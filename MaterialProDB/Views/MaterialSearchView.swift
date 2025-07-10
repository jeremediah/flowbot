import SwiftUI

struct MaterialSearchView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showingCategoryFilter = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Header
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search materials...", text: $materialViewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // All Categories Button
                            CategoryFilterButton(
                                title: "All",
                                icon: "square.grid.2x2",
                                isSelected: materialViewModel.selectedCategory == nil
                            ) {
                                materialViewModel.selectedCategory = nil
                            }
                            
                            // Category Buttons
                            ForEach(Material.MaterialCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: materialViewModel.selectedCategory == category
                                ) {
                                    materialViewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                
                // Materials List
                if materialViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading materials...")
                    Spacer()
                } else {
                    let availableMaterials = materialViewModel.getFilteredMaterials(isPremiumUser: purchaseManager.isPremiumUser)
                    
                    if availableMaterials.isEmpty {
                        EmptyStateView()
                    } else {
                        List(availableMaterials) { material in
                            NavigationLink(destination: MaterialDetailView(material: material)) {
                                MaterialRowView(material: material)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        materialViewModel.clearFilters()
                    }
                    .disabled(materialViewModel.searchText.isEmpty && materialViewModel.selectedCategory == nil)
                }
            }
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct MaterialRowView: View {
    let material: Material
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: material.category.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Material Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(material.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if material.isPremium && !purchaseManager.isPremiumUser {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(material.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(material.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Quick Properties
            VStack(alignment: .trailing, spacing: 2) {
                if let density = material.properties.density {
                    PropertyQuickView(
                        value: materialViewModel.userPreferences.convertDensity(density),
                        unit: materialViewModel.userPreferences.preferredUnits.densityUnit,
                        format: "%.0f"
                    )
                }
                
                if let strength = material.properties.tensileStrength {
                    PropertyQuickView(
                        value: materialViewModel.userPreferences.convertStrength(strength),
                        unit: materialViewModel.userPreferences.preferredUnits.strengthUnit,
                        format: "%.0f"
                    )
                }
            }
            
            // Favorite Button
            Button(action: {
                materialViewModel.userPreferences.toggleFavorite(material.id)
            }) {
                Image(systemName: materialViewModel.userPreferences.isFavorite(material.id) ? "heart.fill" : "heart")
                    .foregroundColor(materialViewModel.userPreferences.isFavorite(material.id) ? .red : .gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .opacity(material.isPremium && !purchaseManager.isPremiumUser ? 0.6 : 1.0)
    }
}

struct PropertyQuickView: View {
    let value: Double
    let unit: String
    let format: String
    
    var body: some View {
        Text("\(value, specifier: format) \(unit)")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No materials found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MaterialSearchView()
        .environmentObject(MaterialViewModel())
        .environmentObject(PurchaseManager())
}

