import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("syncEnabled") private var syncEnabled = true
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("handwritingRecognition") private var handwritingRecognition = true
    @AppStorage("collaborationEnabled") private var collaborationEnabled = true
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    
    @State private var showingAbout = false
    @State private var showingExportOptions = false
    @State private var showingImportOptions = false
    @State private var showingStorageInfo = false
    
    var body: some View {
        NavigationView {
            Form {
                // Sync & Storage Section
                Section("Sync & Storage") {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                            Text("Sync notes across all your devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $syncEnabled)
                    }
                    
                    Button(action: { showingStorageInfo = true }) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text("Storage Info")
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Editor Settings Section
                Section("Editor") {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Save")
                            Text("Automatically save changes as you type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoSave)
                    }
                    
                    HStack {
                        Image(systemName: "pencil.tip")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Handwriting Recognition")
                            Text("Convert handwriting to searchable text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $handwritingRecognition)
                    }
                }
                
                // Collaboration Section
                Section("Collaboration") {
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real-time Collaboration")
                            Text("Allow others to edit shared notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $collaborationEnabled)
                    }
                    
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Collaboration Notifications")
                            Text("Get notified when others edit shared notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationEnabled)
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        
                        Text("Dark Mode")
                        
                        Spacer()
                        
                        Toggle("", isOn: $darkModeEnabled)
                    }
                    
                    NavigationLink(destination: ThemeSettingsView()) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.pink)
                                .frame(width: 24)
                            
                            Text("Themes & Colors")
                            
                            Spacer()
                        }
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Export Notes")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingImportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("Import Notes")
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Privacy Settings")
                        }
                    }
                    
                    NavigationLink(destination: SecuritySettingsView()) {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            Text("Security")
                        }
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text("Help & FAQ")
                        }
                    }
                    
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            Text("Send Feedback")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            Text("About")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
            }
            .sheet(isPresented: $showingImportOptions) {
                ImportOptionsView()
            }
            .sheet(isPresented: $showingStorageInfo) {
                StorageInfoView()
            }
        }
    }
    
    private func sendFeedback() {
        // Implement feedback functionality
        if let url = URL(string: "mailto:feedback@notesapp.com?subject=Notes App Feedback") {
            UIApplication.shared.open(url)
        }
    }
}

/// Theme settings view
struct ThemeSettingsView: View {
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("fontFamily") private var fontFamily = "system"
    
    private let accentColors = [
        ("blue", Color.blue),
        ("green", Color.green),
        ("orange", Color.orange),
        ("red", Color.red),
        ("purple", Color.purple),
        ("pink", Color.pink)
    ]
    
    private let fontFamilies = [
        ("system", "System"),
        ("serif", "Serif"),
        ("monospace", "Monospace")
    ]
    
    var body: some View {
        Form {
            Section("Accent Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(accentColors, id: \.0) { colorName, color in
                        Button(action: { accentColorName = colorName }) {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: accentColorName == colorName ? 2 : 0)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Typography") {
                Picker("Font Family", selection: $fontFamily) {
                    ForEach(fontFamilies, id: \.0) { family, name in
                        Text(name).tag(family)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(fontSize))pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $fontSize, in: 12...24, step: 1)
                    
                    Text("Sample text with current settings")
                        .font(.system(size: fontSize))
                        .padding(.top, 4)
                }
            }
        }
        .navigationTitle("Themes & Colors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Privacy settings view
struct PrivacySettingsView: View {
    @AppStorage("analyticsEnabled") private var analyticsEnabled = false
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled = true
    @AppStorage("locationServicesEnabled") private var locationServicesEnabled = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Analytics")
                        Text("Help improve the app by sharing usage data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $analyticsEnabled)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Crash Reporting")
                        Text("Automatically send crash reports to help fix bugs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $crashReportingEnabled)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location Services")
                        Text("Add location information to notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $locationServicesEnabled)
                }
            } footer: {
                Text("Your privacy is important to us. All data is processed securely and never shared with third parties.")
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Security settings view
struct SecuritySettingsView: View {
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = false
    @AppStorage("autoLockEnabled") private var autoLockEnabled = false
    @AppStorage("autoLockTimeout") private var autoLockTimeout = 300.0 // 5 minutes
    
    var body: some View {
        Form {
            Section("Authentication") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Face ID / Touch ID")
                        Text("Require biometric authentication to open the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $biometricAuthEnabled)
                }
            }
            
            Section("Auto Lock") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Lock")
                        Text("Automatically lock the app when inactive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoLockEnabled)
                }
                
                if autoLockEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto Lock Timeout: \(Int(autoLockTimeout / 60)) minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $autoLockTimeout, in: 60...1800, step: 60) // 1-30 minutes
                    }
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// About view
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // App icon and name
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    Text("Notes App")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Description
                Text("A powerful note-taking app designed for iPad with Apple Pencil support, real-time collaboration, and seamless iCloud sync.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "pencil.tip", text: "Apple Pencil Support")
                    FeatureRow(icon: "person.2", text: "Real-time Collaboration")
                    FeatureRow(icon: "icloud", text: "iCloud Sync")
                    FeatureRow(icon: "magnifyingglass", text: "Advanced Search")
                    FeatureRow(icon: "folder", text: "Smart Organization")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Copyright
                Text("© 2024 Notes App. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About")
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

/// Feature row for about view
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
        }
    }
}

/// Placeholder views for additional functionality
struct HelpView: View {
    var body: some View {
        Text("Help & FAQ")
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Export Options")
                .navigationTitle("Export Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Import Options")
                .navigationTitle("Import Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

struct StorageInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Storage usage chart would go here
                Text("Storage Information")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    StorageRow(label: "Notes", usage: "2.3 MB", color: .blue)
                    StorageRow(label: "Attachments", usage: "15.7 MB", color: .green)
                    StorageRow(label: "Handwriting", usage: "4.1 MB", color: .purple)
                    StorageRow(label: "Cache", usage: "1.2 MB", color: .orange)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Storage Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StorageRow: View {
    let label: String
    let usage: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(usage)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}

