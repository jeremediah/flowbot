import SwiftUI
import PencilKit
import UIKit

/// Enhanced drawing view with advanced Apple Pencil features
struct EnhancedDrawingView: View {
    @Binding var canvasView: PKCanvasView
    let note: Note
    @StateObject private var drawingToolManager = DrawingToolManager()
    @StateObject private var shapeRecognizer = ShapeRecognizer()
    
    @State private var showingToolPalette = true
    @State private var isDrawingMode = true
    @State private var selectedTool: DrawingTool = .pen
    @State private var showingColorPicker = false
    @State private var showingBrushSettings = false
    
    var body: some View {
        ZStack {
            // Main drawing canvas
            EnhancedCanvasView(
                canvasView: $canvasView,
                note: note,
                toolManager: drawingToolManager,
                shapeRecognizer: shapeRecognizer,
                selectedTool: $selectedTool,
                isDrawingMode: $isDrawingMode
            )
            
            // Floating tool palette
            if showingToolPalette {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        FloatingToolPalette(
                            selectedTool: $selectedTool,
                            toolManager: drawingToolManager,
                            showingColorPicker: $showingColorPicker,
                            showingBrushSettings: $showingBrushSettings,
                            isDrawingMode: $isDrawingMode
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            
            // Top toolbar
            VStack {
                TopDrawingToolbar(
                    showingToolPalette: $showingToolPalette,
                    canvasView: canvasView,
                    shapeRecognizer: shapeRecognizer
                )
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(toolManager: drawingToolManager)
        }
        .sheet(isPresented: $showingBrushSettings) {
            BrushSettingsSheet(toolManager: drawingToolManager)
        }
        .onAppear {
            setupDrawingEnvironment()
        }
    }
    
    private func setupDrawingEnvironment() {
        // Configure canvas for enhanced Apple Pencil features
        canvasView.drawingPolicy = .pencilOnly // Pencil-only mode for precision
        canvasView.backgroundColor = UIColor.systemBackground
        
        // Enable advanced gesture recognition
        if #available(iOS 14.0, *) {
            canvasView.drawingGestureRecognizer.isEnabled = true
        }
        
        // Set initial tool
        updateCanvasTool()
    }
    
    private func updateCanvasTool() {
        canvasView.tool = drawingToolManager.createPKTool(for: selectedTool)
    }
}

/// Enhanced canvas view with Apple Pencil optimizations
struct EnhancedCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let note: Note
    @ObservedObject var toolManager: DrawingToolManager
    @ObservedObject var shapeRecognizer: ShapeRecognizer
    @Binding var selectedTool: DrawingTool
    @Binding var isDrawingMode: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .pencilOnly
        canvasView.backgroundColor = UIColor.systemBackground
        
        // Enhanced Apple Pencil settings
        canvasView.allowsFingerDrawing = false // Pencil-only for precision
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 4.0
        canvasView.minimumZoomScale = 0.25
        
        // Enable advanced gestures
        if #available(iOS 14.0, *) {
            canvasView.drawingGestureRecognizer.isEnabled = true
        }
        
        // Add custom gesture recognizers
        addCustomGestures(to: canvasView, coordinator: context.coordinator)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update tool when selection changes
        uiView.tool = toolManager.createPKTool(for: selectedTool)
        
        // Update drawing policy based on mode
        uiView.drawingPolicy = isDrawingMode ? .pencilOnly : .default
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func addCustomGestures(to canvasView: PKCanvasView, coordinator: Coordinator) {
        // Double-tap gesture for tool switching
        let doubleTapGesture = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        canvasView.addGestureRecognizer(doubleTapGesture)
        
        // Long press for lasso tool
        let longPressGesture = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.5
        canvasView.addGestureRecognizer(longPressGesture)
        
        // Two-finger tap for undo
        let twoFingerTap = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(Coordinator.handleTwoFingerTap(_:))
        )
        twoFingerTap.numberOfTouchesRequired = 2
        canvasView.addGestureRecognizer(twoFingerTap)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: EnhancedCanvasView
        private var lastStrokeTime = Date()
        
