import Foundation
import CloudKit
import SwiftUI
import Combine

/// Advanced collaboration service for real-time note editing
@MainActor
final class CollaborationService: ObservableObject {
    @Published var activeCollaborators: [Collaborator] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var conflictResolutionNeeded = false
    @Published var pendingChanges: [NoteChange] = []
    
    private let container = CKContainer.default()
    private let database: CKDatabase
    private var subscription: CKQuerySubscription?
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
        
        var displayText: String {
            switch self {
            case .disconnected: return "Offline"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .gray
            case .connecting: return .orange
            case .connected: return .green
            case .error: return .red
            }
        }
    }
    
    init() {
        self.database = container.privateCloudDatabase
        setupCollaboration()
    }
    
    /// Setup collaboration infrastructure
    private func setupCollaboration() {
        checkAccountStatus()
        setupSubscriptions()
    }
    
    /// Check iCloud account status
    private func checkAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    switch status {
                    case .available:
                        self.connectionStatus = .connected
                    case .noAccount:
                        self.connectionStatus = .error("No iCloud account")
                    case .restricted:
                        self.connectionStatus = .error("iCloud restricted")
                    case .couldNotDetermine:
                        self.connectionStatus = .error("Could not determine iCloud status")
                    case .temporarilyUnavailable:
                        self.connectionStatus = .error("iCloud temporarily unavailable")
                    @unknown default:
                        self.connectionStatus = .error("Unknown iCloud status")
                    }
                }
            } catch {
                await MainActor.run {
                    self.connectionStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    /// Setup CloudKit subscriptions for real-time updates
    private func setupSubscriptions() {
        let predicate = NSPredicate(value: true)
        subscription = CKQuerySubscription(
            recordType: "SharedNote",
            predicate: predicate,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription?.notificationInfo = notificationInfo
        
        Task {
            do {
                if let subscription = subscription {
                    try await database.save(subscription)
                }
            } catch {
                print("Failed to setup subscription: \(error)")
            }
        }
    }
    
    /// Share a note with collaborators
    func shareNote(_ note: Note, with emails: [String]) async throws {
        connectionStatus = .connecting
        
        do {
            // Create CloudKit record for the note
            let record = CKRecord(recordType: "SharedNote")
            record["title"] = note.title
            record["content"] = note.content
            record["noteID"] = note.id.uuidString
            record["lastModified"] = note.modifiedAt
            record["owner"] = try await getCurrentUserID()
            
            // Save the record
            let savedRecord = try await database.save(record)
            
            // Create share
            let share = CKShare(rootRecord: savedRecord)
            share[CKShare.SystemFieldKey.title] = note.title
            share.publicPermission = .none
            
            // Add participants
            for email in emails {
                let participant = CKShare.Participant()
                participant.userIdentity = CKUserIdentity()
                participant.userIdentity.emailAddress = email
                participant.permission = .readWrite
                participant.role = .privateUser
                share.addParticipant(participant)
            }
            
            // Save the share
            try await database.save(share)
            
            // Update note status
            note.isShared = true
            note.collaborators = emails
            
            connectionStatus = .connected
            
        } catch {
            connectionStatus = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// Stop sharing a note
    func stopSharing(_ note: Note) async throws {
        // Implementation for stopping collaboration
        note.isShared = false
        note.collaborators = []
        activeCollaborators.removeAll()
    }
    
    /// Send note changes to collaborators
    func sendChanges(_ changes: [NoteChange], for note: Note) async {
        guard note.isShared else { return }
        
        do {
            for change in changes {
                let record = CKRecord(recordType: "NoteChange")
                record["noteID"] = note.id.uuidString
                record["changeType"] = change.type.rawValue
                record["content"] = change.content
                record["timestamp"] = change.timestamp
                record["userID"] = try await getCurrentUserID()
                record["position"] = change.position
                
                try await database.save(record)
            }
        } catch {
            print("Failed to send changes: \(error)")
        }
    }
    
    /// Receive and apply changes from collaborators
    func receiveChanges(for note: Note) async -> [NoteChange] {
        guard note.isShared else { return [] }
        
        do {
            let predicate = NSPredicate(format: "noteID == %@", note.id.uuidString)
            let query = CKQuery(recordType: "NoteChange", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
            
            let (matchResults, _) = try await database.records(matching: query)
            
            var changes: [NoteChange] = []
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let change = NoteChange.from(record: record) {
                        changes.append(change)
                    }
                case .failure(let error):
                    print("Failed to fetch change: \(error)")
                }
            }
            
            return changes
        } catch {
            print("Failed to receive changes: \(error)")
            return []
        }
    }
    
    /// Resolve conflicts between different versions
    func resolveConflicts(localNote: Note, remoteChanges: [NoteChange]) -> Note {
        // Simple last-writer-wins strategy
        // In production, implement more sophisticated conflict resolution
        
        let sortedChanges = remoteChanges.sorted { $0.timestamp < $1.timestamp }
        var resolvedContent = localNote.content
        
        for change in sortedChanges {
            switch change.type {
            case .insert:
                resolvedContent = applyInsert(to: resolvedContent, change: change)
            case .delete:
                resolvedContent = applyDelete(to: resolvedContent, change: change)
            case .replace:
                resolvedContent = applyReplace(to: resolvedContent, change: change)
            }
        }
        
        localNote.content = resolvedContent
        localNote.modifiedAt = Date()
        
        return localNote
    }
    
    /// Get current user ID
    private func getCurrentUserID() async throws -> String {
        let userIdentity = try await container.userRecordID()
        return userIdentity.recordName
    }
    
    /// Apply insert operation
    private func applyInsert(to content: String, change: NoteChange) -> String {
        let index = content.index(content.startIndex, offsetBy: min(change.position, content.count))
        return String(content[..<index]) + change.content + String(content[index...])
    }
    
    /// Apply delete operation
    private func applyDelete(to content: String, change: NoteChange) -> String {
        let startIndex = content.index(content.startIndex, offsetBy: min(change.position, content.count))
        let endIndex = content.index(startIndex, offsetBy: min(change.content.count, content.count - change.position))
        return String(content[..<startIndex]) + String(content[endIndex...])
    }
    
    /// Apply replace operation
    private func applyReplace(to content: String, change: NoteChange) -> String {
        let startIndex = content.index(content.startIndex, offsetBy: min(change.position, content.count))
        let endIndex = content.index(startIndex, offsetBy: min(change.content.count, content.count - change.position))
        return String(content[..<startIndex]) + change.content + String(content[endIndex...])
    }
}

/// Represents a collaborator in real-time editing
struct Collaborator: Identifiable, Codable {
    let id = UUID()
    let userID: String
    let name: String
    let email: String
    let avatarURL: String?
    let cursorPosition: Int
    let lastSeen: Date
    let isActive: Bool
    
    var displayName: String {
        name.isEmpty ? email : name
    }
    
    var isOnline: Bool {
        Date().timeIntervalSince(lastSeen) < 30 // Consider online if seen within 30 seconds
    }
}

/// Represents a change made to a note
struct NoteChange: Identifiable, Codable {
    let id = UUID()
    let type: ChangeType
    let content: String
    let position: Int
    let timestamp: Date
    let userID: String
    
    enum ChangeType: String, Codable {
        case insert
        case delete
        case replace
    }
    
    static func from(record: CKRecord) -> NoteChange? {
        guard let typeString = record["changeType"] as? String,
              let type = ChangeType(rawValue: typeString),
              let content = record["content"] as? String,
              let position = record["position"] as? Int,
              let timestamp = record["timestamp"] as? Date,
              let userID = record["userID"] as? String else {
            return nil
        }
        
        return NoteChange(
            type: type,
            content: content,
            position: position,
            timestamp: timestamp,
            userID: userID
        )
    }
}

/// Collaboration status indicator view
struct CollaborationStatusView: View {
    @ObservedObject var collaborationService: CollaborationService
    
    var body: some View {
        HStack(spacing: 8) {
            // Connection status
            Circle()
                .fill(collaborationService.connectionStatus.color)
                .frame(width: 8, height: 8)
            
            Text(collaborationService.connectionStatus.displayText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Active collaborators
            if !collaborationService.activeCollaborators.isEmpty {
                HStack(spacing: -8) {
                    ForEach(collaborationService.activeCollaborators.prefix(3)) { collaborator in
                        CollaboratorAvatar(collaborator: collaborator)
                    }
                    
                    if collaborationService.activeCollaborators.count > 3 {
                        Text("+\(collaborationService.activeCollaborators.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

/// Individual collaborator avatar
struct CollaboratorAvatar: View {
    let collaborator: Collaborator
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 24, height: 24)
            
            Text(String(collaborator.displayName.prefix(1)).uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if collaborator.isOnline {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: -8)
            }
        }
    }
}

/// Share note sheet for collaboration
struct ShareNoteSheet: View {
    let note: Note
    @ObservedObject var collaborationService: CollaborationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var emailAddresses: [String] = [""]
    @State private var isSharing = false
    @State private var shareError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(note.title)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(note.formattedCreatedDate)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Collaborators") {
                    ForEach(emailAddresses.indices, id: \.self) { index in
                        HStack {
                            TextField("Email address", text: $emailAddresses[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            if emailAddresses.count > 1 {
                                Button(action: { removeEmail(at: index) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Button("Add Another Email") {
                        emailAddresses.append("")
                    }
                    .foregroundColor(.accentColor)
                }
                
                Section("Permissions") {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                        Text("Can edit")
                        Spacer()
                        Text("All collaborators can edit this note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = shareError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Share Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        shareNote()
                    }
                    .disabled(isSharing || !hasValidEmails)
                }
            }
        }
    }
    
    private var hasValidEmails: Bool {
        emailAddresses.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func removeEmail(at index: Int) {
        emailAddresses.remove(at: index)
    }
    
    private func shareNote() {
        let validEmails = emailAddresses
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !validEmails.isEmpty else { return }
        
        isSharing = true
        shareError = nil
        
        Task {
            do {
                try await collaborationService.shareNote(note, with: validEmails)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    shareError = error.localizedDescription
                    isSharing = false
                }
            }
        }
    }
}

#Preview {
    CollaborationStatusView(collaborationService: CollaborationService())
}

