import Foundation
import SwiftData
import SwiftUI
import Combine

/// Main view model for note management with thread-safe operations
@MainActor
final class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var folders: [Folder] = []
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var syncStatus: SyncStatus = .idle
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private let syncManager = SyncManager()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
    }
    
    /// Setup model context and load initial data
    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadData()
        setupSyncTimer()
    }
    
    /// Load all data from SwiftData
    private func loadData() {
        guard let context = modelContext else { return }
        
        isLoading = true
        
        Task {
            do {
                // Load notes
                let noteDescriptor = FetchDescriptor<Note>(
                    sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
                )
                self.notes = try context.fetch(noteDescriptor)
                
                // Load folders
                let folderDescriptor = FetchDescriptor<Folder>(
                    sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
                )
                self.folders = try context.fetch(folderDescriptor)
                
                // Load tags
                let tagDescriptor = FetchDescriptor<Tag>(
                    sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
                )
                self.tags = try context.fetch(tagDescriptor)
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Note Operations
    
    /// Create a new note
    func createNote(
        title: String = "Untitled Note",
        content: String = "",
        folder: Folder? = nil,
        template: NoteTemplate? = nil
    ) -> Note {
        guard let context = modelContext else {
            fatalError("Model context not set")
        }
        
        let note = Note(
            title: title,
            content: template?.templateContent ?? content,
            folder: folder,
            templateType: template
        )
        
        context.insert(note)
        
        // Add to folder if specified
        if let folder = folder {
            folder.notes.append(note)
        }
        
        saveContext()
        loadData() // Refresh data
        
        return note
    }
    
    /// Update an existing note
    func updateNote(_ note: Note, title: String? = nil, content: String? = nil) {
        if let title = title {
            note.title = title
        }
        
        if let content = content {
            note.content = content
        }
        
        note.updateModificationDate()
        saveContext()
        
        // Trigger sync for shared notes
        if note.isShared {
            syncNote(note)
        }
    }
    
    /// Delete a note
    func deleteNote(_ note: Note) {
        guard let context = modelContext else { return }
        
        // Remove from folder
        if let folder = note.folder {
            folder.notes.removeAll { $0.id == note.id }
        }
        
        // Update tag usage counts
        for tag in note.tags {
            tag.decrementUsage()
        }
        
        context.delete(note)
        saveContext()
        loadData()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        note.updateModificationDate()
        saveContext()
    }
    
    /// Archive/unarchive note
    func toggleArchive(_ note: Note) {
        note.isArchived.toggle()
        note.updateModificationDate()
        saveContext()
        loadData()
    }
    
    /// Duplicate a note
    func duplicateNote(_ note: Note) -> Note {
        let duplicatedNote = createNote(
            title: "\(note.title) Copy",
            content: note.content,
            folder: note.folder,
            template: note.templateType
        )
        
        // Copy tags
        duplicatedNote.tags = note.tags
        for tag in note.tags {
            tag.incrementUsage()
        }
        
        saveContext()
        return duplicatedNote
    }
    
    // MARK: - Folder Operations
    
    /// Create a new folder
    func createFolder(
        name: String,
        color: String = FolderColor.blue.rawValue,
        icon: String = FolderIcon.folder.rawValue,
        parent: Folder? = nil
    ) -> Folder {
        guard let context = modelContext else {
            fatalError("Model context not set")
        }
        
        let folder = Folder(name: name, color: color, icon: icon)
        folder.parentFolder = parent
        folder.sortOrder = folders.count
        
        context.insert(folder)
        
        if let parent = parent {
            parent.subfolders.append(folder)
        }
        
        saveContext()
        loadData()
        
        return folder
    }
    
    /// Update folder
    func updateFolder(_ folder: Folder, name: String? = nil, color: String? = nil, icon: String? = nil) {
        if let name = name {
            folder.name = name
        }
        
        if let color = color {
            folder.color = color
        }
        
        if let icon = icon {
            folder.icon = icon
        }
        
        saveContext()
    }
    
    /// Delete folder and move notes to default folder
    func deleteFolder(_ folder: Folder) {
        guard let context = modelContext else { return }
        
        // Move notes to default folder or no folder
        let defaultFolder = folders.first { $0.isDefault }
        for note in folder.notes {
            note.folder = defaultFolder
        }
        
        // Remove from parent folder
        if let parent = folder.parentFolder {
            parent.subfolders.removeAll { $0.id == folder.id }
        }
        
        context.delete(folder)
        saveContext()
        loadData()
    }
    
    /// Move note to folder
    func moveNote(_ note: Note, to folder: Folder?) {
        // Remove from current folder
        if let currentFolder = note.folder {
            currentFolder.notes.removeAll { $0.id == note.id }
        }
        
        // Add to new folder
        note.folder = folder
        if let folder = folder {
            folder.notes.append(note)
        }
        
        note.updateModificationDate()
        saveContext()
    }
    
    // MARK: - Tag Operations
    
    /// Create a new tag
    func createTag(name: String, color: String = TagColor.blue.rawValue) -> Tag {
        guard let context = modelContext else {
            fatalError("Model context not set")
        }
        
        // Check if tag already exists
        if let existingTag = tags.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existingTag
        }
        
        let tag = Tag(name: name.lowercased(), color: color)
        context.insert(tag)
        saveContext()
        loadData()
        
        return tag
    }
    
    /// Add tag to note
    func addTag(_ tag: Tag, to note: Note) {
        if !note.tags.contains(where: { $0.id == tag.id }) {
            note.tags.append(tag)
            tag.notes.append(note)
            tag.incrementUsage()
            note.updateModificationDate()
            saveContext()
        }
    }
    
    /// Remove tag from note
    func removeTag(_ tag: Tag, from note: Note) {
        note.tags.removeAll { $0.id == tag.id }
        tag.notes.removeAll { $0.id == note.id }
        tag.decrementUsage()
        note.updateModificationDate()
        saveContext()
    }
    
    /// Delete tag
    func deleteTag(_ tag: Tag) {
        guard let context = modelContext else { return }
        
        // Remove from all notes
        for note in tag.notes {
            note.tags.removeAll { $0.id == tag.id }
        }
        
        context.delete(tag)
        saveContext()
        loadData()
    }
    
    // MARK: - Filtering and Sorting
    
    /// Get notes filtered by folder
    func notes(in folder: Folder?) -> [Note] {
        if let folder = folder {
            return folder.notes.filter { !$0.isArchived }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        } else {
            return notes.filter { $0.folder == nil && !$0.isArchived }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        }
    }
    
    /// Get favorite notes
    var favoriteNotes: [Note] {
        notes.filter { $0.isFavorite && !$0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    /// Get archived notes
    var archivedNotes: [Note] {
        notes.filter { $0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    /// Get recent notes (modified in last 7 days)
    var recentNotes: [Note] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notes.filter { $0.modifiedAt > sevenDaysAgo && !$0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    /// Get notes with specific tag
    func notes(with tag: Tag) -> [Note] {
        tag.notes.filter { !$0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    // MARK: - Sync Operations
    
    /// Setup automatic sync timer
    private func setupSyncTimer() {
        Timer.publish(every: 300, on: .main, in: .common) // Sync every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.syncAllNotes()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sync all notes with iCloud
    func syncAllNotes() async {
        syncStatus = .syncing
        
        do {
            try await syncManager.syncNotes(notes)
            syncStatus = .success
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    /// Sync specific note
    private func syncNote(_ note: Note) {
        Task {
            do {
                try await syncManager.syncNote(note)
            } catch {
                print("Failed to sync note: \(error)")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Save model context
    private func saveContext() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

/// Sync manager for iCloud operations
actor SyncManager {
    /// Sync all notes with iCloud
    func syncNotes(_ notes: [Note]) async throws {
        // Simulate iCloud sync operation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        for note in notes where note.isShared {
            try await syncNote(note)
        }
    }
    
    /// Sync individual note
    func syncNote(_ note: Note) async throws {
        // Simulate individual note sync
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        
        note.lastSyncedAt = Date()
        
        // In a real implementation, this would:
        // 1. Upload note content to iCloud
        // 2. Handle conflict resolution
        // 3. Update collaboration status
        // 4. Sync attachments
    }
}

