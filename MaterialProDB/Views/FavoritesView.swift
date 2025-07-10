import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    
    var favoriteMaterials: [Material] {
        materialViewModel.materials.filter { material in
            materialViewModel.userPreferences.isFavorite(material.id)
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if favoriteMaterials.isEmpty {
                    EmptyFavoritesView()
                } else {
                    List(favoriteMaterials) { material in
                        NavigationLink(destination: MaterialDetailView(material: material)) {
                            MaterialRowView(material: material)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favoriteMaterials.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Clear All Favorites") {
                                clearAllFavorites()
                            }
                            
                            Button("Add All to Comparison") {
                                addAllToComparison()
                            }
                            .disabled(favoriteMaterials.count > 4)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    private func clearAllFavorites() {
        for material in favoriteMaterials {
            materialViewModel.userPreferences.toggleFavorite(material.id)
        }
    }
    
    private func addAllToComparison() {
        materialViewModel.userPreferences.clearComparison()
        for material in Array(favoriteMaterials.prefix(4)) {
            materialViewModel.userPreferences.addToComparison(material)
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap the heart icon on any material to add it to your favorites for quick access.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: MaterialSearchView()) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Browse Materials")
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
    FavoritesView()
        .environmentObject(MaterialViewModel())
        .environmentObject(PurchaseManager())
}

