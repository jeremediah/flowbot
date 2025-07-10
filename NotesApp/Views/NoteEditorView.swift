import SwiftUI
import PencilKit
import UniformTypeIdentifiers

/// Main note editor with rich text and Apple Pencil support
struct NoteEditorView: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    
    @State private var title: String
    @State private var content: String
    @State private var isEditing = false
    @State private var showingTagEditor = false
    @State private var showingAttachmentPicker = false
    @State private var showingDrawingCanvas = false
    @State private var selectedTags: Set<Tag> = []
    @State private var canvasView = PKCanvasView()
    
    // Toolbar states
    @State private var showingFormatting = false
    @State private var showingShareSheet = false
    @State private var showingMoveSheet = false
    
    init(note: Note, noteViewModel: NoteViewModel) {
        self.note = note
        self.noteViewModel = noteViewModel
        self._title = State(initialValue: note.title)
        self._content = State(initialValue: note.content)
        self._selectedTags = State(initialValue: Set(note.tags))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title editor
            TitleEditorView(
                title: $title,
                isEditing: $isEditing,
                onCommit: saveNote
            )
            .padding(.horizontal)
            .padding(.top)
            
            // Tags section
            if !selectedTags.isEmpty || isEditing {
                TagsSection(
                    selectedTags: $selectedTags,
                    showingTagEditor: $showingTagEditor,
                    isEditing: isEditing
                )
                .padding(.horizontal)
            }
            
            // Content editor
            ScrollView {
                VStack(spacing: 16) {
                    // Text content
                    ContentEditorView(
                        content: $content,
                        isEditing: $isEditing,
                        onCommit: saveNote
                    )
                    .padding(.horizontal)
                    
                    // Drawing canvas (if has handwriting)
                    if note.hasHandwriting || showingDrawingCanvas {
                        DrawingCanvasView(
                            canvasView: $canvasView,
                            note: note,
                            isVisible: $showingDrawingCanvas
                        )
                        .frame(height: 300)
                        .padding(.horizontal)
                    }
                    
                    // Attachments
                    if !note.attachments.isEmpty {
                        AttachmentsSection(
                            attachments: note.attachments,
                            isEditing: isEditing
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Done") {
                        finishEditing()
                    }
                    .fontWeight(.semibold)
                } else {
                    Menu {
                        EditorMenuContent(
                            note: note,
                            noteViewModel: noteViewModel,
                            showingTagEditor: $showingTagEditor,
                            showingAttachmentPicker: $showingAttachmentPicker,
                            showingDrawingCanvas: $showingDrawingCanvas,
                            showingShareSheet: $showingShareSheet,
                            showingMoveSheet: $showingMoveSheet,
                            startEditing: startEditing
                        )
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onTapGesture {
            if !isEditing {
                startEditing()
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorSheet(
                selectedTags: $selectedTags,
                noteViewModel: noteViewModel
            )
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            AttachmentPickerSheet(note: note)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(note: note)
        }
        .sheet(isPresented: $showingMoveSheet) {
            MoveNoteSheet(note: note, noteViewModel: noteViewModel)
        }
        .onAppear {
            loadDrawingData()
        }
        .onDisappear {
            if isEditing {
                finishEditing()
            }
        }
    }
    
    private func startEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = true
        }
    }
    
    private func finishEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = false
        }
        saveNote()
        saveDrawingData()
        updateTags()
    }
    
    private func saveNote() {
        noteViewModel.updateNote(note, title: title, content: content)
    }
    
    private func updateTags() {
        // Remove tags that are no longer selected
        for tag in note.tags {
            if !selectedTags.contains(tag) {
                noteViewModel.removeTag(tag, from: note)
            }
        }
        
        // Add newly selected tags
        for tag in selectedTags {
            if !note.tags.contains(where: { $0.id == tag.id }) {
                noteViewModel.addTag(tag, to: note)
            }
        }
    }
    
    private func loadDrawingData() {
        if let drawingData = note.handwritingData {
            do {
                let drawing = try PKDrawing(data: drawingData)
                canvasView.drawing = drawing
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }
    }
    
    private func saveDrawingData() {
        if !canvasView.drawing.strokes.isEmpty {
            do {
                let drawingData = canvasView.drawing.dataRepresentation()
                note.handwritingData = drawingData
                note.hasHandwriting = true
            } catch {
                print("Failed to save drawing: \(error)")
            }
        }
    }
}

/// Title editor component
struct TitleEditorView: View {
    @Binding var title: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Note Title", text: $title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .focused($isFocused)
                    .onSubmit {
                        onCommit()
                    }
                    .onAppear {
                        isFocused = true
                    }
            } else {
                Text(title.isEmpty ? "Untitled Note" : title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(title.isEmpty ? .secondary : .primary)
            }
            
            Spacer()
        }
    }
}

