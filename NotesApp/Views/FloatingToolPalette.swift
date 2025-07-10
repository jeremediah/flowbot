import SwiftUI
import PencilKit

/// Floating tool palette with advanced Apple Pencil tools
struct FloatingToolPalette: View {
    @Binding var selectedTool: DrawingTool
    @ObservedObject var toolManager: DrawingToolManager
    @Binding var showingColorPicker: Bool
    @Binding var showingBrushSettings: Bool
    @Binding var isDrawingMode: Bool
    
    @State private var isExpanded = true
    @State private var dragOffset = CGSize.zero
    @State private var lastDragPosition = CGSize.zero
    
    private let toolSpacing: CGFloat = 8
    private let toolSize: CGFloat = 44
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapse/Expand button
            Button(action: { 
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: toolSize, height: 20)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: toolSpacing) {
                    // Drawing tools
                    ForEach(DrawingTool.allCases, id: \.rawValue) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: selectedTool == tool,
                            toolManager: toolManager,
                            action: { selectedTool = tool }
                        )
                    }
                    
                    Divider()
                        .frame(width: toolSize - 16)
                    
                    // Color indicator and picker
                    ColorIndicatorButton(
                        currentColor: toolManager.currentColor,
                        action: { showingColorPicker = true }
                    )
                    
                    // Brush settings
                    BrushSettingsButton(
                        action: { showingBrushSettings = true }
                    )
                    
                    Divider()
                        .frame(width: toolSize - 16)
                    
                    // Quick actions
                    QuickActionButtons(toolManager: toolManager)
                }
                .padding(.vertical, toolSpacing)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .offset(dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = CGSize(
                        width: lastDragPosition.width + value.translation.x,
                        height: lastDragPosition.height + value.translation.y
                    )
                }
                .onEnded { value in
                    lastDragPosition = dragOffset
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }
}

/// Individual tool button
struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    @ObservedObject var toolManager: DrawingToolManager
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                // Tool icon
                Image(systemName: tool.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        } perform: {}
        .contextMenu {
            ToolContextMenu(tool: tool, toolManager: toolManager)
        }
    }
}

/// Tool context menu for advanced options
struct ToolContextMenu: View {
    let tool: DrawingTool
    @ObservedObject var toolManager: DrawingToolManager
    
    var body: some View {
        Group {
            if tool != .eraser && tool != .lasso {
                Button("Customize \(tool.displayName)", systemImage: "slider.horizontal.3") {
                    // Open tool customization
                }
                
                Button("Duplicate Tool", systemImage: "doc.on.doc") {
                    // Duplicate tool with current settings
                }
                
                Divider()
            }
            
            Button("Tool Info", systemImage: "info.circle") {
                // Show tool information
            }
        }
    }
}

/// Color indicator button
struct ColorIndicatorButton: View {
    let currentColor: UIColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                // Color circle
                Circle()
                    .fill(Color(currentColor))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
                
                // Color picker icon
                Image(systemName: "eyedropper")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                    .offset(x: 8, y: -8)
                    .background(
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 16)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Brush settings button
struct BrushSettingsButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Quick action buttons
struct QuickActionButtons: View {
    @ObservedObject var toolManager: DrawingToolManager
    
    var body: some View {
        VStack(spacing: 8) {
            // Undo button
            QuickActionButton(
                icon: "arrow.uturn.backward",
                action: {
                    // Undo action would be handled by the canvas
                }
            )
            
            // Redo button
            QuickActionButton(
                icon: "arrow.uturn.forward",
                action: {
                    // Redo action would be handled by the canvas
                }
            )
            
            // Clear all button
            QuickActionButton(
                icon: "trash",
                color: .red,
                action: {
                    // Clear all action
                }
            )
        }
    }
}

/// Individual quick action button
struct QuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, color: Color = .primary, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Advanced color picker sheet
struct ColorPickerSheet: View {
    @ObservedObject var toolManager: DrawingToolManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedColor: Color = .black
    @State private var customColor: Color = .black
    @State private var showingCustomPicker = false
    
    private let colorColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current color preview
                    VStack(spacing: 12) {
                        Text("Current Color")
                            .font(.headline)
                        
                        Circle()
                            .fill(Color(toolManager.currentColor))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemGray3), lineWidth: 2)
                            )
                    }
                    
                    // Preset colors
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preset Colors")
                            .font(.headline)
                        
                        LazyVGrid(columns: colorColumns, spacing: 12) {
                            ForEach(toolManager.customColors.indices, id: \.self) { index in
                                ColorSwatch(
                                    color: toolManager.customColors[index],
                                    isSelected: toolManager.currentColor == toolManager.customColors[index],
                                    action: {
                                        toolManager.currentColor = toolManager.customColors[index]
                                        selectedColor = Color(toolManager.customColors[index])
                                    }
                                )
                            }
                        }
                    }
                    
                    // Custom color picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Color")
                            .font(.headline)
                        
                        ColorPicker("Choose Color", selection: $customColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(height: 200)
                        
                        Button("Use Custom Color") {
                            let uiColor = UIColor(customColor)
                            toolManager.currentColor = uiColor
                            toolManager.addCustomColor(uiColor)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Opacity slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Opacity")
                            .font(.headline)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $toolManager.currentOpacity, in: 0.1...1.0)
                            
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(Int(toolManager.currentOpacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Colors")
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

/// Color swatch component
struct ColorSwatch: View {
    let color: UIColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 3 : 1)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Brush settings sheet
struct BrushSettingsSheet: View {
    @ObservedObject var toolManager: DrawingToolManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Brush Size") {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Size")
                            Spacer()
                            Text("\(Int(toolManager.currentWidth))pt")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $toolManager.currentWidth, in: 1...50)
                        
                        // Size preview
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color(toolManager.currentColor))
                                .frame(width: toolManager.currentWidth, height: toolManager.currentWidth)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Brush Properties") {
                    Picker("Texture", selection: $toolManager.brushTexture) {
                        ForEach(DrawingToolManager.BrushTexture.allCases, id: \.rawValue) { texture in
                            Text(texture.displayName).tag(texture)
                        }
                    }
                    
                    Toggle("Pressure Sensitive", isOn: $toolManager.pressureSensitive)
                    Toggle("Tilt Sensitive", isOn: $toolManager.tiltSensitive)
                    Toggle("Palm Rejection", isOn: $toolManager.palmRejectionEnabled)
                }
                
                Section("Advanced") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blend Mode")
                        // Blend mode picker would go here
                        Text("Normal")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Brush Settings")
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

#Preview {
    FloatingToolPalette(
        selectedTool: .constant(.pen),
        toolManager: DrawingToolManager(),
        showingColorPicker: .constant(false),
        showingBrushSettings: .constant(false),
        isDrawingMode: .constant(true)
    )
    .padding()
}

