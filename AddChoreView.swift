/*
File creates the screen where the user can add a new household chore
The user can: 
    1. Enter a nem for the chore
    2. Enter the roommate responsible for the chore
    3. Choose a due date
    4. Save the chore to the database
    5. Cancel without saving
*/
// Import SwiftUI, iOS framework for building the frontend
import SwiftUI

// Screen for creating and assining a new chore.
struct AddChoreView: View {
    // Connects this screen wo the view model that manages the chores
    @ObservedObject var viewModel: ChoreViewModel
    // Allows the screen to close when saving or canceling
    @Environment(\.dismiss) private var dismiss

    // Stores information entered by the user
    @State private var title = ""
    @State private var roommate = ""
    @State private var dueDate = Date()
    // Tracks if the chore is being saved or not
    @State private var isSaving = false

    // Checks the required text fields contain information
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roommate.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Input fields for the chore's details.
                Section("Chore Details") {
                    TextField("Chore name", text: $title)
                    
                    TextField(
                        "Assigned roommate",
                        text: $roommate
                    )
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }
                // Saves the chore using the view model
                Section {
                    Button {
                        Task {
                            // Display the chore is being saved 
                            isSaving = true
                            // Send the entered information to the view model
                            // Remove extra spaces from text inputs
                            let success = await viewModel.addChore(
                                title: title.trimmingCharacters(
                                    in: .whitespaces
                            ),
                            roommate: roommate.trimmingCharacters(
                                in: .whitespaces
                            ),    
                            date: dueDate
                        )
                        // Stop showing the loading indicator
                        isSaving = false
                            // Closee the screen if chore was saved
                        if success {
                            dismiss()
                        }
                      }
                    } label: {
                        HStack {
                            Spacer()
                            // Display spinner while saving, else display the button text
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Chore")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    // Prevent saving empty chores or duplicate submissions
                    .disabled(!isValid || isSaving)
                }
            }
            .navigationTitle("Add Chore")
            // Adds cancel button to close without saving
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
