import Foundation
import Combine

@MainActor
final class ChoreViewModel: ObservableObject {
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var userID: UUID?
    private let service = SupabaseService.shared
    
    var completedCount: Int {
        chores.filter { $0.isCompleted }.count
    }
    
    var progress: Double {
        guard !chores.isEmpty else { return 0}
        return Double(completedCount) / Double(chores.count)
    }
    
    func initialize() async {
        isLoading = true
        defer { isLoading = false}
        
        do {
            userID = try await service.signIn()
            chores = try await service.fetchChores()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refresh() async {
        do {
            chores = try await service.fetchChores()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func addChore(
        title: String,
        roommate: String,
        date: Date
    ) async -> Bool {
        guard let userID else {
            errorMessage = "Not signed in."
            return false
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let newChore = NewChore(
            title: title,
            assignedTo: roommate,
            dueDate: formatter.string(from: date),
            user_id: userID
        )
        
        do {
            try await service.addChore(newChore)
            await refresh()
            return errorMessage == nil
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    func toggleChore(_ chore: Chore) async {
        do {
            try await service.updateChore(
                id: chore.id,
                completed: !chore.isCompleted
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteChore(_ chore: Chore) async {
        do {
            try await service.deleteChore(id: chore.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
