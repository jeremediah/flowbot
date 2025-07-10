import SwiftUI

/// Advanced search filters sheet
struct SearchFiltersSheet: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempFilters: SearchFilters
    
    init(searchViewModel: SearchViewModel) {
        self.searchViewModel = searchViewModel
        self._tempFilters = State(initialValue: searchViewModel.searchFilters)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Date Range Section
                Section("Date Range") {
                    Picker("Date Range", selection: $tempFilters.dateRange) {
                        ForEach(dateRangeOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if case .custom = tempFilters.dateRange {
                        CustomDateRangePicker(dateRange: $tempFilters.dateRange)
                    }
                }
                
                // Content Type Section
                Section("Content Type") {
                    Picker("Content Type", selection: $tempFilters.contentType) {
                        ForEach(contentTypeOptions, id: \.0) { option in
                            HStack {
                                Image(systemName: option.2)
                                Text(option.1)
                            }
                            .tag(option.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Folder Filter Section
                Section("Folder") {
                    FolderFilterPicker(selectedFolder: $tempFilters.selectedFolder)
                }
                
                // Tag Filter Section
                Section("Tags") {
                    TagFilterView(selectedTags: $tempFilters.selectedTags)
                }
                
                // Additional Options
                Section("Options") {
                    Toggle("Include Archived Notes", isOn: $tempFilters.includeArchived)
                }
                
                // Reset Section
                Section {
                    Button("Reset All Filters", role: .destructive) {
                        tempFilters = SearchFilters()
                    }
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var dateRangeOptions: [(SearchFilters.DateRange, String)] {
        [
            (.all, "All Time"),
            (.today, "Today"),
            (.thisWeek, "This Week"),
            (.thisMonth, "This Month"),
            (.thisYear, "This Year"),
            (.custom(from: Date(), to: Date()), "Custom Range")
        ]
    }
    
    private var contentTypeOptions: [(SearchFilters.ContentType, String, String)] {
        [
            (.all, "All Content", "doc.text"),
            (.textOnly, "Text Only", "textformat"),
            (.handwritingOnly, "Handwriting Only", "pencil.tip"),
            (.withAttachments, "With Attachments", "paperclip")
        ]
    }
    
    private func applyFilters() {
        searchViewModel.applyFilters(tempFilters)
        dismiss()
    }
}

/// Custom date range picker
struct CustomDateRangePicker: View {
    @Binding var dateRange: SearchFilters.DateRange
    @State private var fromDate = Date()
    @State private var toDate = Date()
    
    var body: some View {
        VStack(spacing: 12) {
            DatePicker("From", selection: $fromDate, displayedComponents: .date)
                .onChange(of: fromDate) { _, newValue in
                    updateDateRange()
                }
            
            DatePicker("To", selection: $toDate, displayedComponents: .date)
                .onChange(of: toDate) { _, newValue in
                    updateDateRange()
                }
        }
        .onAppear {
            if case .custom(let from, let to) = dateRange {
                fromDate = from
                toDate = to
            }
        }
    }
    
    private func updateDateRange() {
        dateRange = .custom(from: fromDate, to: toDate)
    }
}

/// Folder filter picker
struct FolderFilterPicker: View {
    @Binding var selectedFolder: Folder?
    
    var body: some View {
        NavigationLink(destination: FolderSelectionView(selectedFolder: $selectedFolder)) {
            HStack {
                Text("Selected Folder")
                Spacer()
                if let folder = selectedFolder {
                    HStack(spacing: 4) {
                        Image(systemName: folder.icon)
                            .foregroundColor(folder.swiftUIColor)
                        Text(folder.name)
                    }
                    .foregroundColor(.secondary)
                } else {
                    Text("All Folders")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

/// Folder selection view
struct FolderSelectionView: View {
    @Binding var selectedFolder: Folder?
    @Environment(\.dismiss) private var dismiss
    
    // This would typically come from the view model
    @State private var folders: [Folder] = []
    
    var body: some View {
        List {
            // All folders option
            Button(action: {
                selectedFolder = nil
                dismiss()
            }) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                    Text("All Folders")
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedFolder == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Individual folders
            ForEach(folders, id: \.id) { folder in
                Button(action: {
                    selectedFolder = folder
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: folder.icon)
                            .foregroundColor(folder.swiftUIColor)
                        Text(folder.name)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedFolder?.id == folder.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Select Folder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Tag filter view
struct TagFilterView: View {
    @Binding var selectedTags: [Tag]
    @State private var showingTagSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showingTagSelection = true }) {
                HStack {
                    Text("Selected Tags")
                    Spacer()
                    Text(selectedTags.isEmpty ? "None" : "\(selectedTags.count) selected")
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Display selected tags
            if !selectedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedTags, id: \.id) { tag in
                            TagChip(tag: tag, size: .small)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionSheet(selectedTags: $selectedTags)
        }
    }
}

/// Tag selection sheet
struct TagSelectionSheet: View {
    @Binding var selectedTags: [Tag]
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var availableTags: [Tag] = [] // This would come from view model
    
    private var filteredTags: [Tag] {
        if searchText.isEmpty {
            return availableTags
        } else {
            return availableTags.filter { tag in
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
                
                // Tags list
                List {
                    ForEach(filteredTags, id: \.id) { tag in
                        TagSelectionRow(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                            onToggle: { toggleTag(tag) }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

/// Tag selection row
struct TagSelectionRow: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                TagChip(tag: tag, size: .medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Filter summary view for displaying active filters
struct FilterSummaryView: View {
    let filters: SearchFilters
    let onClearFilter: (FilterType) -> Void
    
    enum FilterType {
        case dateRange
        case contentType
        case folder
        case tags
        case archived
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date range filter
                if filters.dateRange != .all {
                    FilterChip(
                        title: filters.dateRange.displayName,
                        icon: "calendar",
                        onRemove: { onClearFilter(.dateRange) }
                    )
                }
                
                // Content type filter
                if filters.contentType != .all {
                    FilterChip(
                        title: filters.contentType.displayName,
                        icon: "doc.text",
                        onRemove: { onClearFilter(.contentType) }
                    )
                }
                
                // Folder filter
                if let folder = filters.selectedFolder {
                    FilterChip(
                        title: folder.name,
                        icon: folder.icon,
                        onRemove: { onClearFilter(.folder) }
                    )
                }
                
                // Tags filter
                if !filters.selectedTags.isEmpty {
                    FilterChip(
                        title: "\(filters.selectedTags.count) tags",
                        icon: "tag",
                        onRemove: { onClearFilter(.tags) }
                    )
                }
                
                // Archived filter
                if filters.includeArchived {
                    FilterChip(
                        title: "Include Archived",
                        icon: "archivebox",
                        onRemove: { onClearFilter(.archived) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual filter chip
struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(title)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
    }
}

#Preview {
    SearchFiltersSheet(searchViewModel: SearchViewModel())
}

