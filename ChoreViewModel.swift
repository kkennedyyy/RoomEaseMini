/*
Contains the logic and data for household chores. Connects SwiftUI to Supabase to 
retrieve, create, update, and delete chores. Also tracks loading states,
errors, and chore completion progress
*/

import Foundation
import Combine

// Manages chore data and updates the frontend
// @MainActor makes sure UI-related changes occur on the main actor
@MainActor
final class ChoreViewModel: ObservableObject {
    // @Published notifies frontend when these values change
    @Published var chores: [Chore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Stores the authenticated user's ID and provides 
    // access to the shared Supabase service.
    private var userID: UUID?
    private let service = SupabaseService.shared

    // Calculates number of completed chores
    var completedCount: Int {
        chores.filter { $0.isCompleted }.count
    }

    // Calculates percentage of chores completed as a decimal
    // between 0 and 1
    var progress: Double {
        guard !chores.isEmpty else { return 0}
        return Double(completedCount) / Double(chores.count)
    }

    // Intializes the app by signing in the user and 
    // retrieving their chores from Supabase
    func initialize() async {
        isLoading = true
        // Verifies loading stops when the function finishes
        defer { isLoading = false}
        
        do {
            userID = try await service.signIn()
            chores = try await service.fetchChores()
            errorMessage = nil
        } catch {
            // Displays an error if aunthentication or loading fails
            errorMessage = error.localizedDescription
        }
    }

    // Retrieves the latest chores from Supabase
    // Used to keep the displayed chore list up to date
    func refresh() async {
        do {
            chores = try await service.fetchChores()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    // Creates a new chore using the information entered
    // in AddChoreView and saves it to Supabase.
    // Returns true if the chore was saved successfully.
    func addChore(
        title: String,
        roommate: String,
        date: Date
    ) async -> Bool {
        // Prevents creating a chore if user isnt signed in.
        guard let userID else {
            errorMessage = "Not signed in."
            return false
        }

        // Converts selected data into the right format for the database
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Creates a NewChore object 
        let newChore = NewChore(
            title: title,
            assignedTo: roommate,
            dueDate: formatter.string(from: date),
            user_id: userID
        )
        
        do {
            // Saves chore to Supabase
            try await service.addChore(newChore)
            // Reloads the list to display new chore
            await refresh()
            // Returns true if no error occured
            return errorMessage == nil
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    // Changes a chore's completion status
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

    // Deletes the selected chore from Supabase
    // and refreshes displayed chore list
    func deleteChore(_ chore: Chore) async {
        do {
            try await service.deleteChore(id: chore.id)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
