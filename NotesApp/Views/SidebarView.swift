import SwiftUI

/// Sidebar view for iPad navigation with folders and smart collections
struct SidebarView: View {
    @Binding var selectedFolder: Folder?
    @ObservedObject var noteViewModel: NoteViewModel
    
    @State private var showingNewFolderSheet = false
    @State private var showingFolderSettings = false
    @State private var selectedFolderForSettings: Folder?
    @State private var expandedFolders: Set<UUID> = []
    
    var body: some View {
        List(selection: $selectedFolder) {
            // Smart Collections Section
            Section("Smart Collections") {
                SmartCollectionRow(
                    icon: "tray.fill",
                    title: "All Notes",
                    count: noteViewModel.notes.filter { !$0.isArchived }.count,
                    color: .blue
                ) {
                    selectedFolder = nil
                }
                
                SmartCollectionRow(
                    icon: "heart.fill",
                    title: "Favorites",
                    count: noteViewModel.favoriteNotes.count,
                    color: .red
                ) {
                    // Handle favorites selection
                }
                
                SmartCollectionRow(
                    icon: "clock.fill",
                    title: "Recent",
                    count: noteViewModel.recentNotes.count,
                    color: .orange
                ) {
                    // Handle recent selection
                }
                
                SmartCollectionRow(
                    icon: "archivebox.fill",
                    title: "Archived",
                    count: noteViewModel.archivedNotes.count,
                    color: .gray
                ) {
                    // Handle archived selection
                }
            }
            
            // Folders Section
            Section {
                ForEach(rootFolders, id: \.id) { folder in
                    FolderRowView(
                        folder: folder,
                        selectedFolder: $selectedFolder,
                        expandedFolders: $expandedFolders,
                        noteViewModel: noteViewModel,
                        onSettingsTap: { folder in
                            selectedFolderForSettings = folder
                            showingFolderSettings = true
                        }
                    )
                }
                .onDelete(perform: deleteFolders)
            } header: {
                HStack {
                    Text("Folders")
                    Spacer()
                    Button(action: { showingNewFolderSheet = true }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Folder", systemImage: "folder.badge.plus") {
                        showingNewFolderSheet = true
                    }
                    
                    Button("Settings", systemImage: "gear") {
                        // Handle settings
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewFolderSheet) {
            NewFolderSheet(noteViewModel: noteViewModel)
        }
        .sheet(isPresented: $showingFolderSettings) {
            if let folder = selectedFolderForSettings {
                FolderSettingsSheet(folder: folder, noteViewModel: noteViewModel)
            }
        }
    }
    
    /// Get root folders (folders without parent)
    private var rootFolders: [Folder] {
        noteViewModel.folders.filter { $0.parentFolder == nil }
    }
    
    /// Delete folders
    private func deleteFolders(offsets: IndexSet) {
        for index in offsets {
            let folder = rootFolders[index]
            noteViewModel.deleteFolder(folder)
        }
    }
}

/// Smart collection row view
struct SmartCollectionRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Folder row view with hierarchical support
struct FolderRowView: View {
    let folder: Folder
    @Binding var selectedFolder: Folder?
    @Binding var expandedFolders: Set<UUID>
    @ObservedObject var noteViewModel: NoteViewModel
    let onSettingsTap: (Folder) -> Void
    
    private var isExpanded: Bool {
        expandedFolders.contains(folder.id)
    }
    
    private var hasSubfolders: Bool {
        !folder.subfolders.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main folder row
            HStack {
                // Expansion indicator
                if hasSubfolders {
                    Button(action: toggleExpansion) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Spacer()
                        .frame(width: 16)
                }
                
                // Folder icon
                Image(systemName: folder.icon)
                    .foregroundColor(folder.swiftUIColor)
                    .frame(width: 20)
                
                // Folder name
                Button(action: { selectedFolder = folder }) {
                    HStack {
                        Text(folder.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Note count
                        if folder.totalNoteCount > 0 {
                            Text("\(folder.totalNoteCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Settings button
                Button(action: { onSettingsTap(folder) }) {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 2)
            
            // Subfolders
            if hasSubfolders && isExpanded {
                ForEach(folder.subfolders, id: \.id) { subfolder in
                    FolderRowView(
                        folder: subfolder,
                        selectedFolder: $selectedFolder,
                        expandedFolders: $expandedFolders,
                        noteViewModel: noteViewModel,
                        onSettingsTap: onSettingsTap
                    )
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isExpanded {
                expandedFolders.remove(folder.id)
            } else {
                expandedFolders.insert(folder.id)
            }
        }
    }
}

/// New folder creation sheet
struct NewFolderSheet: View {
    @ObservedObject var noteViewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName = ""
    @State private var selectedColor = FolderColor.blue
    @State private var selectedIcon = FolderIcon.folder
    @State private var parentFolder: Folder?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Parent Folder", selection: $parentFolder) {
                        Text("None").tag(nil as Folder?)
                        ForEach(noteViewModel.folders, id: \.id) { folder in
                            Text(folder.name).tag(folder as Folder?)
                        }
                    }
                }
                
                Section("Appearance") {
                    // Color picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(FolderColor.allCases, id: \.rawValue) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Icon picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(FolderIcon.allCases, id: \.rawValue) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon.rawValue)
                                    .font(.title2)
                                    .foregroundColor(selectedColor.color)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.secondary.opacity(0.3) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createFolder() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        noteViewModel.createFolder(
            name: trimmedName,
            color: selectedColor.rawValue,
            icon: selectedIcon.rawValue,
            parent: parentFolder
        )
        
        dismiss()
    }
}

/// Folder settings sheet
struct FolderSettingsSheet: View {
    let folder: Folder
    @ObservedObject var noteViewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var folderName: String
    @State private var selectedColor: FolderColor
    @State private var selectedIcon: FolderIcon
    @State private var showingDeleteAlert = false
    
    init(folder: Folder, noteViewModel: NoteViewModel) {
        self.folder = folder
        self.noteViewModel = noteViewModel
        self._folderName = State(initialValue: folder.name)
        self._selectedColor = State(initialValue: FolderColor(rawValue: folder.color) ?? .blue)
        self._selectedIcon = State(initialValue: FolderIcon(rawValue: folder.icon) ?? .folder)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Folder Details") {
                    TextField("Folder Name", text: $folderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(folder.formattedCreatedDate)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Notes")
                        Spacer()
                        Text("\(folder.totalNoteCount)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Appearance") {
                    // Color picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(FolderColor.allCases, id: \.rawValue) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Icon picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(FolderIcon.allCases, id: \.rawValue) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon.rawValue)
                                    .font(.title2)
                                    .foregroundColor(selectedColor.color)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color.secondary.opacity(0.3) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section {
                    Button("Delete Folder", role: .destructive) {
                        showingDeleteAlert = true
                    }
                    .disabled(folder.isDefault)
                }
            }
            .navigationTitle("Folder Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .alert("Delete Folder", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    noteViewModel.deleteFolder(folder)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this folder? Notes will be moved to the default folder.")
            }
        }
    }
    
    private func saveChanges() {
        let trimmedName = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        noteViewModel.updateFolder(
            folder,
            name: trimmedName,
            color: selectedColor.rawValue,
            icon: selectedIcon.rawValue
        )
        
        dismiss()
    }
}

#Preview {
    NavigationView {
        SidebarView(
            selectedFolder: .constant(nil),
            noteViewModel: NoteViewModel()
        )
    }
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}

