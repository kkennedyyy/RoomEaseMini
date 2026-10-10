import SwiftUI

struct AddChoreView: View {
    @ObservedObject var viewModel: ChoreViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var roommate = ""
    @State private var dueDate = Date()
    @State private var isSaving = false
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !roommate.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
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
                Section {
                    Button {
                        Task {
                            isSaving = true
                            
                            let success = await viewModel.addChore(
                                title: title.trimmingCharacters(
                                    in: .whitespaces
                            ),
                            roommate: roommate.trimmingCharacters(
                                in: .whitespaces
                            ),    
                            date: dueDate
                        )
                        
                        isSaving = false
                            
                        if success {
                            dismiss()
                        }
                      }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save Chore")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .navigationTitle("Add Chore")
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
