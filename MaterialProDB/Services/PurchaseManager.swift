import Foundation
import StoreKit

class PurchaseManager: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseError: String?
    
    private let productIDs = ["material_pro_monthly", "material_pro_yearly"]
    
    var isPremiumUser: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        
        // Load purchased products from UserDefaults (for demo purposes)
        if let savedPurchases = UserDefaults.standard.object(forKey: "purchased_products") as? [String] {
            purchasedProductIDs = Set(savedPurchases)
        }
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    @MainActor
    func loadProducts() {
        isLoading = true
        
        Task {
            do {
                let products = try await Product.products(for: productIDs)
                self.products = products
                self.isLoading = false
            } catch {
                print("Failed to load products: \(error)")
                self.isLoading = false
                
                // For demo purposes, create mock products
                self.createMockProducts()
            }
        }
    }
    
    private func createMockProducts() {
        // This is for demo purposes only
        // In a real app, you would only use actual App Store products
        print("Using mock products for demo")
    }
    
    @MainActor
    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Grant premium access
                    await self.handleSuccessfulPurchase(transaction.productID)
                    await transaction.finish()
                case .unverified:
                    purchaseError = "Purchase could not be verified"
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending"
            @unknown default:
                purchaseError = "Unknown purchase result"
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func handleSuccessfulPurchase(_ productID: String) async {
        purchasedProductIDs.insert(productID)
        
        // Save to UserDefaults (for demo purposes)
        UserDefaults.standard.set(Array(purchasedProductIDs), forKey: "purchased_products")
    }
    
    func restorePurchases() {
        Task {
            try? await AppStore.sync()
        }
    }
    
    // Demo function to simulate purchase (remove in production)
    func simulatePurchase() {
        purchasedProductIDs.insert("material_pro_monthly")
        UserDefaults.standard.set(Array(purchasedProductIDs), forKey: "purchased_products")
    }
    
    // Demo function to reset purchases (remove in production)
    func resetPurchases() {
        purchasedProductIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: "purchased_products")
    }
}

// MARK: - SKPaymentTransactionObserver
extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                Task {
                    await handleSuccessfulPurchase(transaction.payment.productIdentifier)
                }
                queue.finishTransaction(transaction)
            case .failed:
                if let error = transaction.error {
                    DispatchQueue.main.async {
                        self.purchaseError = error.localizedDescription
                    }
                }
                queue.finishTransaction(transaction)
            case .restored:
                Task {
                    await handleSuccessfulPurchase(transaction.payment.productIdentifier)
                }
                queue.finishTransaction(transaction)
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}

