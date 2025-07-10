import Foundation
import Vision
import PencilKit
import UIKit

/// Service for handwriting recognition using Vision framework
@MainActor
final class HandwritingRecognitionService: ObservableObject {
    @Published var isProcessing = false
    @Published var recognizedText = ""
    @Published var confidence: Float = 0.0
    
    private let recognitionQueue = DispatchQueue(label: "handwriting.recognition", qos: .userInitiated)
    
    /// Recognize text from PKDrawing
    func recognizeText(from drawing: PKDrawing) async -> HandwritingResult {
        isProcessing = true
        
        return await withCheckedContinuation { continuation in
            recognitionQueue.async {
                let result = self.performRecognition(drawing: drawing)
                
                Task { @MainActor in
                    self.isProcessing = false
                    self.recognizedText = result.text
                    self.confidence = result.confidence
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Recognize text from UIImage
    func recognizeText(from image: UIImage) async -> HandwritingResult {
        isProcessing = true
        
        return await withCheckedContinuation { continuation in
            recognitionQueue.async {
                let result = self.performRecognition(image: image)
                
                Task { @MainActor in
                    self.isProcessing = false
                    self.recognizedText = result.text
                    self.confidence = result.confidence
                    continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Perform recognition on PKDrawing
    private func performRecognition(drawing: PKDrawing) -> HandwritingResult {
        // Convert PKDrawing to UIImage
        let image = drawing.image(from: drawing.bounds, scale: 2.0)
        return performRecognition(image: image)
    }
    
    /// Perform recognition on UIImage using Vision framework
    private func performRecognition(image: UIImage) -> HandwritingResult {
        guard let cgImage = image.cgImage else {
            return HandwritingResult(text: "", confidence: 0.0, words: [])
        }
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Configure for handwriting recognition
        if #available(iOS 16.0, *) {
            request.automaticallyDetectsLanguage = true
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return HandwritingResult(text: "", confidence: 0.0, words: [])
            }
            
            var recognizedWords: [RecognizedWord] = []
            var fullText = ""
            var totalConfidence: Float = 0.0
            
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { continue }
                
                let word = RecognizedWord(
                    text: topCandidate.string,
                    confidence: topCandidate.confidence,
                    boundingBox: observation.boundingBox
                )
                
                recognizedWords.append(word)
                fullText += topCandidate.string + " "
                totalConfidence += topCandidate.confidence
            }
            
            let averageConfidence = observations.isEmpty ? 0.0 : totalConfidence / Float(observations.count)
            
            return HandwritingResult(
                text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
                confidence: averageConfidence,
                words: recognizedWords
            )
            
        } catch {
            print("Text recognition error: \(error)")
            return HandwritingResult(text: "", confidence: 0.0, words: [])
        }
    }
    
    /// Extract searchable text from handwriting data
    func extractSearchableText(from handwritingData: Data) async -> String {
        do {
            let drawing = try PKDrawing(data: handwritingData)
            let result = await recognizeText(from: drawing)
            return result.text
        } catch {
            print("Failed to extract searchable text: \(error)")
            return ""
        }
    }
    
    /// Batch process multiple drawings for search indexing
    func batchProcessDrawings(_ drawings: [Data]) async -> [String] {
        var results: [String] = []
        
        for drawingData in drawings {
            let text = await extractSearchableText(from: drawingData)
            results.append(text)
        }
        
        return results
    }
}

/// Result of handwriting recognition
struct HandwritingResult {
    let text: String
    let confidence: Float
    let words: [RecognizedWord]
    
    var isHighConfidence: Bool {
        confidence > 0.7
    }
    
    var formattedConfidence: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

/// Individual recognized word with metadata
struct RecognizedWord {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    
    var isHighConfidence: Bool {
        confidence > 0.8
    }
}

/// Handwriting recognition view for displaying results
struct HandwritingRecognitionView: View {
    @StateObject private var recognitionService = HandwritingRecognitionService()
    let drawing: PKDrawing
    let onTextRecognized: (String) -> Void
    
    @State private var showingResults = false
    @State private var recognitionResult: HandwritingResult?
    
    var body: some View {
        VStack(spacing: 16) {
            // Recognition button
            Button(action: performRecognition) {
                HStack {
                    if recognitionService.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "text.viewfinder")
                    }
                    
                    Text(recognitionService.isProcessing ? "Recognizing..." : "Recognize Handwriting")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(recognitionService.isProcessing || drawing.strokes.isEmpty)
            
            // Results
            if let result = recognitionResult, showingResults {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recognition Results")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("Confidence: \(result.formattedConfidence)")
                            .font(.caption)
                            .foregroundColor(result.isHighConfidence ? .green : .orange)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recognized Text:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(result.text.isEmpty ? "No text recognized" : result.text)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                            
                            if !result.words.isEmpty {
                                Text("Individual Words:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100))
                                ], spacing: 8) {
                                    ForEach(Array(result.words.enumerated()), id: \.offset) { index, word in
                                        WordChip(word: word)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    
                    // Action buttons
                    HStack {
                        Button("Use Text") {
                            onTextRecognized(result.text)
                            showingResults = false
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(result.text.isEmpty)
                        
                        Button("Copy") {
                            UIPasteboard.general.string = result.text
                        }
                        .buttonStyle(.bordered)
                        .disabled(result.text.isEmpty)
                        
                        Spacer()
                        
                        Button("Close") {
                            showingResults = false
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
            }
        }
    }
    
    private func performRecognition() {
        Task {
            let result = await recognitionService.recognizeText(from: drawing)
            recognitionResult = result
            showingResults = true
        }
    }
}

/// Individual word chip showing confidence
struct WordChip: View {
    let word: RecognizedWord
    
    var body: some View {
        VStack(spacing: 4) {
            Text(word.text)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(String(format: "%.0f%%", word.confidence * 100))
                .font(.caption2)
                .foregroundColor(word.isHighConfidence ? .green : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(word.isHighConfidence ? Color.green : Color.orange, lineWidth: 1)
                )
        )
    }
}

/// Enhanced drawing canvas with recognition integration
struct EnhancedDrawingCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var recognizedText: String
    let note: Note
    
    @StateObject private var recognitionService = HandwritingRecognitionService()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.delegate = context.coordinator
        
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
        let parent: EnhancedDrawingCanvas
        private var recognitionTimer: Timer?
        
        init(_ parent: EnhancedDrawingCanvas) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update note's handwriting status
            parent.note.hasHandwriting = !canvasView.drawing.strokes.isEmpty
            
            // Debounce recognition to avoid excessive processing
            recognitionTimer?.invalidate()
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                Task {
                    let result = await parent.recognitionService.recognizeText(from: canvasView.drawing)
                    await MainActor.run {
                        parent.recognizedText = result.text
                    }
                }
            }
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // Save drawing data when user finishes drawing
            do {
                let drawingData = canvasView.drawing.dataRepresentation()
                parent.note.handwritingData = drawingData
            } catch {
                print("Failed to save drawing: \(error)")
            }
        }
    }
}

#Preview {
    VStack {
        HandwritingRecognitionView(
            drawing: PKDrawing(),
            onTextRecognized: { text in
                print("Recognized: \(text)")
            }
        )
    }
    .padding()
}

