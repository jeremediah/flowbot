import Foundation
import SwiftData
import SwiftUI

/// Folder model for organizing notes
@Model
final class Folder: Identifiable, ObservableObject {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String // Hex color string
    var icon: String // SF Symbol name
    var createdAt: Date
    var sortOrder: Int
    var isDefault: Bool
    
    // Relationships
    var notes: [Note]
    var parentFolder: Folder?
    var subfolders: [Folder]
    
    init(
        name: String,
        color: String = "#007AFF",
        icon: String = "folder",
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.sortOrder = 0
        self.isDefault = isDefault
        self.notes = []
        self.parentFolder = nil
        self.subfolders = []
    }
    
    /// Get SwiftUI Color from hex string
    var swiftUIColor: Color {
        Color(hex: color) ?? .blue
    }
    
    /// Get note count including subfolders
    var totalNoteCount: Int {
        let directNotes = notes.filter { !$0.isArchived }.count
        let subfolderNotes = subfolders.reduce(0) { $0 + $1.totalNoteCount }
        return directNotes + subfolderNotes
    }
    
    /// Get recent notes (modified in last 7 days)
    var recentNotes: [Note] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return notes.filter { $0.modifiedAt > sevenDaysAgo && !$0.isArchived }
            .sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    /// Check if folder has any notes
    var hasNotes: Bool {
        totalNoteCount > 0
    }
    
    /// Get formatted creation date
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}

/// Extension for Color to support hex initialization
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Convert Color to hex string
    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}

/// Predefined folder colors
enum FolderColor: String, CaseIterable {
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
        }
    }
    
    var color: Color {
        Color(hex: rawValue) ?? .blue
    }
}

/// Predefined folder icons
enum FolderIcon: String, CaseIterable {
    case folder = "folder"
    case folderFill = "folder.fill"
    case work = "briefcase"
    case personal = "person"
    case school = "graduationcap"
    case projects = "hammer"
    case ideas = "lightbulb"
    case archive = "archivebox"
    case important = "star"
    case travel = "airplane"
    case health = "heart"
    case finance = "dollarsign.circle"
    case shopping = "cart"
    case recipes = "fork.knife"
    case books = "book"
    case music = "music.note"
    case photos = "photo"
    case documents = "doc"
    
    var displayName: String {
        switch self {
        case .folder: return "Folder"
        case .folderFill: return "Folder (Filled)"
        case .work: return "Work"
        case .personal: return "Personal"
        case .school: return "School"
        case .projects: return "Projects"
        case .ideas: return "Ideas"
        case .archive: return "Archive"
        case .important: return "Important"
        case .travel: return "Travel"
        case .health: return "Health"
        case .finance: return "Finance"
        case .shopping: return "Shopping"
        case .recipes: return "Recipes"
        case .books: return "Books"
        case .music: return "Music"
        case .photos: return "Photos"
        case .documents: return "Documents"
        }
    }
}

