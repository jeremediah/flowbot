import Foundation
import SwiftData
import UIKit

/// Core Note model with SwiftData annotations for persistence
@Model
final class Note: Identifiable, ObservableObject {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool
    var isArchived: Bool
    
    // Rich text and media support
    var hasHandwriting: Bool
    var handwritingData: Data?
    var attachments: [Attachment]
    
    // Organization
    var folder: Folder?
    var tags: [Tag]
    
    // Collaboration
    var isShared: Bool
    var collaborators: [String] // User IDs
    var lastSyncedAt: Date?
    
    // Template support
    var templateType: NoteTemplate?
    
    init(
        title: String = "Untitled Note",
        content: String = "",
        folder: Folder? = nil,
        templateType: NoteTemplate? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isFavorite = false
        self.isArchived = false
        self.hasHandwriting = false
        self.handwritingData = nil
        self.attachments = []
        self.folder = folder
        self.tags = []
        self.isShared = false
        self.collaborators = []
        self.lastSyncedAt = nil
        self.templateType = templateType
    }
    
    /// Update modification date when content changes
    func updateModificationDate() {
        modifiedAt = Date()
    }
    
    /// Get formatted creation date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    /// Get formatted modification date
    var formattedModifiedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modifiedAt)
    }
    
    /// Check if note was modified recently (within last hour)
    var isRecentlyModified: Bool {
        Date().timeIntervalSince(modifiedAt) < 3600
    }
    
    /// Get preview text (first 100 characters of content)
    var previewText: String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanContent.count > 100 {
            return String(cleanContent.prefix(100)) + "..."
        }
        return cleanContent.isEmpty ? "No content" : cleanContent
    }
}

/// Attachment model for media files
@Model
final class Attachment: Identifiable {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var fileType: AttachmentType
    var fileSize: Int64
    var localURL: String?
    var cloudURL: String?
    var isUploaded: Bool
    var createdAt: Date
    
    // Relationship
    var note: Note?
    
    init(fileName: String, fileType: AttachmentType, fileSize: Int64) {
        self.id = UUID()
        self.fileName = fileName
        self.fileType = fileType
        self.fileSize = fileSize
        self.localURL = nil
        self.cloudURL = nil
        self.isUploaded = false
        self.createdAt = Date()
    }
    
    /// Get formatted file size
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

/// Attachment types supported by the app
enum AttachmentType: String, CaseIterable, Codable {
    case image = "image"
    case pdf = "pdf"
    case audio = "audio"
    case video = "video"
    case document = "document"
    
    var systemImage: String {
        switch self {
        case .image:
            return "photo"
        case .pdf:
            return "doc.richtext"
        case .audio:
            return "waveform"
        case .video:
            return "video"
        case .document:
            return "doc"
        }
    }
    
    var displayName: String {
        switch self {
        case .image:
            return "Image"
        case .pdf:
            return "PDF"
        case .audio:
            return "Audio"
        case .video:
            return "Video"
        case .document:
            return "Document"
        }
    }
}

/// Note template types for quick creation
enum NoteTemplate: String, CaseIterable, Codable {
    case blank = "blank"
    case meeting = "meeting"
    case journal = "journal"
    case todoList = "todoList"
    case lecture = "lecture"
    case brainstorm = "brainstorm"
    case recipe = "recipe"
    case travel = "travel"
    
    var displayName: String {
        switch self {
        case .blank:
            return "Blank Note"
        case .meeting:
            return "Meeting Notes"
        case .journal:
            return "Journal Entry"
        case .todoList:
            return "To-Do List"
        case .lecture:
            return "Lecture Notes"
        case .brainstorm:
            return "Brainstorm"
        case .recipe:
            return "Recipe"
        case .travel:
            return "Travel Notes"
        }
    }
    
    var systemImage: String {
        switch self {
        case .blank:
            return "doc"
        case .meeting:
            return "person.3"
        case .journal:
            return "book"
        case .todoList:
            return "checklist"
        case .lecture:
            return "graduationcap"
        case .brainstorm:
            return "lightbulb"
        case .recipe:
            return "fork.knife"
        case .travel:
            return "airplane"
        }
    }
    
    var templateContent: String {
        switch self {
        case .blank:
            return ""
        case .meeting:
            return """
            # Meeting Notes
            
            **Date:** \(Date().formatted(date: .abbreviated, time: .shortened))
            **Attendees:** 
            
            ## Agenda
            - 
            
            ## Discussion
            
            ## Action Items
            - [ ] 
            
            ## Next Steps
            """
        case .journal:
            return """
            # Journal Entry - \(Date().formatted(date: .complete, time: .omitted))
            
            ## Today's Highlights
            
            ## Thoughts & Reflections
            
            ## Gratitude
            - 
            - 
            - 
            
            ## Tomorrow's Goals
            """
        case .todoList:
            return """
            # To-Do List
            
            ## Today
            - [ ] 
            - [ ] 
            - [ ] 
            
            ## This Week
            - [ ] 
            - [ ] 
            
            ## Someday
            - [ ] 
            """
        case .lecture:
            return """
            # Lecture Notes
            
            **Course:** 
            **Date:** \(Date().formatted(date: .abbreviated, time: .shortened))
            **Topic:** 
            
            ## Key Concepts
            
            ## Important Points
            - 
            
            ## Questions
            - 
            
            ## Summary
            """
        case .brainstorm:
            return """
            # Brainstorm Session
            
            **Topic:** 
            **Date:** \(Date().formatted(date: .abbreviated, time: .shortened))
            
            ## Ideas
            - 
            - 
            - 
            
            ## Best Ideas
            1. 
            
            ## Next Steps
            """
        case .recipe:
            return """
            # Recipe
            
            **Prep Time:** 
            **Cook Time:** 
            **Servings:** 
            
            ## Ingredients
            - 
            - 
            - 
            
            ## Instructions
            1. 
            2. 
            3. 
            
            ## Notes
            """
        case .travel:
            return """
            # Travel Notes
            
            **Destination:** 
            **Dates:** 
            
            ## Itinerary
            
            ## Places to Visit
            - 
            
            ## Restaurants to Try
            - 
            
            ## Packing List
            - [ ] 
            
            ## Notes & Memories
            """
        }
    }
}

