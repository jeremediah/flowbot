import SwiftUI

/// Template selection sheet for creating notes from templates
struct TemplateSelectionSheet: View {
    @ObservedObject var noteViewModel: NoteViewModel
    let selectedFolder: Folder?
    let onNoteCreated: (Note) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTemplate: NoteTemplate?
    
    private let templateColumns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose a Template")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start with a pre-designed template to organize your thoughts")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Template grid
                    LazyVGrid(columns: templateColumns, spacing: 16) {
                        ForEach(NoteTemplate.allCases, id: \.rawValue) { template in
                            TemplateCard(
                                template: template,
                                isSelected: selectedTemplate == template,
                                onSelect: { selectedTemplate = template }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createNoteFromTemplate()
                    }
                    .disabled(selectedTemplate == nil)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createNoteFromTemplate() {
        guard let template = selectedTemplate else { return }
        
        let newNote = noteViewModel.createNote(
            title: template == .blank ? "Untitled Note" : template.displayName,
            folder: selectedFolder,
            template: template
        )
        
        onNoteCreated(newNote)
        dismiss()
    }
}

/// Individual template card
struct TemplateCard: View {
    let template: NoteTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: template.systemImage)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    )
                
                // Title
                Text(template.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Description
                Text(templateDescription(for: template))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func templateDescription(for template: NoteTemplate) -> String {
        switch template {
        case .blank:
            return "Start with a clean slate"
        case .meeting:
            return "Organize meeting notes with agenda and action items"
        case .journal:
            return "Daily reflections and thoughts"
        case .todoList:
            return "Keep track of tasks and goals"
        case .lecture:
            return "Structure your class notes"
        case .brainstorm:
            return "Capture and organize ideas"
        case .recipe:
            return "Document cooking instructions"
        case .travel:
            return "Plan your trips and adventures"
        }
    }
}

/// New note sheet for basic note creation
struct NewNoteSheet: View {
    @ObservedObject var noteViewModel: NoteViewModel
    let selectedFolder: Folder?
    @Environment(\.dismiss) private var dismiss
    
    @State private var noteTitle = ""
    @State private var noteContent = ""
    @State private var selectedTemplate: NoteTemplate = .blank
    @State private var showingTemplateSelector = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Note Details") {
                    TextField("Note Title", text: $noteTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if selectedFolder != nil {
                        HStack {
                            Text("Folder")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: selectedFolder!.icon)
                                    .foregroundColor(selectedFolder!.swiftUIColor)
                                Text(selectedFolder!.name)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Template") {
                    Button(action: { showingTemplateSelector = true }) {
                        HStack {
                            Image(systemName: selectedTemplate.systemImage)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedTemplate.displayName)
                                    .foregroundColor(.primary)
                                
                                if selectedTemplate != .blank {
                                    Text("Pre-filled with template content")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if selectedTemplate == .blank {
                    Section("Content") {
                        TextEditor(text: $noteContent)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createNote()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingTemplateSelector) {
                TemplatePickerSheet(
                    selectedTemplate: $selectedTemplate,
                    onTemplateSelected: { template in
                        selectedTemplate = template
                        if noteTitle.isEmpty {
                            noteTitle = template.displayName
                        }
                    }
                )
            }
        }
    }
    
    private func createNote() {
        let title = noteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = title.isEmpty ? "Untitled Note" : title
        
        let newNote = noteViewModel.createNote(
            title: finalTitle,
            content: selectedTemplate == .blank ? noteContent : "",
            folder: selectedFolder,
            template: selectedTemplate == .blank ? nil : selectedTemplate
        )
        
        dismiss()
    }
}

/// Template picker sheet
struct TemplatePickerSheet: View {
    @Binding var selectedTemplate: NoteTemplate
    let onTemplateSelected: (NoteTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let templateColumns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: templateColumns, spacing: 12) {
                    ForEach(NoteTemplate.allCases, id: \.rawValue) { template in
                        TemplatePickerCard(
                            template: template,
                            isSelected: selectedTemplate == template,
                            onSelect: {
                                selectedTemplate = template
                                onTemplateSelected(template)
                                dismiss()
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Compact template picker card
struct TemplatePickerCard: View {
    let template: NoteTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: template.systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    )
                
                Text(template.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Template preview sheet
struct TemplatePreviewSheet: View {
    let template: NoteTemplate
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: template.systemImage)
                            .font(.title)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Template Preview")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Template content preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Preview:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(template.templateContent)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Template Preview")
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
}

#Preview {
    TemplateSelectionSheet(
        noteViewModel: NoteViewModel(),
        selectedFolder: nil,
        onNoteCreated: { _ in }
    )
    .modelContainer(for: [Note.self, Folder.self, Tag.self], inMemory: true)
}