        init(_ parent: EnhancedCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update note's handwriting status
            parent.note.hasHandwriting = !canvasView.drawing.strokes.isEmpty
            
            // Auto-save drawing data
            saveDrawingData(canvasView)
            
            // Trigger shape recognition if enabled
            if parent.shapeRecognizer.isEnabled {
                recognizeShapes(in: canvasView)
            }
            
            // Provide haptic feedback for stroke completion
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            lastStrokeTime = Date()
            
            // Provide haptic feedback for stroke start
            let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
        
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            // Calculate stroke duration for analytics
            let strokeDuration = Date().timeIntervalSince(lastStrokeTime)
            parent.toolManager.recordStrokeMetrics(duration: strokeDuration)
            
            // Auto-save after stroke completion
            saveDrawingData(canvasView)
        }
        
        private func saveDrawingData(_ canvasView: PKCanvasView) {
            do {
                let drawingData = canvasView.drawing.dataRepresentation()
                parent.note.handwritingData = drawingData
            } catch {
                print("Failed to save drawing: \(error)")
            }
        }
        
        private func recognizeShapes(in canvasView: PKCanvasView) {
            Task {
                await parent.shapeRecognizer.recognizeShapes(in: canvasView.drawing)
            }
        }
        
        // MARK: - Gesture Handlers
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            // Switch between pen and eraser on double-tap
            DispatchQueue.main.async {
                self.parent.selectedTool = self.parent.selectedTool == .pen ? .eraser : .pen
                
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                // Activate lasso tool on long press
                DispatchQueue.main.async {
                    self.parent.selectedTool = .lasso
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }
            }
        }
        
        @objc func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
            // Undo last action on two-finger tap
            if parent.canvasView.undoManager?.canUndo == true {
                parent.canvasView.undoManager?.undo()
                
                // Provide haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }
}

/// Drawing tool enumeration
enum DrawingTool: String, CaseIterable {
    case pen = "pen"
    case pencil = "pencil"
    case marker = "marker"
    case eraser = "eraser"
    case lasso = "lasso"
    case ruler = "ruler"
    
    var displayName: String {
        switch self {
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .marker: return "Marker"
        case .eraser: return "Eraser"
        case .lasso: return "Lasso"
        case .ruler: return "Ruler"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        case .ruler: return "ruler"
        }
    }
}

/// Drawing tool manager for advanced Apple Pencil features
@MainActor
final class DrawingToolManager: ObservableObject {
    @Published var currentColor: UIColor = .black
    @Published var currentWidth: CGFloat = 2.0
    @Published var currentOpacity: CGFloat = 1.0
    @Published var pressureSensitive = true
    @Published var tiltSensitive = true
    @Published var palmRejectionEnabled = true
    
    // Advanced brush settings
    @Published var brushTexture: BrushTexture = .smooth
    @Published var blendMode: CGBlendMode = .normal
    @Published var customColors: [UIColor] = []
    
    // Analytics
    private var strokeMetrics: [StrokeMetric] = []
    
    enum BrushTexture: String, CaseIterable {
        case smooth = "smooth"
        case rough = "rough"
        case textured = "textured"
        case watercolor = "watercolor"
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    init() {
        setupDefaultColors()
    }
    
    /// Create PKTool for the specified drawing tool
    func createPKTool(for tool: DrawingTool) -> PKTool {
        switch tool {
        case .pen:
            return PKInkingTool(.pen, color: currentColor, width: currentWidth)
        case .pencil:
            return PKInkingTool(.pencil, color: currentColor, width: currentWidth)
        case .marker:
            return PKInkingTool(.marker, color: currentColor.withAlphaComponent(currentOpacity), width: currentWidth * 2)
        case .eraser:
            return PKEraserTool(.bitmap)
        case .lasso:
            return PKLassoTool()
        case .ruler:
            return PKInkingTool(.pen, color: currentColor, width: 1.0) // Ruler mode
        }
    }
    
