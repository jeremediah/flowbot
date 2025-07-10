# MaterialPro DB - Material Properties Database

A comprehensive SwiftUI app for mechanical engineers to search, compare, and analyze material properties.

## Features

### 🔍 **Material Search & Discovery**
- Search through 500+ engineering materials
- Filter by material categories (Steel, Aluminum, Titanium, etc.)
- Quick property preview in search results
- Advanced search with property ranges

### 📊 **Detailed Material Properties**
- **Mechanical Properties**: Density, tensile strength, yield strength, elastic modulus, Poisson's ratio, hardness
- **Thermal Properties**: Thermal conductivity, specific heat, thermal expansion, melting point
- **Electrical Properties**: Electrical resistivity
- **Cost & Availability**: Relative cost and availability indicators

### ⚖️ **Material Comparison**
- Side-by-side comparison of up to 4 materials
- Visual bar charts for property comparison
- Compare by any material property
- Easy material management in comparison view

### ❤️ **Favorites & Organization**
- Save frequently used materials to favorites
- Quick access to favorite materials
- Bulk operations on favorites

### 🔧 **Engineering Units**
- Support for both Metric and Imperial units
- Automatic unit conversion throughout the app
- User preference settings for default units

### 💎 **Premium Features**
- Access to complete database (500+ materials)
- Advanced materials (superalloys, composites, ceramics)
- Custom material entry and management
- Data export capabilities
- Cloud sync across devices

## Technical Architecture

### SwiftUI + MVVM Architecture
```
MaterialProDB/
├── App/
│   └── MaterialProDBApp.swift          # App entry point
├── Views/
│   ├── ContentView.swift               # Main tab view
│   ├── MaterialSearchView.swift        # Search and browse materials
│   ├── MaterialDetailView.swift        # Detailed material properties
│   ├── FavoritesView.swift            # Favorite materials
│   ├── ComparisonView.swift           # Material comparison
│   └── SettingsView.swift             # App settings and preferences
├── ViewModels/
│   └── MaterialViewModel.swift         # Main business logic
├── Models/
│   ├── Material.swift                  # Material data model
│   └── UserPreferences.swift          # User settings and preferences
└── Services/
    └── PurchaseManager.swift           # In-app purchase management
```

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for search and filtering
- **StoreKit**: In-app purchases and subscription management
- **UserDefaults**: Local data persistence
- **MVVM Pattern**: Clean separation of concerns

## Monetization Strategy

### Freemium Model
- **Free Tier**: 50 basic materials, core functionality
- **Premium Subscription**: $5.99/month
  - Complete database (500+ materials)
  - Advanced materials (superalloys, composites)
  - Custom material entry
  - Data export (PDF, CSV)
  - Cloud sync

### Revenue Projections
- **Month 1-3**: $100-300/month (early adopters)
- **Month 4-12**: $500-1200/month (organic growth)
- **Year 2+**: $1000-2500/month (established user base)

## Target Market

### Primary Users
- **Mechanical Engineers**: Material selection for design projects
- **Materials Engineers**: Research and development
- **Engineering Students**: Learning and reference
- **Manufacturing Engineers**: Production material decisions

### Market Size
- 2.5M+ mechanical engineers in US
- Growing engineering education market
- International expansion opportunities

## Development Roadmap

### Phase 1 (MVP) - 4 weeks
- [x] Core material database (50 materials)
- [x] Search and filtering
- [x] Material detail views
- [x] Basic comparison functionality
- [x] Favorites system
- [x] Premium purchase flow

### Phase 2 - 2 weeks
- [ ] Expanded material database (200+ materials)
- [ ] Advanced search filters
- [ ] Data export functionality
- [ ] App Store optimization

### Phase 3 - 3 weeks
- [ ] Custom material entry
- [ ] Cloud sync with iCloud
- [ ] Advanced comparison charts
- [ ] Material property calculators

### Phase 4 - 2 weeks
- [ ] iPad optimization
- [ ] Apple Watch companion
- [ ] Offline mode
- [ ] Advanced analytics

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `MaterialProDB.xcodeproj` in Xcode
3. Build and run on simulator or device

### Configuration
1. Set up App Store Connect for in-app purchases
2. Configure product IDs in `PurchaseManager.swift`
3. Add material data to `Material.swift`
4. Test premium features with StoreKit testing

## Contributing

We welcome contributions! Please see our contributing guidelines for details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@materialpro.app or create an issue in this repository.

---

**MaterialPro DB** - Empowering engineers with comprehensive material data 🔧

