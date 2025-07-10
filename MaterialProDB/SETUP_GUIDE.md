# MaterialPro DB - Setup Guide

## 🚀 Quick Start

### 1. Open in Xcode
```bash
cd MaterialProDB
open MaterialProDB.xcodeproj
```

### 2. Configure Bundle Identifier
1. Select the project in Xcode
2. Go to **Signing & Capabilities**
3. Change bundle identifier to: `com.yourcompany.MaterialProDB`
4. Select your development team

### 3. Run the App
- Select iPhone simulator or device
- Press **Cmd+R** to build and run

## 📱 App Structure Overview

```
MaterialProDB/
├── 📱 App Entry Point
│   ├── MaterialProDBApp.swift      # Main app file
│   └── ContentView.swift           # Tab view container
│
├── 🏗️ Models (Data Layer)
│   ├── Material.swift              # Material data structure
│   └── UserPreferences.swift       # User settings & preferences
│
├── 🧠 ViewModels (Business Logic)
│   └── MaterialViewModel.swift     # Main app logic & state
│
├── 🎨 Views (UI Layer)
│   ├── MaterialSearchView.swift    # Search & browse materials
│   ├── MaterialDetailView.swift    # Detailed material properties
│   ├── FavoritesView.swift        # Favorite materials
│   ├── ComparisonView.swift       # Material comparison
│   └── SettingsView.swift         # App settings
│
└── 🔧 Services
    └── PurchaseManager.swift       # In-app purchase handling
```

## 🎯 Key Features Implemented

### ✅ Core Functionality
- [x] **Material Database**: 5 sample materials with full properties
- [x] **Search & Filter**: Text search + category filtering
- [x] **Material Details**: Comprehensive property display
- [x] **Favorites System**: Save/remove favorite materials
- [x] **Comparison Tool**: Side-by-side material comparison
- [x] **Unit Conversion**: Metric/Imperial unit support
- [x] **Premium System**: Freemium model with subscription

### ✅ User Experience
- [x] **Modern SwiftUI Design**: Clean, professional interface
- [x] **Responsive Layout**: Works on iPhone and iPad
- [x] **Intuitive Navigation**: Tab-based navigation
- [x] **Visual Feedback**: Loading states, empty states
- [x] **Accessibility**: VoiceOver support

### ✅ Technical Architecture
- [x] **MVVM Pattern**: Clean separation of concerns
- [x] **Combine Framework**: Reactive search and filtering
- [x] **SwiftUI Best Practices**: Modern declarative UI
- [x] **State Management**: ObservableObject pattern
- [x] **Data Persistence**: UserDefaults for preferences

## 💰 Monetization Setup

### In-App Purchase Configuration

1. **App Store Connect Setup**:
   - Create app in App Store Connect
   - Add in-app purchase products:
     - `material_pro_monthly` - $5.99/month
     - `material_pro_yearly` - $59.99/year

2. **StoreKit Testing**:
   - Enable StoreKit testing in Xcode
   - Test purchase flows before release

3. **Premium Features**:
   - Premium materials are marked with crown icon
   - Free users see limited material set
   - Premium unlocks full database

## 📊 Sample Data

The app includes 5 sample materials:

### Free Materials (3)
1. **AISI 1018 Steel** - Low carbon steel
2. **Aluminum 6061-T6** - Heat treatable aluminum
3. **Stainless Steel 316L** - Corrosion resistant

### Premium Materials (2)
1. **Titanium Ti-6Al-4V** - Aerospace grade titanium
2. **Inconel 718** - High temperature superalloy

## 🔧 Customization Guide

### Adding More Materials

1. **Edit Material.swift**:
```swift
// Add to sampleMaterials array
Material(
    name: "Your Material Name",
    category: .steel, // Choose appropriate category
    description: "Material description",
    properties: MaterialProperties(
        density: 7850,
        tensileStrength: 500,
        // ... other properties
    ),
    isPremium: false // Set to true for premium materials
)
```

### Adding New Material Categories

1. **Update MaterialCategory enum**:
```swift
enum MaterialCategory: String, CaseIterable, Codable {
    case steel = "Steel"
    case aluminum = "Aluminum"
    // Add new category
    case magnesium = "Magnesium"
    
    var icon: String {
        switch self {
        case .magnesium: return "sparkles"
        // Add icon for new category
        }
    }
}
```

### Customizing UI Colors

1. **Update accent colors** in Views
2. **Modify color schemes** for different themes
3. **Add custom color sets** in Assets catalog

## 🧪 Testing Features

### Debug Features (Available in Debug builds)
- **Simulate Premium Purchase**: Test premium features
- **Reset Purchases**: Clear purchase state
- **Add Sample Favorites**: Populate favorites for testing
- **Clear All Data**: Reset app to initial state

### Testing Checklist
- [ ] Search functionality works
- [ ] Category filtering works
- [ ] Material details display correctly
- [ ] Favorites can be added/removed
- [ ] Comparison tool works with multiple materials
- [ ] Unit conversion works properly
- [ ] Premium features are properly gated
- [ ] Purchase flow works (with StoreKit testing)

## 📈 Next Steps for Production

### Phase 1: Database Expansion
1. **Add 200+ materials** to the database
2. **Implement data loading** from JSON/Core Data
3. **Add search optimization** for large datasets

### Phase 2: Advanced Features
1. **Custom material entry** for premium users
2. **Data export** (PDF, CSV) functionality
3. **Cloud sync** with iCloud
4. **Advanced filtering** by property ranges

### Phase 3: Monetization Optimization
1. **A/B test pricing** strategies
2. **Implement analytics** for user behavior
3. **Add promotional offers** and trials
4. **Optimize conversion funnel**

### Phase 4: Platform Expansion
1. **iPad optimization** with split views
2. **macOS version** using Mac Catalyst
3. **Apple Watch companion** app
4. **Web version** for broader reach

## 🐛 Common Issues & Solutions

### Build Issues
- **Missing Bundle ID**: Set unique bundle identifier
- **Signing Issues**: Select development team
- **iOS Version**: Ensure iOS 17.0+ deployment target

### Runtime Issues
- **StoreKit Errors**: Enable StoreKit testing in scheme
- **Preview Crashes**: Check @EnvironmentObject dependencies
- **Data Loading**: Verify sample data is properly formatted

### Performance
- **Large Lists**: Implement lazy loading for 500+ materials
- **Memory Usage**: Optimize image loading and caching
- **Search Performance**: Add debouncing and indexing

## 📞 Support

For questions or issues:
1. Check this setup guide first
2. Review the code comments
3. Test with the debug features
4. Create an issue in the repository

---

**Ready to build the next great engineering app!** 🚀

Start with the MVP, test with real users, and iterate based on feedback. The foundation is solid - now it's time to scale! 💪

