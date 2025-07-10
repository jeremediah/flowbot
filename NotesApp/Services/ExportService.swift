import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// Service for exporting notes to various formats
@MainActor
final class ExportService: ObservableObject {
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "pdf"
        case markdown = "markdown"
        case plainText = "txt"
        case html = "html"
        case json = "json"
        
        var displayName: String {
            switch self {
            case .pdf: return "PDF"
            case .markdown: return "Markdown"
            case .plainText: return "Plain Text"
            case .html: return "HTML"
            case .json: return "JSON"
            }
        }
        
        var fileExtension: String {
            return rawValue
        }
        
        var systemImage: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .markdown: return "doc.text"
            case .plainText: return "doc.plaintext"
            case .html: return "globe"
            case .json: return "doc.badge.gearshape"
            }
        }
        
        var utType: UTType {
            switch self {
            case .pdf: return .pdf
            case .markdown: return UTType(filenameExtension: "md") ?? .plainText
            case .plainText: return .plainText
            case .html: return .html
            case .json: return .json
            }
        }
    }
    
    /// Export a single note
    func exportNote(_ note: Note, format: ExportFormat) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        let fileName = sanitizeFileName(note.title) + "." + format.fileExtension
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        exportProgress = 0.2
        
        switch format {
        case .pdf:
            try await exportToPDF(note: note, url: tempURL)
        case .markdown:
            try await exportToMarkdown(note: note, url: tempURL)
        case .plainText:
            try await exportToPlainText(note: note, url: tempURL)
        case .html:
            try await exportToHTML(note: note, url: tempURL)
        case .json:
            try await exportToJSON(note: note, url: tempURL)
        }
        
        exportProgress = 1.0
        lastExportURL = tempURL
        
        return tempURL
    }
    
    /// Export multiple notes
    func exportNotes(_ notes: [Note], format: ExportFormat) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        let fileName = "Notes_Export_\(Date().formatted(date: .abbreviated, time: .omitted)).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        switch format {
        case .pdf:
            try await exportMultipleNotesToPDF(notes: notes, url: tempURL)
        case .markdown:
            try await exportMultipleNotesToMarkdown(notes: notes, url: tempURL)
        case .plainText:
            try await exportMultipleNotesToPlainText(notes: notes, url: tempURL)
        case .html:
            try await exportMultipleNotesToHTML(notes: notes, url: tempURL)
        case .json:
            try await exportMultipleNotesToJSON(notes: notes, url: tempURL)
        }
        
        exportProgress = 1.0
        lastExportURL = tempURL
        
        return tempURL
    }
    
    // MARK: - Single Note Export Methods
    
    private func exportToPDF(note: Note, url: URL) async throws {
        let htmlContent = generateHTMLContent(for: note)
        
        await MainActor.run {
            exportProgress = 0.5
        }
        
        // Create PDF from HTML
        let pdfData = try await createPDFFromHTML(htmlContent)
        try pdfData.write(to: url)
        
        await MainActor.run {
            exportProgress = 0.9
        }
    }
    
    private func exportToMarkdown(note: Note, url: URL) async throws {
        var markdown = "# \(note.title)\n\n"
        
        // Add metadata
        markdown += "**Created:** \(note.formattedCreatedDate)\n"
        markdown += "**Modified:** \(note.formattedModifiedDate)\n\n"
        
        // Add tags
        if !note.tags.isEmpty {
            markdown += "**Tags:** \(note.tags.map { "#\($0.name)" }.joined(separator: " "))\n\n"
        }
        
        // Add content
        markdown += note.content
        
        // Add handwriting note if present
        if note.hasHandwriting {
            markdown += "\n\n---\n*Note: This note contains handwritten content that cannot be exported to Markdown.*"
        }
        
        await MainActor.run {
            exportProgress = 0.7
        }
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportToPlainText(note: Note, url: URL) async throws {
        var text = "\(note.title)\n"
        text += String(repeating: "=", count: note.title.count) + "\n\n"
        
        text += "Created: \(note.formattedCreatedDate)\n"
        text += "Modified: \(note.formattedModifiedDate)\n\n"
        
        if !note.tags.isEmpty {
            text += "Tags: \(note.tags.map { $0.name }.joined(separator: ", "))\n\n"
        }
        
        text += note.content
        
        if note.hasHandwriting {
            text += "\n\n[Note contains handwritten content]"
        }
        
        await MainActor.run {
            exportProgress = 0.7
        }
        
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportToHTML(note: Note, url: URL) async throws {
        let htmlContent = generateHTMLContent(for: note)
        
        await MainActor.run {
            exportProgress = 0.7
        }
        
        try htmlContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportToJSON(note: Note, url: URL) async throws {
        let exportData = NoteExportData(
            id: note.id.uuidString,
            title: note.title,
            content: note.content,
            createdAt: note.createdAt,
            modifiedAt: note.modifiedAt,
            isFavorite: note.isFavorite,
            isArchived: note.isArchived,
            hasHandwriting: note.hasHandwriting,
            tags: note.tags.map { $0.name },
            folderName: note.folder?.name,
            attachments: note.attachments.map { attachment in
                AttachmentExportData(
                    fileName: attachment.fileName,
                    fileType: attachment.fileType.rawValue,
                    fileSize: attachment.fileSize
                )
            }
        )
        
        await MainActor.run {
            exportProgress = 0.7
        }
        
        let jsonData = try JSONEncoder().encode(exportData)
        try jsonData.write(to: url)
    }
    
    // MARK: - Multiple Notes Export Methods
    
    private func exportMultipleNotesToPDF(notes: [Note], url: URL) async throws {
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Notes Export</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                .note { page-break-after: always; margin-bottom: 40px; }
                .note:last-child { page-break-after: auto; }
                h1 { color: #333; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
                .metadata { color: #666; font-size: 14px; margin-bottom: 20px; }
                .tags { margin: 10px 0; }
                .tag { background: #007AFF; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; }
            </style>
        </head>
        <body>
        """
        
        for (index, note) in notes.enumerated() {
            htmlContent += generateNoteHTML(note)
            
            await MainActor.run {
                exportProgress = Double(index + 1) / Double(notes.count) * 0.8
            }
        }
        
        htmlContent += "</body></html>"
        
        let pdfData = try await createPDFFromHTML(htmlContent)
        try pdfData.write(to: url)
    }
    
    private func exportMultipleNotesToMarkdown(notes: [Note], url: URL) async throws {
        var markdown = "# Notes Export\n\n"
        markdown += "Exported on: \(Date().formatted(date: .complete, time: .shortened))\n\n"
        markdown += "---\n\n"
        
        for (index, note) in notes.enumerated() {
            markdown += "# \(note.title)\n\n"
            markdown += "**Created:** \(note.formattedCreatedDate) | **Modified:** \(note.formattedModifiedDate)\n\n"
            
            if !note.tags.isEmpty {
                markdown += "**Tags:** \(note.tags.map { "#\($0.name)" }.joined(separator: " "))\n\n"
            }
            
            markdown += note.content
            
            if note.hasHandwriting {
                markdown += "\n\n*[Contains handwritten content]*"
            }
            
            if index < notes.count - 1 {
                markdown += "\n\n---\n\n"
            }
            
            await MainActor.run {
                exportProgress = Double(index + 1) / Double(notes.count) * 0.8
            }
        }
        
        try markdown.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportMultipleNotesToPlainText(notes: [Note], url: URL) async throws {
        var text = "NOTES EXPORT\n"
        text += String(repeating: "=", count: 50) + "\n\n"
        text += "Exported on: \(Date().formatted(date: .complete, time: .shortened))\n\n"
        
        for (index, note) in notes.enumerated() {
            text += "\(note.title)\n"
            text += String(repeating: "-", count: note.title.count) + "\n\n"
            text += "Created: \(note.formattedCreatedDate)\n"
            text += "Modified: \(note.formattedModifiedDate)\n"
            
            if !note.tags.isEmpty {
                text += "Tags: \(note.tags.map { $0.name }.joined(separator: ", "))\n"
            }
            
            text += "\n\(note.content)\n"
            
            if note.hasHandwriting {
                text += "\n[Contains handwritten content]\n"
            }
            
            if index < notes.count - 1 {
                text += "\n" + String(repeating: "=", count: 50) + "\n\n"
            }
            
            await MainActor.run {
                exportProgress = Double(index + 1) / Double(notes.count) * 0.8
            }
        }
        
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportMultipleNotesToHTML(notes: [Note], url: URL) async throws {
        var htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Notes Export</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                .header { text-align: center; margin-bottom: 40px; border-bottom: 2px solid #007AFF; padding-bottom: 20px; }
                .note { margin-bottom: 40px; padding: 20px; border: 1px solid #ddd; border-radius: 8px; }
                h1 { color: #333; }
                h2 { color: #007AFF; }
                .metadata { color: #666; font-size: 14px; margin-bottom: 20px; }
                .tags { margin: 10px 0; }
                .tag { background: #007AFF; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; }
                .content { line-height: 1.6; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Notes Export</h1>
                <p>Exported on: \(Date().formatted(date: .complete, time: .shortened))</p>
            </div>
        """
        
        for (index, note) in notes.enumerated() {
            htmlContent += generateNoteHTML(note)
            
            await MainActor.run {
                exportProgress = Double(index + 1) / Double(notes.count) * 0.8
            }
        }
        
        htmlContent += "</body></html>"
        
        try htmlContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportMultipleNotesToJSON(notes: [Note], url: URL) async throws {
        let exportData = NotesExportData(
            exportDate: Date(),
            totalNotes: notes.count,
            notes: notes.enumerated().map { index, note in
                defer {
                    Task { @MainActor in
                        exportProgress = Double(index + 1) / Double(notes.count) * 0.8
                    }
                }
                
                return NoteExportData(
                    id: note.id.uuidString,
                    title: note.title,
                    content: note.content,
                    createdAt: note.createdAt,
                    modifiedAt: note.modifiedAt,
                    isFavorite: note.isFavorite,
                    isArchived: note.isArchived,
                    hasHandwriting: note.hasHandwriting,
                    tags: note.tags.map { $0.name },
                    folderName: note.folder?.name,
                    attachments: note.attachments.map { attachment in
                        AttachmentExportData(
                            fileName: attachment.fileName,
                            fileType: attachment.fileType.rawValue,
                            fileSize: attachment.fileSize
                        )
                    }
                )
            }
        )
        
        let jsonData = try JSONEncoder().encode(exportData)
        try jsonData.write(to: url)
    }
    
    // MARK: - Helper Methods
    
    private func generateHTMLContent(for note: Note) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(note.title)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; line-height: 1.6; }
                h1 { color: #333; border-bottom: 2px solid #007AFF; padding-bottom: 10px; }
                .metadata { color: #666; font-size: 14px; margin-bottom: 20px; }
                .tags { margin: 10px 0; }
                .tag { background: #007AFF; color: white; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; }
                .content { margin-top: 20px; }
            </style>
        </head>
        <body>
            \(generateNoteHTML(note))
        </body>
        </html>
        """
    }
    
    private func generateNoteHTML(_ note: Note) -> String {
        var html = "<div class=\"note\">"
        html += "<h2>\(note.title)</h2>"
        html += "<div class=\"metadata\">"
        html += "Created: \(note.formattedCreatedDate) | Modified: \(note.formattedModifiedDate)"
        html += "</div>"
        
        if !note.tags.isEmpty {
            html += "<div class=\"tags\">"
            for tag in note.tags {
                html += "<span class=\"tag\">\(tag.name)</span>"
            }
            html += "</div>"
        }
        
        html += "<div class=\"content\">"
        html += note.content.replacingOccurrences(of: "\n", with: "<br>")
        html += "</div>"
        
        if note.hasHandwriting {
            html += "<p><em>[This note contains handwritten content]</em></p>"
        }
        
        html += "</div>"
        return html
    }
    
    private func createPDFFromHTML(_ htmlContent: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let webView = WKWebView()
                webView.loadHTMLString(htmlContent, baseURL: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    webView.createPDF { result in
                        switch result {
                        case .success(let data):
                            continuation.resume(returning: data)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return fileName.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}

// MARK: - Export Data Models

struct NotesExportData: Codable {
    let exportDate: Date
    let totalNotes: Int
    let notes: [NoteExportData]
}

struct NoteExportData: Codable {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let modifiedAt: Date
    let isFavorite: Bool
    let isArchived: Bool
    let hasHandwriting: Bool
    let tags: [String]
    let folderName: String?
    let attachments: [AttachmentExportData]
}

struct AttachmentExportData: Codable {
    let fileName: String
    let fileType: String
    let fileSize: Int64
}

// MARK: - Export Sheet View

struct ExportSheet: View {
    let notes: [Note]
    @ObservedObject var exportService: ExportService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportService.ExportFormat = .pdf
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Export Notes")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(notes.count) \(notes.count == 1 ? "note" : "notes") selected")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Format")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120))
                    ], spacing: 12) {
                        ForEach(ExportService.ExportFormat.allCases, id: \.rawValue) { format in
                            FormatCard(
                                format: format,
                                isSelected: selectedFormat == format,
                                onSelect: { selectedFormat = format }
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Export progress
                if exportService.isExporting {
                    VStack(spacing: 8) {
                        ProgressView(value: exportService.exportProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Exporting... \(Int(exportService.exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Export button
                Button(action: performExport) {
                    HStack {
                        if exportService.isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Text(exportService.isExporting ? "Exporting..." : "Export")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(exportService.isExporting)
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK") {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error)
                }
            }
        }
    }
    
    private func performExport() {
        Task {
            do {
                let url: URL
                if notes.count == 1 {
                    url = try await exportService.exportNote(notes[0], format: selectedFormat)
                } else {
                    url = try await exportService.exportNotes(notes, format: selectedFormat)
                }
                
                await MainActor.run {
                    exportURL = url
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

struct FormatCard: View {
    let format: ExportService.ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: format.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(format.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

import WebKit

#Preview {
    ExportSheet(notes: [], exportService: ExportService())
}

