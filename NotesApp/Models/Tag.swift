import Foundation
import SwiftData
import SwiftUI

/// Tag model for categorizing notes
@Model
final class Tag: Identifiable, ObservableObject {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String // Hex color string
    var createdAt: Date
    var usageCount: Int
    
    // Relationships
    var notes: [Note]
    
    init(name: String, color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.usageCount = 0
        self.notes = []
    }
    
    /// Get SwiftUI Color from hex string
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
    
    /// Get active note count (non-archived)
    var activeNoteCount: Int {
        notes.filter { !$0.isArchived }.count
    }
    
    /// Update usage count when tag is applied to a note
    func incrementUsage() {
        usageCount += 1
    }
    
    /// Decrement usage count when tag is removed from a note
    func decrementUsage() {
        if usageCount > 0 {
            usageCount -= 1
        }
    }
    
    /// Get formatted creation date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    /// Check if tag is recently used (within last 30 days)
    var isRecentlyUsed: Bool {
        guard let lastUsedNote = notes.max(by: { $0.modifiedAt < $1.modifiedAt }) else {
            return false
        }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastUsedNote.modifiedAt > thirtyDaysAgo
    }
}

/// Predefined tag colors
enum TagColor: String, CaseIterable {
    case blue = "#007AFF"
    case green = "#34C759"
    case orange = "#FF9500"
    case red = "#FF3B30"
    case purple = "#AF52DE"
    case pink = "#FF2D92"
    case yellow = "#FFCC00"
    case teal = "#5AC8FA"
    case indigo = "#5856D6"
    case brown = "#A2845E"
    case gray = "#8E8E93"
    case mint = "#00C7BE"
    case cyan = "#32D74B"
    
    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .red: return "Red"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .yellow: return "Yellow"
        case .teal: return "Teal"
        case .indigo: return "Indigo"
        case .brown: return "Brown"
        case .gray: return "Gray"
        case .mint: return "Mint"
        case .cyan: return "Cyan"
        }
    }
    
    var color: Color {
        Color(hex: rawValue) ?? .blue
    }
}

/// Common tag suggestions
enum CommonTag: String, CaseIterable {
    case work = "work"
    case personal = "personal"
    case important = "important"
    case urgent = "urgent"
    case ideas = "ideas"
    case todo = "todo"
    case meeting = "meeting"
    case project = "project"
    case research = "research"
    case draft = "draft"
    case review = "review"
    case archive = "archive"
    case inspiration = "inspiration"
    case learning = "learning"
    case reference = "reference"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var suggestedColor: TagColor {
        switch self {
        case .work: return .blue
        case .personal: return .green
        case .important: return .red
        case .urgent: return .orange
        case .ideas: return .yellow
        case .todo: return .purple
        case .meeting: return .teal
        case .project: return .indigo
        case .research: return .brown
        case .draft: return .gray
        case .review: return .pink
        case .archive: return .gray
        case .inspiration: return .mint
        case .learning: return .cyan
        case .reference: return .blue
        }
    }
}

/// Tag management utilities
struct TagManager {
    /// Create a new tag with suggested color
    static func createTag(name: String, suggestedColor: TagColor? = nil) -> Tag {
        let color = suggestedColor?.rawValue ?? TagColor.blue.rawValue
        return Tag(name: name.lowercased(), color: color)
    }
    
    /// Get popular tags based on usage count
    static func getPopularTags(from tags: [Tag], limit: Int = 10) -> [Tag] {
        return tags.sorted { $0.usageCount > $1.usageCount }
                  .prefix(limit)
                  .map { $0 }
    }
    
    /// Get recently used tags
    static func getRecentTags(from tags: [Tag], limit: Int = 5) -> [Tag] {
        return tags.filter { $0.isRecentlyUsed }
                  .sorted { $0.createdAt > $1.createdAt }
                  .prefix(limit)
                  .map { $0 }
    }
    
    /// Search tags by name
    static func searchTags(from tags: [Tag], query: String) -> [Tag] {
        guard !query.isEmpty else { return tags }
        
        return tags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(query)
        }.sorted { $0.name < $1.name }
    }
    
    /// Get tag suggestions based on note content
    static func suggestTags(for content: String) -> [CommonTag] {
        let lowercaseContent = content.lowercased()
        var suggestions: [CommonTag] = []
        
        // Simple keyword matching for tag suggestions
        let keywords: [String: CommonTag] = [
            "meeting": .meeting,
            "project": .project,
            "work": .work,
            "todo": .todo,
            "important": .important,
            "urgent": .urgent,
            "idea": .ideas,
            "research": .research,
            "draft": .draft,
            "review": .review,
            "learning": .learning,
            "reference": .reference
        ]
        
        for (keyword, tag) in keywords {
            if lowercaseContent.contains(keyword) {
                suggestions.append(tag)
            }
        }
        
        return Array(Set(suggestions)) // Remove duplicates
    }
}

