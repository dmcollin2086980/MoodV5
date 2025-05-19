import Foundation
import Combine

class CoachViewModel: ObservableObject {
    @Published var currentInsight: CoachingInsight?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let coachService: CoachService
    private var cancellables = Set<AnyCancellable>()
    
    init(coachService: CoachService) {
        self.coachService = coachService
        refreshInsight()
    }
    
    func refreshInsight() {
        isLoading = true
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.currentInsight = self.coachService.generateDailyInsight()
            self.isLoading = false
        }
    }
    
    func handleAction() {
        // Handle the action button tap based on the current insight
        guard let insight = currentInsight else { return }
        
        switch insight.type {
        case .positive:
            // Log the positive reflection
            break
        case .improvement:
            // Show improvement suggestions
            break
        case .neutral:
            // Navigate to mood entry
            break
        }
    }
} 