import SwiftUI

/// Note list view with search and filtering capabilities
struct NoteListView: View {
    @Binding var selectedNote: Note?
    let selectedFolder: Folder?
    @ObservedObject var noteViewModel: NoteViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    
    @State private var showingNewNoteSheet = false
    @State private var showingSearchFilters = false
    @State private var showingTemplateSelector = false
    @State private var sortOption = SortOption.modifiedDate
    @State private var isGridView = false
    
    private var displayedNotes: [Note] {
        if !searchViewModel.searchText.isEmpty {
            return searchViewModel.searchResults
        } else if let folder = selectedFolder {
            return noteViewModel.notes(in: folder)
        } else {
            return noteViewModel.notes.filter { !$0.isArchived }
                .sorted { sortOption.compare($0, $1) }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBarView(searchViewModel: searchViewModel)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Filter and sort controls
            if !searchViewModel.searchText.isEmpty || selectedFolder != nil {
                ControlsBarView(
                    sortOption: $sortOption,
                    isGridView: $isGridView,
                    showingSearchFilters: $showingSearchFilters,
                    noteCount: displayedNotes.count,
                    isSearching: searchViewModel.isSearching
                )
                .padding(.horizontal)
            }
            
            // Notes list/grid
            if displayedNotes.isEmpty {
                EmptyStateView(
                    searchText: searchViewModel.searchText,
                    selectedFolder: selectedFolder
                )
            } else {
                if isGridView {
                    NotesGridView(
                        notes: displayedNotes,
                        selectedNote: $selectedNote,
                        noteViewModel: noteViewModel
                    )
                } else {
                    NotesListView(
                        notes: displayedNotes,
                        selectedNote: $selectedNote,
                        noteViewModel: noteViewModel
                    )
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Note", systemImage: "doc.badge.plus") {
                        createNewNote()
                    }
                    
                    Button("New from Template", systemImage: "doc.text") {
                        showingTemplateSelector = true
                    }
                    
                    Divider()
                    
                    Button(isGridView ? "List View" : "Grid View", 
                           systemImage: isGridView ? "list.bullet" : "square.grid.2x2") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isGridView.toggle()
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            NewNoteSheet(
                noteViewModel: noteViewModel,
                selectedFolder: selectedFolder
            )
        }
        .sheet(isPresented: $showingTemplateSelector) {
            TemplateSelectionSheet(
                noteViewModel: noteViewModel,
                selectedFolder: selectedFolder,
                onNoteCreated: { note in
                    selectedNote = note
                }
            )
        }
        .sheet(isPresented: $showingSearchFilters) {
            SearchFiltersSheet(searchViewModel: searchViewModel)
        }
    }
    
    private var navigationTitle: String {
        if !searchViewModel.searchText.isEmpty {
            return "Search Results"
        } else if let folder = selectedFolder {
            return folder.name
        } else {
            return "All Notes"
        }
    }
    
    private func createNewNote() {
        let newNote = noteViewModel.createNote(folder: selectedFolder)
        selectedNote = newNote
    }
}

/// Search bar with suggestions
struct SearchBarView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @State private var showingSuggestions = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search notes...", text: $searchViewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        showingSuggestions = true
                    }
                
                if !searchViewModel.searchText.isEmpty {
                    Button(action: {
                        searchViewModel.clearSearch()
                        showingSuggestions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                if searchViewModel.isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Search suggestions
            if showingSuggestions && !searchViewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchViewModel.recentSearches.prefix(5), id: \.self) { search in
                        Button(action: {
                            searchViewModel.useRecentSearch(search)
                            showingSuggestions = false
                        }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Text(search)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if search != searchViewModel.recentSearches.prefix(5).last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
                .padding(.top, 4)
            }
        }
        .onTapGesture {
            showingSuggestions = false
        }
    }
}

/// Controls bar with sort and filter options
struct ControlsBarView: View {
    @Binding var sortOption: SortOption
    @Binding var isGridView: Bool
    @Binding var showingSearchFilters: Bool
    let noteCount: Int
    let isSearching: Bool
    
