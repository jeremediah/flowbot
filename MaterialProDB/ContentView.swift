import SwiftUI

struct ContentView: View {
    @EnvironmentObject var materialViewModel: MaterialViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MaterialSearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(0)
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
                .tag(1)
            
            ComparisonView()
                .tabItem {
                    Image(systemName: "scale.3d")
                    Text("Compare")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

