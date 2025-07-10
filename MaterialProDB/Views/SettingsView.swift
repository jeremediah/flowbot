import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingPurchaseSheet = false
    
    var body: some View {
        NavigationView {
            List {
                // Premium Status Section
                Section {
                    PremiumStatusView()
                } header: {
                    Text("Subscription")
                }
                
                // Preferences Section
                Section {
                    UnitsPreferenceView()
                } header: {
                    Text("Preferences")
                }
                
                // Statistics Section
                Section {
                    StatisticsView()
                } header: {
                    Text("Statistics")
                }
                
                // About Section
                Section {
                    AboutView()
                } header: {
                    Text("About")
                }
                
                // Debug Section (remove in production)
                #if DEBUG
                Section {
                    DebugView()
                } header: {
                    Text("Debug")
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPurchaseSheet) {
                PremiumPurchaseView()
            }
        }
    }
}

struct PremiumStatusView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingPurchaseSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: purchaseManager.isPremiumUser ? "crown.fill" : "crown")
                    .foregroundColor(purchaseManager.isPremiumUser ? .orange : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(purchaseManager.isPremiumUser ? "Premium Active" : "Free Plan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(purchaseManager.isPremiumUser ? 
                         "Access to all materials and features" : 
                         "Limited to basic materials")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !purchaseManager.isPremiumUser {
                    Button("Upgrade") {
                        showingPurchaseSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            if purchaseManager.isPremiumUser {
                HStack {
                    Button("Restore Purchases") {
                        purchaseManager.restorePurchases()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingPurchaseSheet) {
            PremiumPurchaseView()
        }
    }
}

struct UnitsPreferenceView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "ruler")
                .foregroundColor(.blue)
            
            Text("Units")
                .font(.body)
            
            Spacer()
            
            Picker("Units", selection: $materialViewModel.userPreferences.preferredUnits) {
                ForEach(UserPreferences.UnitSystem.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
        }
        .padding(.vertical, 4)
    }
}

struct StatisticsView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        VStack(spacing: 12) {
            StatRowView(
                icon: "cube.fill",
                title: "Total Materials",
                value: "\(materialViewModel.totalMaterials)"
            )
            
            StatRowView(
                icon: "heart.fill",
                title: "Favorites",
                value: "\(materialViewModel.userPreferences.favoriteMaterials.count)"
            )
            
            StatRowView(
                icon: "scale.3d",
                title: "In Comparison",
                value: "\(materialViewModel.userPreferences.comparisonMaterials.count)"
            )
            
            if purchaseManager.isPremiumUser {
                StatRowView(
                    icon: "crown.fill",
                    title: "Premium Materials",
                    value: "\(materialViewModel.premiumMaterials)"
                )
            }
        }
    }
}

struct StatRowView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("Version")
                    .font(.body)
                
                Spacer()
                
                Text("1.0.0")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.blue)
                
                Text("Support")
                    .font(.body)
                
                Spacer()
                
                Button("Contact") {
                    // Open email or support
                }
                .font(.body)
                .foregroundColor(.blue)
            }
            
            HStack {
                Image(systemName: "star")
                    .foregroundColor(.blue)
                
                Text("Rate App")
                    .font(.body)
                
                Spacer()
                
                Button("Rate") {
                    // Open App Store rating
                }
                .font(.body)
                .foregroundColor(.blue)
            }
        }
    }
}

#if DEBUG
struct DebugView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var materialViewModel: MaterialViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Simulate Premium Purchase") {
                purchaseManager.simulatePurchase()
            }
            .foregroundColor(.green)
            
            Button("Reset Purchases") {
                purchaseManager.resetPurchases()
            }
            .foregroundColor(.red)
            
            Button("Add Sample Favorites") {
                for material in Array(materialViewModel.materials.prefix(3)) {
                    materialViewModel.userPreferences.toggleFavorite(material.id)
                }
            }
            .foregroundColor(.blue)
            
            Button("Clear All Data") {
                purchaseManager.resetPurchases()
                materialViewModel.userPreferences.favoriteMaterials.removeAll()
                materialViewModel.userPreferences.clearComparison()
            }
            .foregroundColor(.red)
        }
    }
}
#endif

struct PremiumPurchaseView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Upgrade to Premium")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Unlock the complete materials database and advanced features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRowView(
                        icon: "database.fill",
                        title: "Complete Database",
                        description: "Access 500+ materials including advanced alloys and composites"
                    )
                    
                    FeatureRowView(
                        icon: "plus.circle.fill",
                        title: "Custom Materials",
                        description: "Add and save your own material properties"
                    )
                    
                    FeatureRowView(
                        icon: "square.and.arrow.up.fill",
                        title: "Export Data",
                        description: "Export material data and comparison reports"
                    )
                    
                    FeatureRowView(
                        icon: "icloud.fill",
                        title: "Cloud Sync",
                        description: "Sync favorites and custom materials across devices"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Purchase Buttons
                VStack(spacing: 12) {
                    Button("Start Free Trial") {
                        // Handle purchase
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text("$5.99/month after 7-day free trial")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Restore Purchases") {
                        purchaseManager.restorePurchases()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MaterialViewModel())
        .environmentObject(PurchaseManager())
}

