import SwiftUI
import PencilKit

/// Top toolbar for drawing view with advanced controls
struct TopDrawingToolbar: View {
    @Binding var showingToolPalette: Bool
    let canvasView: PKCanvasView
    @ObservedObject var shapeRecognizer: ShapeRecognizer
    
    @State private var showingShapeRecognition = false
    @State private var showingDrawingAnalytics = false
    @State private var showingZoomControls = false
    @State private var currentZoom: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool palette toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingToolPalette.toggle()
                }
            }) {
                Image(systemName: showingToolPalette ? "paintbrush.fill" : "paintbrush")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(ToolbarButtonStyle())
            
            Spacer()
            
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: zoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(ToolbarButtonStyle(compact: true))
                .disabled(currentZoom <= 0.25)
                
                Button(action: resetZoom) {
                    Text("\(Int(currentZoom * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(minWidth: 40)
                }
                .buttonStyle(ToolbarButtonStyle(compact: true))
                
                Button(action: zoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(ToolbarButtonStyle(compact: true))
                .disabled(currentZoom >= 4.0)
            }
            
            Spacer()
            
            // Shape recognition toggle
            Button(action: {
                shapeRecognizer.isEnabled.toggle()
                
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: shapeRecognizer.isEnabled ? "square.on.circle.fill" : "square.on.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(shapeRecognizer.isEnabled ? .accentColor : .secondary)
            }
            .buttonStyle(ToolbarButtonStyle())
            
            // More options menu
            Menu {
                ToolbarMenuContent(
                    canvasView: canvasView,
                    shapeRecognizer: shapeRecognizer,
                    showingShapeRecognition: $showingShapeRecognition,
                    showingDrawingAnalytics: $showingDrawingAnalytics
                )
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
            .buttonStyle(ToolbarButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .sheet(isPresented: $showingShapeRecognition) {
            ShapeRecognitionSheet(shapeRecognizer: shapeRecognizer)
        }
        .sheet(isPresented: $showingDrawingAnalytics) {
            DrawingAnalyticsSheet(canvasView: canvasView)
        }
        .onAppear {
            updateZoomLevel()
        }
    }
    
    // MARK: - Zoom Controls
    
    private func zoomIn() {
        let newZoom = min(currentZoom * 1.25, 4.0)
        canvasView.zoomScale = newZoom
        currentZoom = newZoom
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func zoomOut() {
        let newZoom = max(currentZoom / 1.25, 0.25)
        canvasView.zoomScale = newZoom
        currentZoom = newZoom
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func resetZoom() {
        canvasView.zoomScale = 1.0
        currentZoom = 1.0
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateZoomLevel() {
        currentZoom = canvasView.zoomScale
    }
}

/// Toolbar button style
struct ToolbarButtonStyle: ButtonStyle {
    let compact: Bool
    
    init(compact: Bool = false) {
        self.compact = compact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: compact ? 32 : 40, height: compact ? 32 : 40)
            .background(
                RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                    .fill(configuration.isPressed ? Color(.systemGray4) : Color(.systemGray6))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Toolbar menu content
struct ToolbarMenuContent: View {
    let canvasView: PKCanvasView
    @ObservedObject var shapeRecognizer: ShapeRecognizer
    @Binding var showingShapeRecognition: Bool
    @Binding var showingDrawingAnalytics: Bool
    
    var body: some View {
        Group {
            // Canvas actions
            Button("Clear Canvas", systemImage: "trash") {
                clearCanvas()
            }
            .foregroundColor(.red)
            
            Button("Fit to Screen", systemImage: "arrow.up.left.and.arrow.down.right") {
                fitCanvasToScreen()
            }
            
            Divider()
            
            // Shape recognition
            Button("Shape Recognition", systemImage: "square.on.circle") {
                showingShapeRecognition = true
            }
            
            Button("Convert Shapes", systemImage: "wand.and.rays") {
                convertRecognizedShapes()
            }
            .disabled(shapeRecognizer.recognizedShapes.isEmpty)
            
            Divider()
            
            // Analytics and tools
            Button("Drawing Analytics", systemImage: "chart.bar") {
                showingDrawingAnalytics = true
            }
            
            Button("Grid Overlay", systemImage: "grid") {
                toggleGridOverlay()
            }
            
            Button("Ruler Mode", systemImage: "ruler") {
                toggleRulerMode()
            }
        }
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        
        // Provide haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    private func fitCanvasToScreen() {
        // Calculate the bounds of all strokes
        let drawingBounds = canvasView.drawing.bounds
        
        if !drawingBounds.isEmpty {
            // Zoom to fit the drawing
            canvasView.zoomScale = 1.0
            canvasView.contentOffset = CGPoint(
                x: drawingBounds.midX - canvasView.bounds.midX,
                y: drawingBounds.midY - canvasView.bounds.midY
            )
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func convertRecognizedShapes() {
        // Convert recognized shapes to perfect geometric shapes
        for shape in shapeRecognizer.recognizedShapes {
            let perfectShape = shapeRecognizer.convertToShape(shape)
            // Add the perfect shape to the canvas
            // This would require more complex PKDrawing manipulation
        }
        
        // Provide haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func toggleGridOverlay() {
        // Toggle grid overlay on canvas
        // This would require custom overlay implementation
    }
    
    private func toggleRulerMode() {
        // Toggle ruler mode for straight lines
        // This would modify the drawing tool behavior
    }
}

/// Shape recognition settings sheet
struct ShapeRecognitionSheet: View {
    @ObservedObject var shapeRecognizer: ShapeRecognizer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Recognition Settings") {
                    Toggle("Enable Shape Recognition", isOn: $shapeRecognizer.isEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Threshold")
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { Double(shapeRecognizer.confidenceThreshold) },
                                set: { shapeRecognizer.confidenceThreshold = Float($0) }
                            ), in: 0.1...1.0)
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(Int(shapeRecognizer.confidenceThreshold * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Recognized Shapes") {
                    if shapeRecognizer.recognizedShapes.isEmpty {
                        Text("No shapes recognized yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(shapeRecognizer.recognizedShapes) { shape in
                            ShapeRecognitionRow(shape: shape)
                        }
                    }
                }
                
                Section("Supported Shapes") {
                    ForEach(RecognizedShape.ShapeType.allCases, id: \.rawValue) { shapeType in
                        HStack {
                            Image(systemName: shapeType.systemImage)
                                .foregroundColor(.accentColor)
                                .frame(width: 24)
                            
                            Text(shapeType.displayName)
                            
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Shape Recognition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Individual shape recognition row
struct ShapeRecognitionRow: View {
    let shape: RecognizedShape
    
    var body: some View {
        HStack {
            Image(systemName: shape.type.systemImage)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(shape.type.displayName)
                    .font(.body)
                
                Text("Confidence: \(Int(shape.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Confidence indicator
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private var confidenceColor: Color {
        if shape.confidence > 0.8 {
            return .green
        } else if shape.confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Drawing analytics sheet
struct DrawingAnalyticsSheet: View {
    let canvasView: PKCanvasView
    @Environment(\.dismiss) private var dismiss
    
    @State private var analytics: DrawingAnalytics?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let analytics = analytics {
                        // Drawing statistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Drawing Statistics")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            StatisticCard(
                                title: "Total Strokes",
                                value: "\(analytics.totalStrokes)",
                                icon: "pencil.tip",
                                color: .blue
                            )
                            
                            StatisticCard(
                                title: "Drawing Time",
                                value: formatTime(analytics.totalDrawingTime),
                                icon: "clock",
                                color: .green
                            )
                            
                            StatisticCard(
                                title: "Average Stroke Duration",
                                value: String(format: "%.1fs", analytics.averageStrokeDuration),
                                icon: "speedometer",
                                color: .orange
                            )
                            
                            if let lastSession = analytics.lastDrawingSession {
                                StatisticCard(
                                    title: "Last Session",
                                    value: formatDate(lastSession),
                                    icon: "calendar",
                                    color: .purple
                                )
                            }
                        }
                        
                        // Canvas information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Canvas Information")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            CanvasInfoCard(canvasView: canvasView)
                        }
                    } else {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Drawing Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadAnalytics()
            }
        }
    }
    
    private func loadAnalytics() {
        // In a real implementation, this would load from DrawingToolManager
        analytics = DrawingAnalytics(
            totalStrokes: canvasView.drawing.strokes.count,
            averageStrokeDuration: 0.5, // Mock data
            totalDrawingTime: 120.0, // Mock data
            lastDrawingSession: Date()
        )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Statistic card component
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Canvas information card
struct CanvasInfoCard: View {
    let canvasView: PKCanvasView
    
    var body: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Zoom Level", value: "\(Int(canvasView.zoomScale * 100))%")
            InfoRow(label: "Canvas Size", value: "\(Int(canvasView.bounds.width)) × \(Int(canvasView.bounds.height))")
            InfoRow(label: "Drawing Bounds", value: formatBounds(canvasView.drawing.bounds))
            InfoRow(label: "Stroke Count", value: "\(canvasView.drawing.strokes.count)")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func formatBounds(_ bounds: CGRect) -> String {
        if bounds.isEmpty {
            return "Empty"
        }
        return "\(Int(bounds.width)) × \(Int(bounds.height))"
    }
}

/// Information row component
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TopDrawingToolbar(
        showingToolPalette: .constant(true),
        canvasView: PKCanvasView(),
        shapeRecognizer: ShapeRecognizer()
    )
}

