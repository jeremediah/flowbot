import SwiftUI

struct MaterialDetailView: View {
    let material: Material
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingPremiumAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                MaterialHeaderView(material: material)
                
                // Properties Sections
                if canViewMaterial {
                    VStack(spacing: 20) {
                        MechanicalPropertiesView(properties: material.properties)
                        ThermalPropertiesView(properties: material.properties)
                        ElectricalPropertiesView(properties: material.properties)
                        CostAvailabilityView(properties: material.properties)
                    }
                } else {
                    PremiumRequiredView {
                        showingPremiumAlert = true
                    }
                }
            }
            .padding()
        }
        .navigationTitle(material.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    materialViewModel.userPreferences.toggleFavorite(material.id)
                }) {
                    Image(systemName: materialViewModel.userPreferences.isFavorite(material.id) ? "heart.fill" : "heart")
                        .foregroundColor(materialViewModel.userPreferences.isFavorite(material.id) ? .red : .blue)
                }
                
                Button(action: {
                    if canViewMaterial {
                        materialViewModel.userPreferences.addToComparison(material)
                    } else {
                        showingPremiumAlert = true
                    }
                }) {
                    Image(systemName: "scale.3d")
                        .foregroundColor(.blue)
                }
            }
        }
        .alert("Premium Required", isPresented: $showingPremiumAlert) {
            Button("Upgrade") {
                // Navigate to premium purchase
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This material requires a premium subscription to view detailed properties.")
        }
    }
    
    private var canViewMaterial: Bool {
        !material.isPremium || purchaseManager.isPremiumUser
    }
}

struct MaterialHeaderView: View {
    let material: Material
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: material.category.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(material.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(material.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if material.isPremium && !purchaseManager.isPremiumUser {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                Text("Premium")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            
            Text(material.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MechanicalPropertiesView: View {
    let properties: MaterialProperties
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        PropertySectionView(title: "Mechanical Properties", icon: "hammer.fill") {
            VStack(spacing: 12) {
                if let density = properties.density {
                    PropertyRowView(
                        name: "Density",
                        value: materialViewModel.userPreferences.convertDensity(density),
                        unit: materialViewModel.userPreferences.preferredUnits.densityUnit,
                        format: "%.0f"
                    )
                }
                
                if let tensileStrength = properties.tensileStrength {
                    PropertyRowView(
                        name: "Tensile Strength",
                        value: materialViewModel.userPreferences.convertStrength(tensileStrength),
                        unit: materialViewModel.userPreferences.preferredUnits.strengthUnit,
                        format: "%.0f"
                    )
                }
                
                if let yieldStrength = properties.yieldStrength {
                    PropertyRowView(
                        name: "Yield Strength",
                        value: materialViewModel.userPreferences.convertStrength(yieldStrength),
                        unit: materialViewModel.userPreferences.preferredUnits.strengthUnit,
                        format: "%.0f"
                    )
                }
                
                if let elasticModulus = properties.elasticModulus {
                    PropertyRowView(
                        name: "Elastic Modulus",
                        value: materialViewModel.userPreferences.convertModulus(elasticModulus),
                        unit: materialViewModel.userPreferences.preferredUnits.modulusUnit,
                        format: "%.1f"
                    )
                }
                
                if let poissonRatio = properties.poissonRatio {
                    PropertyRowView(
                        name: "Poisson's Ratio",
                        value: poissonRatio,
                        unit: "",
                        format: "%.3f"
                    )
                }
                
                if let hardness = properties.hardness {
                    PropertyRowView(
                        name: "Hardness",
                        value: hardness,
                        unit: "HB",
                        format: "%.0f"
                    )
                }
            }
        }
    }
}

struct ThermalPropertiesView: View {
    let properties: MaterialProperties
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        PropertySectionView(title: "Thermal Properties", icon: "thermometer") {
            VStack(spacing: 12) {
                if let thermalConductivity = properties.thermalConductivity {
                    PropertyRowView(
                        name: "Thermal Conductivity",
                        value: materialViewModel.userPreferences.convertThermalConductivity(thermalConductivity),
                        unit: materialViewModel.userPreferences.preferredUnits.thermalConductivityUnit,
                        format: "%.1f"
                    )
                }
                
                if let specificHeat = properties.specificHeat {
                    PropertyRowView(
                        name: "Specific Heat",
                        value: specificHeat,
                        unit: "J/kg·K",
                        format: "%.0f"
                    )
                }
                
                if let thermalExpansion = properties.thermalExpansion {
                    PropertyRowView(
                        name: "Thermal Expansion",
                        value: thermalExpansion * 1e6,
                        unit: "µm/m·K",
                        format: "%.1f"
                    )
                }
                
                if let meltingPoint = properties.meltingPoint {
                    PropertyRowView(
                        name: "Melting Point",
                        value: materialViewModel.userPreferences.convertTemperature(meltingPoint),
                        unit: materialViewModel.userPreferences.preferredUnits.temperatureUnit,
                        format: "%.0f"
                    )
                }
            }
        }
    }
}

struct ElectricalPropertiesView: View {
    let properties: MaterialProperties
    
    var body: some View {
        PropertySectionView(title: "Electrical Properties", icon: "bolt.fill") {
            VStack(spacing: 12) {
                if let electricalResistivity = properties.electricalResistivity {
                    PropertyRowView(
                        name: "Electrical Resistivity",
                        value: electricalResistivity * 1e8,
                        unit: "µΩ·cm",
                        format: "%.2f"
                    )
                }
            }
        }
    }
}

struct CostAvailabilityView: View {
    let properties: MaterialProperties
    
    var body: some View {
        PropertySectionView(title: "Cost & Availability", icon: "dollarsign.circle.fill") {
            VStack(spacing: 12) {
                if let relativeCost = properties.relativeCost {
                    HStack {
                        Text("Relative Cost")
                            .font(.subheadline)
                        Spacer()
                        CostLevelView(level: relativeCost)
                    }
                }
                
                if let availability = properties.availability {
                    HStack {
                        Text("Availability")
                            .font(.subheadline)
                        Spacer()
                        AvailabilityLevelView(level: availability)
                    }
                }
            }
        }
    }
}

struct PropertySectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PropertyRowView: View {
    let name: String
    let value: Double
    let unit: String
    let format: String
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            Spacer()
            Text("\(value, specifier: format) \(unit)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
}

struct CostLevelView: View {
    let level: MaterialProperties.CostLevel
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index < costLevel ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var costLevel: Int {
        switch level {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .veryHigh: return 4
        }
    }
}

struct AvailabilityLevelView: View {
    let level: MaterialProperties.AvailabilityLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch level {
        case .common: return .green
        case .moderate: return .orange
        case .limited: return .red
        case .rare: return .purple
        }
    }
}

struct PremiumRequiredView: View {
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Premium Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Upgrade to view detailed material properties and access our complete database.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Upgrade Now") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        MaterialDetailView(material: Material.sampleMaterials[0])
            .environmentObject(MaterialViewModel())
            .environmentObject(PurchaseManager())
    }
}

