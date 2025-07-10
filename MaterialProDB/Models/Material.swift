import Foundation

struct Material: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let category: MaterialCategory
    let description: String
    let properties: MaterialProperties
    let isPremium: Bool
    
    enum MaterialCategory: String, CaseIterable, Codable {
        case steel = "Steel"
        case aluminum = "Aluminum"
        case titanium = "Titanium"
        case copper = "Copper"
        case plastic = "Plastic"
        case composite = "Composite"
        case ceramic = "Ceramic"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .steel: return "hammer.fill"
            case .aluminum: return "cube.fill"
            case .titanium: return "diamond.fill"
            case .copper: return "bolt.fill"
            case .plastic: return "drop.fill"
            case .composite: return "layers.fill"
            case .ceramic: return "circle.fill"
            case .other: return "questionmark.circle.fill"
            }
        }
    }
}

struct MaterialProperties: Codable, Hashable {
    // Mechanical Properties
    let density: Double? // kg/m³
    let tensileStrength: Double? // MPa
    let yieldStrength: Double? // MPa
    let elasticModulus: Double? // GPa
    let poissonRatio: Double?
    let hardness: Double? // HB, HRC, etc.
    
    // Thermal Properties
    let thermalConductivity: Double? // W/m·K
    let specificHeat: Double? // J/kg·K
    let thermalExpansion: Double? // 1/K
    let meltingPoint: Double? // °C
    
    // Electrical Properties
    let electricalResistivity: Double? // Ω·m
    
    // Cost and Availability
    let relativeCost: CostLevel?
    let availability: AvailabilityLevel?
    
    enum CostLevel: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case veryHigh = "Very High"
    }
    
    enum AvailabilityLevel: String, Codable, CaseIterable {
        case common = "Common"
        case moderate = "Moderate"
        case limited = "Limited"
        case rare = "Rare"
    }
}

// MARK: - Sample Data
extension Material {
    static let sampleMaterials: [Material] = [
        // Free Materials
        Material(
            name: "AISI 1018 Steel",
            category: .steel,
            description: "Low carbon steel, good machinability and weldability",
            properties: MaterialProperties(
                density: 7870,
                tensileStrength: 440,
                yieldStrength: 370,
                elasticModulus: 200,
                poissonRatio: 0.29,
                hardness: 126,
                thermalConductivity: 51.9,
                specificHeat: 486,
                thermalExpansion: 11.7e-6,
                meltingPoint: 1515,
                electricalResistivity: 1.7e-7,
                relativeCost: .low,
                availability: .common
            ),
            isPremium: false
        ),
        
        Material(
            name: "Aluminum 6061-T6",
            category: .aluminum,
            description: "Heat treatable aluminum alloy with good strength and corrosion resistance",
            properties: MaterialProperties(
                density: 2700,
                tensileStrength: 310,
                yieldStrength: 276,
                elasticModulus: 68.9,
                poissonRatio: 0.33,
                hardness: 95,
                thermalConductivity: 167,
                specificHeat: 896,
                thermalExpansion: 23.6e-6,
                meltingPoint: 582,
                electricalResistivity: 4.0e-8,
                relativeCost: .medium,
                availability: .common
            ),
            isPremium: false
        ),
        
        Material(
            name: "Stainless Steel 316L",
            category: .steel,
            description: "Austenitic stainless steel with excellent corrosion resistance",
            properties: MaterialProperties(
                density: 8000,
                tensileStrength: 580,
                yieldStrength: 290,
                elasticModulus: 200,
                poissonRatio: 0.30,
                hardness: 217,
                thermalConductivity: 16.3,
                specificHeat: 500,
                thermalExpansion: 16.0e-6,
                meltingPoint: 1375,
                electricalResistivity: 7.4e-7,
                relativeCost: .high,
                availability: .common
            ),
            isPremium: false
        ),
        
        // Premium Materials
        Material(
            name: "Titanium Ti-6Al-4V",
            category: .titanium,
            description: "Alpha-beta titanium alloy with excellent strength-to-weight ratio",
            properties: MaterialProperties(
                density: 4430,
                tensileStrength: 950,
                yieldStrength: 880,
                elasticModulus: 113.8,
                poissonRatio: 0.342,
                hardness: 334,
                thermalConductivity: 6.7,
                specificHeat: 563,
                thermalExpansion: 8.6e-6,
                meltingPoint: 1604,
                electricalResistivity: 1.7e-6,
                relativeCost: .veryHigh,
                availability: .moderate
            ),
            isPremium: true
        ),
        
        Material(
            name: "Inconel 718",
            category: .other,
            description: "Nickel-chromium superalloy for high temperature applications",
            properties: MaterialProperties(
                density: 8220,
                tensileStrength: 1275,
                yieldStrength: 1034,
                elasticModulus: 200,
                poissonRatio: 0.294,
                hardness: 331,
                thermalConductivity: 11.4,
                specificHeat: 435,
                thermalExpansion: 13.0e-6,
                meltingPoint: 1336,
                electricalResistivity: 1.25e-6,
                relativeCost: .veryHigh,
                availability: .limited
            ),
            isPremium: true
        )
    ]
}

