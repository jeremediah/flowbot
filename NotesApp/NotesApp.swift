import SwiftUI
import SwiftData

/// Main app entry point with multi-window support for iPadOS
@main
struct NotesApp: App {
    @StateObject private var paywallManager = PaywallManager()
    @StateObject private var collaborationService = CollaborationService()
    @StateObject private var exportService = ExportService()
    
    var body: some Scene {
        // Multi-window support for iPadOS
        WindowGroup {
            ContentView()
                .modelContainer(for: [Note.self, Folder.self, Tag.self])
                .environmentObject(paywallManager)
                .environmentObject(collaborationService)
                .environmentObject(exportService)
        }
        .windowResizability(.contentSize)
        
        // Additional window group for opening notes in separate windows
        WindowGroup("Note Editor", id: "note-editor", for: Note.ID.self) { $noteID in
            if let noteID = noteID {
                NoteEditorWindowView(noteID: noteID)
                    .modelContainer(for: [Note.self, Folder.self, Tag.self])
                    .environmentObject(paywallManager)
                    .environmentObject(collaborationService)
                    .environmentObject(exportService)
            }
        }
        .windowResizability(.contentSize)
    }
}

/// Main content view with NavigationSplitView for iPad layout
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var noteViewModel = NoteViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var selectedNote: Note?
    @State private var selectedFolder: Folder?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with folders and navigation
            SidebarView(
                selectedFolder: $selectedFolder,
                noteViewModel: noteViewModel
            )
        } content: {
            // Note list view
            NoteListView(
                selectedNote: $selectedNote,
                selectedFolder: selectedFolder,
                noteViewModel: noteViewModel,
                searchViewModel: searchViewModel
            )
        } detail: {
            // Note editor or empty state
            if let selectedNote = selectedNote {
                NoteEditorView(
                    note: selectedNote,
                    noteViewModel: noteViewModel
                )
            } else {
                EmptyNoteView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            setupInitialData()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    /// Setup initial sample data for testing
    private func setupInitialData() {
        noteViewModel.setupModelContext(modelContext)
        
        // Create sample data if none exists
        let fetchDescriptor = FetchDescriptor<Note>()
        let existingNotes = try? modelContext.fetch(fetchDescriptor)
        
        if existingNotes?.isEmpty == true {
            SampleDataGenerator.createSampleData(in: modelContext)
        }
    }
}

/// Empty state view when no note is selected
struct EmptyNoteView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
                .symbolEffect(.breathe)
            
            Text("Select a note to get started")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Create a new note or choose from your existing notes")
                .font(.body)
                .foregroundColor(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// Separate window view for note editing
struct NoteEditorWindowView: View {
    let noteID: Note.ID
    @Environment(\.modelContext) private var modelContext
    @StateObject private var noteViewModel = NoteViewModel()
    @State private var note: Note?
    
    var body: some View {
        Group {
            if let note = note {
                NoteEditorView(note: note, noteViewModel: noteViewModel)
            } else {
                ProgressView("Loading note...")
            }
        }
        .onAppear {
            loadNote()
        }
    }
    
    private func loadNote() {
        noteViewModel.setupModelContext(modelContext)
        
        let fetchDescriptor = FetchDescriptor<Note>(
            predicate: #Predicate { $0.id == noteID }
        )
        
        do {
            let notes = try modelContext.fetch(fetchDescriptor)
            self.note = notes.first
        } catch {
            print("Error loading note: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}
