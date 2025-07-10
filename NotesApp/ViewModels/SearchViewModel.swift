import Foundation
import SwiftUI
import Combine

/// Search view model with optimized search functionality
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [Note] = []
    @Published var isSearching = false
    @Published var searchFilters = SearchFilters()
    @Published var recentSearches: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let searchQueue = DispatchQueue(label: "search.queue", qos: .userInitiated)
    
    init() {
        setupSearchDebouncing()
        loadRecentSearches()
    }
    
    /// Setup search debouncing to optimize performance
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Perform search with filters
    func performSearch(query: String, notes: [Note] = []) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Perform search on background queue
        let results = await withTaskGroup(of: [Note].self) { group in
            group.addTask { [weak self] in
                await self?.searchInBackground(query: query, notes: notes) ?? []
            }
            
            var allResults: [Note] = []
            for await result in group {
                allResults.append(contentsOf: result)
            }
            return allResults
        }
        
        searchResults = results
        isSearching = false
        
        // Save to recent searches
        addToRecentSearches(query)
    }
    
    /// Background search operation
    private func searchInBackground(query: String, notes: [Note]) async -> [Note] {
        return await withCheckedContinuation { continuation in
            searchQueue.async {
                let filteredNotes = self.filterNotes(notes, with: query)
                continuation.resume(returning: filteredNotes)
            }
        }
    }
    
    /// Filter notes based on search query and filters
    private func filterNotes(_ notes: [Note], with query: String) -> [Note] {
        let lowercaseQuery = query.lowercased()
        let searchTerms = lowercaseQuery.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return notes.filter { note in
            // Skip archived notes unless specifically searching for them
            if note.isArchived && !searchFilters.includeArchived {
                return false
            }
            
            // Apply date filter
            if !searchFilters.dateRange.contains(note.modifiedAt) {
                return false
            }
            
            // Apply folder filter
            if let selectedFolder = searchFilters.selectedFolder,
               note.folder?.id != selectedFolder.id {
                return false
            }
            
            // Apply tag filter
            if !searchFilters.selectedTags.isEmpty {
                let noteTagIDs = Set(note.tags.map { $0.id })
                let selectedTagIDs = Set(searchFilters.selectedTags.map { $0.id })
                if noteTagIDs.intersection(selectedTagIDs).isEmpty {
                    return false
                }
            }
            
            // Apply content type filter
            switch searchFilters.contentType {
            case .all:
                break
            case .textOnly:
                if note.hasHandwriting || !note.attachments.isEmpty {
                    return false
                }
            case .handwritingOnly:
                if !note.hasHandwriting {
                    return false
                }
            case .withAttachments:
                if note.attachments.isEmpty {
                    return false
                }
            }
            
            // Perform text search
            return searchTerms.allSatisfy { term in
                searchInNoteContent(note: note, term: term)
            }
        }
        .sorted { note1, note2 in
            // Sort by relevance score
            let score1 = calculateRelevanceScore(note: note1, query: lowercaseQuery)
            let score2 = calculateRelevanceScore(note: note2, query: lowercaseQuery)
            
            if score1 != score2 {
                return score1 > score2
            }
            
            // Secondary sort by modification date
            return note1.modifiedAt > note2.modifiedAt
        }
    }
    
    /// Search within note content
    private func searchInNoteContent(note: Note, term: String) -> Bool {
        let lowercaseTerm = term.lowercased()
        
        // Search in title (higher priority)
        if note.title.lowercased().contains(lowercaseTerm) {
            return true
        }
        
        // Search in content
        if note.content.lowercased().contains(lowercaseTerm) {
            return true
        }
        
        // Search in tags
        if note.tags.contains(where: { $0.name.lowercased().contains(lowercaseTerm) }) {
            return true
        }
        
        // Search in folder name
        if let folderName = note.folder?.name.lowercased(),
           folderName.contains(lowercaseTerm) {
            return true
        }
        
        // TODO: Add handwriting text recognition search
        // This would use Vision framework to extract text from handwriting data
        
        return false
    }
    
    /// Calculate relevance score for search results
    private func calculateRelevanceScore(note: Note, query: String) -> Int {
        var score = 0
        let lowercaseQuery = query.lowercased()
        
        // Title matches get highest score
        if note.title.lowercased().contains(lowercaseQuery) {
            score += 100
            
            // Exact title match gets bonus
            if note.title.lowercased() == lowercaseQuery {
                score += 50
            }
            
            // Title starts with query gets bonus
            if note.title.lowercased().hasPrefix(lowercaseQuery) {
                score += 25
            }
        }
        
        // Content matches
        let contentMatches = note.content.lowercased().components(separatedBy: lowercaseQuery).count - 1
        score += contentMatches * 10
        
        // Tag matches
        let tagMatches = note.tags.filter { $0.name.lowercased().contains(lowercaseQuery) }.count
        score += tagMatches * 20
        
        // Recent notes get slight boost
        if note.isRecentlyModified {
            score += 5
        }
        
        // Favorite notes get slight boost
        if note.isFavorite {
            score += 3
        }
        
        return score
    }
    
    /// Clear search results
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
    
    /// Apply search filters
    func applyFilters(_ filters: SearchFilters) {
        searchFilters = filters
        
        if !searchText.isEmpty {
            Task {
                await performSearch(query: searchText)
            }
        }
    }
    
    /// Reset search filters
    func resetFilters() {
        searchFilters = SearchFilters()
        
        if !searchText.isEmpty {
            Task {
                await performSearch(query: searchText)
            }
        }
    }
    
    // MARK: - Recent Searches
    
    /// Add search query to recent searches
    private func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
        
        // Add to beginning
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Keep only last 10 searches
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        saveRecentSearches()
    }
    
    /// Load recent searches from UserDefaults
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "RecentSearches") ?? []
    }
    
    /// Save recent searches to UserDefaults
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "RecentSearches")
    }
    
    /// Clear recent searches
    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "RecentSearches")
    }
    
    /// Use recent search
    func useRecentSearch(_ query: String) {
        searchText = query
    }
}