/// Tags section component
struct TagsSection: View {
    @Binding var selectedTags: Set<Tag>
    @Binding var showingTagEditor: Bool
    let isEditing: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedTags), id: \.id) { tag in
                    TagChip(tag: tag, size: .medium)
                }
                
                if isEditing {
                    Button(action: { showingTagEditor = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add Tag")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

/// Content editor with rich text support
struct ContentEditorView: View {
    @Binding var content: String
    @Binding var isEditing: Bool
    let onCommit: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                TextEditor(text: $content)
                    .font(.body)
                    .focused($isFocused)
                    .frame(minHeight: 200)
                    .onAppear {
                        // Delay focus to allow animation to complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isFocused = true
                        }
                    }
            } else {
                if content.isEmpty {
                    Text("Tap to start writing...")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    Text(content)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

/// Drawing canvas wrapper for Apple Pencil support
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let note: Note
    @Binding var isVisible: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        
        // Enable Apple Pencil features
        if #available(iOS 14.0, *) {
            canvasView.drawingGestureRecognizer.isEnabled = true
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update canvas if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: DrawingCanvasView
        
        init(_ parent: DrawingCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Auto-save drawing changes
            parent.note.hasHandwriting = !canvasView.drawing.strokes.isEmpty
        }
    }
}

/// Attachments section
struct AttachmentsSection: View {
    let attachments: [Attachment]
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120, maximum: 200))
            ], spacing: 12) {
                ForEach(attachments, id: \.id) { attachment in
                    AttachmentThumbnail(attachment: attachment, isEditing: isEditing)
                }
            }
        }
    }
}

/// Individual attachment thumbnail
struct AttachmentThumbnail: View {
    let attachment: Attachment
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 80)
                .overlay(
                    Image(systemName: attachment.fileType.systemImage)
                        .font(.title)
                        .foregroundColor(.secondary)
                )
            
            Text(attachment.fileName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Text(attachment.formattedFileSize)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Editor menu content
struct EditorMenuContent: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    @Binding var showingTagEditor: Bool
    @Binding var showingAttachmentPicker: Bool
    @Binding var showingDrawingCanvas: Bool
    @Binding var showingShareSheet: Bool
    @Binding var showingMoveSheet: Bool
    let startEditing: () -> Void
    
    var body: some View {
        Group {
            Button("Edit", systemImage: "pencil") {
                startEditing()
            }
            
            Button("Add Drawing", systemImage: "pencil.tip") {
                showingDrawingCanvas = true
            }
            
            Button("Add Attachment", systemImage: "paperclip") {
                showingAttachmentPicker = true
            }
            
            Button("Manage Tags", systemImage: "tag") {
                showingTagEditor = true
            }
            
            Divider()
            
            Button("Move to Folder", systemImage: "folder") {
                showingMoveSheet = true
            }
            
            Button("Share", systemImage: "square.and.arrow.up") {
                showingShareSheet = true
            }
            
            Button(note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                   systemImage: note.isFavorite ? "heart.slash" : "heart") {
                noteViewModel.toggleFavorite(note)
            }
            
            Divider()
            
            Button("Archive", systemImage: "archivebox") {
                noteViewModel.toggleArchive(note)
            }
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                noteViewModel.deleteNote(note)
            }
        }
    }
}

/// Tag chip component
struct TagChip: View {
    let tag: Tag
    let size: ChipSize
    
    enum ChipSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .body
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            }
        }
    }
    
    var body: some View {
        Text(tag.name)
            .font(size.font)
            .padding(size.padding)
            .background(tag.swiftUIColor.opacity(0.2))
            .foregroundColor(tag.swiftUIColor)
            .clipShape(Capsule())
    }
}

/// Tag editor sheet
struct TagEditorSheet: View {
    @Binding var selectedTags: Set<Tag>
    @ObservedObject var noteViewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var newTagName = ""
    @State private var selectedColor = TagColor.blue
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return noteViewModel.tags
        } else {
            return noteViewModel.tags.filter { tag in
                tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search tags...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // New tag creation
                VStack(spacing: 12) {
                    HStack {
                        TextField("New tag name", text: $newTagName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Create") {
                            createNewTag()
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Color picker for new tag
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TagColor.allCases, id: \.rawValue) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Divider()
                
                // Tags list
                List {
                    ForEach(filteredTags, id: \.id) { tag in
                        TagRowView(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            onToggle: { toggleTag(tag) }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createNewTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newTag = noteViewModel.createTag(name: trimmedName, color: selectedColor.rawValue)
        selectedTags.insert(newTag)
        
        newTagName = ""
        selectedColor = .blue
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

/// Tag row in editor
struct TagRowView: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                TagChip(tag: tag, size: .medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Placeholder sheets for additional functionality
struct AttachmentPickerSheet: View {
    let note: Note
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Attachment Picker")
                .navigationTitle("Add Attachment")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct ShareSheet: View {
    let note: Note
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Share Options")
                .navigationTitle("Share Note")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct MoveNoteSheet: View {
    let note: Note
    @ObservedObject var noteViewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Move to Folder") {
                    ForEach(noteViewModel.folders, id: \.id) { folder in
                        Button(action: {
                            noteViewModel.moveNote(note, to: folder)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: folder.icon)
                                    .foregroundColor(folder.swiftUIColor)
                                Text(folder.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                if note.folder?.id == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Move Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let note = Note(title: "Sample Note", content: "This is a sample note content.")
    
    NavigationView {
        NoteEditorView(note: note, noteViewModel: NoteViewModel())
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}

