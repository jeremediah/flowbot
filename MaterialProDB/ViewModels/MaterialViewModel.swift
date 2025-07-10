import Foundation
import Combine

class MaterialViewModel: ObservableObject {
    @Published var materials: [Material] = []
    @Published var filteredMaterials: [Material] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: Material.MaterialCategory?
    @Published var isLoading: Bool = false
    @Published var userPreferences = UserPreferences()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadMaterials()
        setupSearchAndFilter()
    }
    
    private func setupSearchAndFilter() {
        // Combine search text and category filter
        Publishers.CombineLatest($searchText, $selectedCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, category in
                self?.filterMaterials(searchText: searchText, category: category)
            }
            .store(in: &cancellables)
    }
    
    func loadMaterials() {
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.materials = Material.sampleMaterials
            self.filteredMaterials = self.materials
            self.isLoading = false
        }
    }
    
    private func filterMaterials(searchText: String, category: Material.MaterialCategory?) {
        var filtered = materials
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { material in
                material.name.localizedCaseInsensitiveContains(searchText) ||
                material.description.localizedCaseInsensitiveContains(searchText) ||
                material.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredMaterials = filtered
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }
    
    // Get available materials based on premium status
    func getAvailableMaterials(isPremiumUser: Bool) -> [Material] {
        if isPremiumUser {
            return materials
        } else {
            return materials.filter { !$0.isPremium }
        }
    }
    
    // Get filtered materials based on premium status
    func getFilteredMaterials(isPremiumUser: Bool) -> [Material] {
        if isPremiumUser {
            return filteredMaterials
        } else {
            return filteredMaterials.filter { !$0.isPremium }
        }
    }
    
    // Material statistics
    var totalMaterials: Int {
        materials.count
    }
    
    var freeMaterials: Int {
        materials.filter { !$0.isPremium }.count
    }
    
    var premiumMaterials: Int {
        materials.filter { $0.isPremium }.count
    }
    
    // Category statistics
    func materialsCount(for category: Material.MaterialCategory) -> Int {
        materials.filter { $0.category == category }.count
    }
}