/// Search filters for advanced search functionality
struct SearchFilters {
    var includeArchived = false
    var dateRange = DateRange.all
    var selectedFolder: Folder?
    var selectedTags: [Tag] = []
    var contentType = ContentType.all
    
    enum DateRange {
        case all
        case today
        case thisWeek
        case thisMonth
        case thisYear
        case custom(from: Date, to: Date)
        
        func contains(_ date: Date) -> Bool {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all:
                return true
            case .today:
                return calendar.isDate(date, inSameDayAs: now)
            case .thisWeek:
                let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
                return date >= weekAgo
            case .thisMonth:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
                return date >= monthAgo
            case .thisYear:
                let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                return date >= yearAgo
            case .custom(let from, let to):
                return date >= from && date <= to
            }
        }
        
        var displayName: String {
            switch self {
            case .all: return "All Time"
            case .today: return "Today"
            case .thisWeek: return "This Week"
            case .thisMonth: return "This Month"
            case .thisYear: return "This Year"
            case .custom: return "Custom Range"
            }
        }
    }
    
    enum ContentType {
        case all
        case textOnly
        case handwritingOnly
        case withAttachments
        
        var displayName: String {
            switch self {
            case .all: return "All Content"
            case .textOnly: return "Text Only"
            case .handwritingOnly: return "Handwriting Only"
            case .withAttachments: return "With Attachments"
            }
        }
    }
}

/// Search suggestions provider
struct SearchSuggestions {
    /// Get search suggestions based on current query
    static func getSuggestions(for query: String, notes: [Note], tags: [Tag]) -> [String] {
        let lowercaseQuery = query.lowercased()
        var suggestions: Set<String> = []
        
        // Add matching tag names
        for tag in tags {
            if tag.name.lowercased().hasPrefix(lowercaseQuery) {
                suggestions.insert(tag.name)
            }
        }
        
        // Add matching note titles
        for note in notes.prefix(5) {
            if note.title.lowercased().hasPrefix(lowercaseQuery) {
                suggestions.insert(note.title)
            }
        }
        
        // Add common search terms
        let commonTerms = ["meeting", "project", "idea", "todo", "important", "urgent", "draft"]
        for term in commonTerms {
            if term.hasPrefix(lowercaseQuery) {
                suggestions.insert(term)
            }
        }
        
        return Array(suggestions).sorted().prefix(8).map { $0 }
    }
}

