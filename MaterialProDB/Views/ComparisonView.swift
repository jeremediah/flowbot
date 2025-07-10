import SwiftUI

struct ComparisonView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedProperty: ComparisonProperty = .density
    
    enum ComparisonProperty: String, CaseIterable {
        case density = "Density"
        case tensileStrength = "Tensile Strength"
        case yieldStrength = "Yield Strength"
        case elasticModulus = "Elastic Modulus"
        case thermalConductivity = "Thermal Conductivity"
        case meltingPoint = "Melting Point"
        
        var unit: String {
            switch self {
            case .density: return "kg/m³"
            case .tensileStrength, .yieldStrength: return "MPa"
            case .elasticModulus: return "GPa"
            case .thermalConductivity: return "W/m·K"
            case .meltingPoint: return "°C"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if materialViewModel.userPreferences.comparisonMaterials.isEmpty {
                    EmptyComparisonView()
                } else {
                    VStack(spacing: 16) {
                        // Property Selector
                        PropertySelectorView(selectedProperty: $selectedProperty)
                        
                        // Comparison Chart
                        ComparisonChartView(
                            materials: materialViewModel.userPreferences.comparisonMaterials,
                            property: selectedProperty
                        )
                        
                        // Materials List
                        ComparisonListView()
                    }
                    .padding()
                }
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !materialViewModel.userPreferences.comparisonMaterials.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            materialViewModel.userPreferences.clearComparison()
                        }
                    }
                }
            }
        }
    }
}

struct PropertySelectorView: View {
    @Binding var selectedProperty: ComparisonView.ComparisonProperty
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compare by:")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ComparisonView.ComparisonProperty.allCases, id: \.self) { property in
                        Button(action: {
                            selectedProperty = property
                        }) {
                            Text(property.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedProperty == property ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedProperty == property ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ComparisonChartView: View {
    let materials: [Material]
    let property: ComparisonView.ComparisonProperty
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Comparison")
                .font(.headline)
                .foregroundColor(.primary)
            
            let values = materials.compactMap { material -> (String, Double)? in
                guard let value = getPropertyValue(for: material, property: property) else { return nil }
                return (material.name, value)
            }
            
            if values.isEmpty {
                Text("No data available for this property")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                        ComparisonBarView(
                            name: item.0,
                            value: item.1,
                            maxValue: values.map(\.1).max() ?? 1,
                            unit: getUnitForProperty(property),
                            color: getColorForIndex(index)
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private func getPropertyValue(for material: Material, property: ComparisonView.ComparisonProperty) -> Double? {
        let preferences = materialViewModel.userPreferences
        
        switch property {
        case .density:
            return material.properties.density.map { preferences.convertDensity($0) }
        case .tensileStrength:
            return material.properties.tensileStrength.map { preferences.convertStrength($0) }
        case .yieldStrength:
            return material.properties.yieldStrength.map { preferences.convertStrength($0) }
        case .elasticModulus:
            return material.properties.elasticModulus.map { preferences.convertModulus($0) }
        case .thermalConductivity:
            return material.properties.thermalConductivity.map { preferences.convertThermalConductivity($0) }
        case .meltingPoint:
            return material.properties.meltingPoint.map { preferences.convertTemperature($0) }
        }
    }
    
    private func getUnitForProperty(_ property: ComparisonView.ComparisonProperty) -> String {
        let preferences = materialViewModel.userPreferences
        
        switch property {
        case .density: return preferences.preferredUnits.densityUnit
        case .tensileStrength, .yieldStrength: return preferences.preferredUnits.strengthUnit
        case .elasticModulus: return preferences.preferredUnits.modulusUnit
        case .thermalConductivity: return preferences.preferredUnits.thermalConductivityUnit
        case .meltingPoint: return preferences.preferredUnits.temperatureUnit
        }
    }
    
    private func getColorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple]
        return colors[index % colors.count]
    }
}

struct ComparisonBarView: View {
    let name: String
    let value: Double
    let maxValue: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (value / maxValue), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ComparisonListView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Materials in Comparison")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(materialViewModel.userPreferences.comparisonMaterials) { material in
                    ComparisonMaterialRowView(material: material)
                }
            }
        }
    }
}

struct ComparisonMaterialRowView: View {
    let material: Material
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: material.category.icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(material.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                materialViewModel.userPreferences.removeFromComparison(material)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyComparisonView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "scale.3d")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Materials to Compare")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add materials to comparison from the search or detail views to see side-by-side property comparisons.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: MaterialSearchView()) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Materials")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    ComparisonView()
        .environmentObject(MaterialViewModel())
        .environmentObject(PurchaseManager())
}