    var body: some View {
        HStack {
            // Results count
            if isSearching {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(noteCount) \(noteCount == 1 ? "note" : "notes")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sort menu
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: { sortOption = option }) {
                        HStack {
                            Text(option.displayName)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sort")
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            // Filter button
            Button(action: { showingSearchFilters = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filter")
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            // View toggle
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isGridView.toggle()
                }
            }) {
                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

/// List view for notes
struct NotesListView: View {
    let notes: [Note]
    @Binding var selectedNote: Note?
    @ObservedObject var noteViewModel: NoteViewModel
    
    var body: some View {
        List(notes, id: \.id, selection: $selectedNote) { note in
            NoteRowView(note: note, noteViewModel: noteViewModel)
                .tag(note)
        }
        .listStyle(PlainListStyle())
    }
}

/// Grid view for notes
struct NotesGridView: View {
    let notes: [Note]
    @Binding var selectedNote: Note?
    @ObservedObject var noteViewModel: NoteViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(notes, id: \.id) { note in
                    NoteCardView(note: note, noteViewModel: noteViewModel)
                        .onTapGesture {
                            selectedNote = note
                        }
                }
            }
            .padding()
        }
    }
}

/// Individual note row for list view
struct NoteRowView: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    @State private var showingContextMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Title
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Indicators
                HStack(spacing: 4) {
                    if note.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if note.hasHandwriting {
                        Image(systemName: "pencil.tip")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    
                    if !note.attachments.isEmpty {
                        Image(systemName: "paperclip")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    if note.isShared {
                        Image(systemName: "person.2")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            
            // Preview text
            Text(note.previewText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Metadata
            HStack {
                // Folder
                if let folder = note.folder {
                    HStack(spacing: 2) {
                        Image(systemName: folder.icon)
                            .foregroundColor(folder.swiftUIColor)
                        Text(folder.name)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Date
                Text(note.formattedModifiedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(note.tags, id: \.id) { tag in
                            TagChip(tag: tag, size: .small)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            NoteContextMenu(note: note, noteViewModel: noteViewModel)
        }
    }
}

/// Note card for grid view
struct NoteCardView: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if note.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Content preview
            Text(note.previewText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Footer
            VStack(alignment: .leading, spacing: 4) {
                // Tags
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(3), id: \.id) { tag in
                                TagChip(tag: tag, size: .small)
                            }
                            
                            if note.tags.count > 3 {
                                Text("+\(note.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Metadata
                HStack {
                    if let folder = note.folder {
                        HStack(spacing: 2) {
                            Image(systemName: folder.icon)
                                .foregroundColor(folder.swiftUIColor)
                            Text(folder.name)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(note.formattedModifiedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .contextMenu {
            NoteContextMenu(note: note, noteViewModel: noteViewModel)
        }
    }
}

/// Context menu for notes
struct NoteContextMenu: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    
    var body: some View {
        Group {
            Button(action: { noteViewModel.toggleFavorite(note) }) {
                Label(note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: note.isFavorite ? "heart.slash" : "heart")
            }
            
            Button(action: { noteViewModel.duplicateNote(note) }) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Button(action: { noteViewModel.toggleArchive(note) }) {
                Label(note.isArchived ? "Unarchive" : "Archive",
                      systemImage: note.isArchived ? "tray.and.arrow.up" : "archivebox")
            }
            
            Divider()
            
            Button(role: .destructive, action: { noteViewModel.deleteNote(note) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Empty state view
struct EmptyStateView: View {
    let searchText: String
    let selectedFolder: Folder?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .symbolEffect(.breathe)
            
            Text(emptyStateTitle)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        } else if selectedFolder != nil {
            return "No Notes in Folder"
        } else {
            return "No Notes Yet"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters"
        } else if selectedFolder != nil {
            return "Create your first note in this folder"
        } else {
            return "Create your first note to get started"
        }
    }
}

/// Sort options for notes
enum SortOption: CaseIterable {
    case modifiedDate
    case createdDate
    case title
    case favorite
    
    var displayName: String {
        switch self {
        case .modifiedDate: return "Modified Date"
        case .createdDate: return "Created Date"
        case .title: return "Title"
        case .favorite: return "Favorites First"
        }
    }
    
    func compare(_ note1: Note, _ note2: Note) -> Bool {
        switch self {
        case .modifiedDate:
            return note1.modifiedAt > note2.modifiedAt
        case .createdDate:
            return note1.createdAt > note2.createdAt
        case .title:
            return note1.title.localizedCaseInsensitiveCompare(note2.title) == .orderedAscending
        case .favorite:
            if note1.isFavorite != note2.isFavorite {
                return note1.isFavorite
            }
            return note1.modifiedAt > note2.modifiedAt
        }
    }
}

#Preview {
    NavigationView {
        NoteListView(
            selectedNote: .constant(nil),
            selectedFolder: nil,
            noteViewModel: NoteViewModel(),
            searchViewModel: SearchViewModel()
        )
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}

