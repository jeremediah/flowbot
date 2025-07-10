import SwiftUI

@main
struct MaterialProDBApp: App {
    @StateObject private var materialViewModel = MaterialViewModel()
    @StateObject private var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(materialViewModel)
                .environmentObject(purchaseManager)
                .onAppear {
                    purchaseManager.loadProducts()
                }
        }
    }
}

