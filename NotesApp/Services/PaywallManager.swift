import Foundation
import SwiftUI
import StoreKit

/// PaywallManager for handling premium features and subscriptions
/// Note: This is a mock implementation. In production, integrate with RevenueCat
@MainActor
final class PaywallManager: ObservableObject {
    @Published var isPremiumUser = false
    @Published var showingPaywall = false
    @Published var availableProducts: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    
    enum PurchaseState {
        case idle
        case purchasing
        case success
        case failed(Error)
    }
    
    enum PremiumFeature: String, CaseIterable {
        case collaboration = "collaboration"
        case advancedTemplates = "advanced_templates"
        case unlimitedNotes = "unlimited_notes"
        case cloudStorage = "cloud_storage"
        case handwritingRecognition = "handwriting_recognition"
        case exportOptions = "export_options"
        
        var displayName: String {
            switch self {
            case .collaboration:
                return "Real-time Collaboration"
            case .advancedTemplates:
                return "Advanced Templates"
            case .unlimitedNotes:
                return "Unlimited Notes"
            case .cloudStorage:
                return "Enhanced Cloud Storage"
            case .handwritingRecognition:
                return "Handwriting Recognition"
            case .exportOptions:
                return "Export Options"
            }
        }
        
        var description: String {
            switch self {
            case .collaboration:
                return "Share and edit notes with others in real-time"
            case .advancedTemplates:
                return "Access to premium note templates"
            case .unlimitedNotes:
                return "Create unlimited notes and folders"
            case .cloudStorage:
                return "Unlimited iCloud storage for your notes"
            case .handwritingRecognition:
                return "Convert handwriting to searchable text"
            case .exportOptions:
                return "Export notes to PDF, Word, and more"
            }
        }
        
        var systemImage: String {
            switch self {
            case .collaboration:
                return "person.2.fill"
            case .advancedTemplates:
                return "doc.richtext.fill"
            case .unlimitedNotes:
                return "infinity"
            case .cloudStorage:
                return "icloud.fill"
            case .handwritingRecognition:
                return "pencil.tip"
            case .exportOptions:
                return "square.and.arrow.up.fill"
            }
        }
    }
    
    private let freeNotesLimit = 10
    private let freeTemplatesLimit = 3
    
    init() {
        loadPremiumStatus()
        loadProducts()
    }
    
    /// Check if user has access to a premium feature
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isPremiumUser
    }
    
    /// Check if user can create more notes (free tier limit)
    func canCreateNote(currentCount: Int) -> Bool {
        return isPremiumUser || currentCount < freeNotesLimit
    }
    
    /// Check if user can use advanced templates
    func canUseAdvancedTemplates() -> Bool {
        return isPremiumUser
    }
    
    /// Show paywall for specific feature
    func showPaywall(for feature: PremiumFeature) {
        showingPaywall = true
    }
    
    /// Load available products from App Store
    private func loadProducts() {
        Task {
            do {
                // In production, replace with actual product IDs
                let productIDs = [
                    "com.notesapp.premium.monthly",
                    "com.notesapp.premium.yearly"
                ]
                
                // Mock products for demonstration
                // In production, use: Product.products(for: productIDs)
                await MainActor.run {
                    self.availableProducts = [] // Would contain actual products
                }
            } catch {
                print("Failed to load products: \(error)")
            }
        }
    }
    
    /// Purchase premium subscription
    func purchasePremium() async {
        guard !availableProducts.isEmpty else { return }
        
        purchaseState = .purchasing
        
        do {
            // Mock purchase process
            // In production, implement actual StoreKit purchase
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                self.isPremiumUser = true
                self.purchaseState = .success
                self.showingPaywall = false
                self.savePremiumStatus()
            }
        } catch {
            await MainActor.run {
                self.purchaseState = .failed(error)
            }
        }
    }
    
    /// Restore previous purchases
    func restorePurchases() async {
        purchaseState = .purchasing
        
        do {
            // Mock restore process
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                // In production, check actual purchase history
                self.isPremiumUser = true
                self.purchaseState = .success
                self.savePremiumStatus()
            }
        } catch {
            await MainActor.run {
                self.purchaseState = .failed(error)
            }
        }
    }
    
    /// Load premium status from UserDefaults
    private func loadPremiumStatus() {
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    /// Save premium status to UserDefaults
    private func savePremiumStatus() {
        UserDefaults.standard.set(isPremiumUser, forKey: "isPremiumUser")
    }
}

/// Paywall view for premium features
struct PaywallView: View {
    @ObservedObject var paywallManager: PaywallManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.yellow)
                            .symbolEffect(.bounce)
                        
                        Text("Unlock Premium Features")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Take your note-taking to the next level")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Features list
                    VStack(spacing: 16) {
                        ForEach(PaywallManager.PremiumFeature.allCases, id: \.rawValue) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            PricingCard(
                                title: "Monthly",
                                price: "$4.99",
                                period: "per month",
                                isRecommended: false
                            )
                            
                            PricingCard(
                                title: "Yearly",
                                price: "$39.99",
                                period: "per year",
                                savings: "Save 33%",
                                isRecommended: true
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase button
                    VStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await paywallManager.purchasePremium()
                            }
                        }) {
                            HStack {
                                if case .purchasing = paywallManager.purchaseState {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Text("Start Premium")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(paywallManager.purchaseState == .purchasing)
                        
                        Button("Restore Purchases") {
                            Task {
                                await paywallManager.restorePurchases()
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Terms and privacy
                    VStack(spacing: 8) {
                        Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // Open terms
                            }
                            .font(.caption)
                            
                            Button("Privacy Policy") {
                                // Open privacy policy
                            }
                            .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
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
        .alert("Purchase Error", isPresented: .constant(
            if case .failed = paywallManager.purchaseState { true } else { false }
        )) {
            Button("OK") {
                paywallManager.purchaseState = .idle
            }
        } message: {
            if case .failed(let error) = paywallManager.purchaseState {
                Text(error.localizedDescription)
            }
        }
    }
}

/// Individual feature row in paywall
struct FeatureRow: View {
    let feature: PaywallManager.PremiumFeature
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Pricing card component
struct PricingCard: View {
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isRecommended: Bool
    
    init(title: String, price: String, period: String, savings: String? = nil, isRecommended: Bool = false) {
        self.title = title
        self.price = price
        self.period = period
        self.savings = savings
        self.isRecommended = isRecommended
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if isRecommended {
                Text("RECOMMENDED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(price)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(period)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let savings = savings {
                Text(savings)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRecommended ? Color.accentColor : Color(.systemGray4), lineWidth: isRecommended ? 2 : 1)
        )
    }
}

#Preview {
    PaywallView(paywallManager: PaywallManager())
}

