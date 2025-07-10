import Foundation

class UserPreferences: ObservableObject {
    @Published var preferredUnits: UnitSystem = .metric
    @Published var favoriteMaterials: Set<UUID> = []
    @Published var comparisonMaterials: [Material] = []
    
    enum UnitSystem: String, CaseIterable {
        case metric = "Metric"
        case imperial = "Imperial"
        
        var densityUnit: String {
            switch self {
            case .metric: return "kg/m³"
            case .imperial: return "lb/ft³"
            }
        }
        
        var strengthUnit: String {
            switch self {
            case .metric: return "MPa"
            case .imperial: return "ksi"
            }
        }
        
        var modulusUnit: String {
            switch self {
            case .metric: return "GPa"
            case .imperial: return "Msi"
            }
        }
        
        var thermalConductivityUnit: String {
            switch self {
            case .metric: return "W/m·K"
            case .imperial: return "BTU/hr·ft·°F"
            }
        }
        
        var temperatureUnit: String {
            switch self {
            case .metric: return "°C"
            case .imperial: return "°F"
            }
        }
    }
    
    // Unit conversion functions
    func convertDensity(_ value: Double) -> Double {
        switch preferredUnits {
        case .metric: return value
        case .imperial: return value * 0.062428 // kg/m³ to lb/ft³
        }
    }
    
    func convertStrength(_ value: Double) -> Double {
        switch preferredUnits {
        case .metric: return value
        case .imperial: return value * 0.145038 // MPa to ksi
        }
    }
    
    func convertModulus(_ value: Double) -> Double {
        switch preferredUnits {
        case .metric: return value
        case .imperial: return value * 0.145038 // GPa to Msi
        }
    }
    
    func convertThermalConductivity(_ value: Double) -> Double {
        switch preferredUnits {
        case .metric: return value
        case .imperial: return value * 0.577789 // W/m·K to BTU/hr·ft·°F
        }
    }
    
    func convertTemperature(_ value: Double) -> Double {
        switch preferredUnits {
        case .metric: return value
        case .imperial: return value * 9/5 + 32 // °C to °F
        }
    }
    
    // Favorites management
    func toggleFavorite(_ materialId: UUID) {
        if favoriteMaterials.contains(materialId) {
            favoriteMaterials.remove(materialId)
        } else {
            favoriteMaterials.insert(materialId)
        }
    }
    
    func isFavorite(_ materialId: UUID) -> Bool {
        favoriteMaterials.contains(materialId)
    }
    
    // Comparison management
    func addToComparison(_ material: Material) {
        if !comparisonMaterials.contains(where: { $0.id == material.id }) && comparisonMaterials.count < 4 {
            comparisonMaterials.append(material)
        }
    }
    
    func removeFromComparison(_ material: Material) {
        comparisonMaterials.removeAll { $0.id == material.id }
    }
    
    func clearComparison() {
        comparisonMaterials.removeAll()
    }
}