    /// Setup default color palette
    private func setupDefaultColors() {
        customColors = [
            .black, .blue, .red, .green, .orange, .purple, .brown, .systemPink,
            .systemTeal, .systemIndigo, .systemMint, .systemCyan
        ]
    }
    
    /// Add custom color to palette
    func addCustomColor(_ color: UIColor) {
        if !customColors.contains(color) {
            customColors.append(color)
            
            // Limit to 20 custom colors
            if customColors.count > 20 {
                customColors.removeFirst()
            }
        }
    }
    
    /// Record stroke metrics for analytics
    func recordStrokeMetrics(duration: TimeInterval) {
        let metric = StrokeMetric(
            duration: duration,
            tool: "current", // Would track actual tool
            pressure: 1.0, // Would get from Apple Pencil
            timestamp: Date()
        )
        strokeMetrics.append(metric)
        
        // Keep only last 1000 metrics
        if strokeMetrics.count > 1000 {
            strokeMetrics.removeFirst(strokeMetrics.count - 1000)
        }
    }
    
    /// Get drawing analytics
    func getDrawingAnalytics() -> DrawingAnalytics {
        let totalStrokes = strokeMetrics.count
        let averageDuration = strokeMetrics.isEmpty ? 0 : strokeMetrics.map { $0.duration }.reduce(0, +) / Double(totalStrokes)
        let totalDrawingTime = strokeMetrics.map { $0.duration }.reduce(0, +)
        
        return DrawingAnalytics(
            totalStrokes: totalStrokes,
            averageStrokeDuration: averageDuration,
            totalDrawingTime: totalDrawingTime,
            lastDrawingSession: strokeMetrics.last?.timestamp
        )
    }
}

/// Stroke metric for analytics
struct StrokeMetric {
    let duration: TimeInterval
    let tool: String
    let pressure: Float
    let timestamp: Date
}

/// Drawing analytics data
struct DrawingAnalytics {
    let totalStrokes: Int
    let averageStrokeDuration: TimeInterval
    let totalDrawingTime: TimeInterval
    let lastDrawingSession: Date?
}

/// Shape recognition service
@MainActor
final class ShapeRecognizer: ObservableObject {
    @Published var isEnabled = true
    @Published var recognizedShapes: [RecognizedShape] = []
    @Published var confidenceThreshold: Float = 0.8
    
    /// Recognize shapes in the drawing
    func recognizeShapes(in drawing: PKDrawing) async {
        // This would integrate with Core ML or custom shape recognition
        // For now, we'll simulate shape recognition
        
        let shapes = await performShapeRecognition(drawing)
        
        await MainActor.run {
            self.recognizedShapes = shapes
        }
    }
    
    private func performShapeRecognition(_ drawing: PKDrawing) async -> [RecognizedShape] {
        // Simulate shape recognition processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // In a real implementation, this would:
        // 1. Analyze stroke patterns
        // 2. Use Core ML model for shape classification
        // 3. Calculate confidence scores
        // 4. Return recognized shapes with bounding boxes
        
        return [] // Placeholder
    }
    
    /// Convert recognized shape to perfect geometric shape
    func convertToShape(_ recognizedShape: RecognizedShape) -> PKDrawing {
        // This would create a perfect geometric shape
        // based on the recognized shape type
        return PKDrawing() // Placeholder
    }
}

/// Recognized shape data
struct RecognizedShape: Identifiable {
    let id = UUID()
    let type: ShapeType
    let confidence: Float
    let boundingBox: CGRect
    let originalStrokes: [PKStroke]
    
    enum ShapeType: String, CaseIterable {
        case circle = "circle"
        case rectangle = "rectangle"
        case triangle = "triangle"
        case line = "line"
        case arrow = "arrow"
        case star = "star"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var systemImage: String {
            switch self {
            case .circle: return "circle"
            case .rectangle: return "rectangle"
            case .triangle: return "triangle"
            case .line: return "line.diagonal"
            case .arrow: return "arrow.right"
            case .star: return "star"
            }
        }
    }
}

#Preview {
    EnhancedDrawingView(
        canvasView: .constant(PKCanvasView()),
        note: Note(title: "Test Note")
    )
}

