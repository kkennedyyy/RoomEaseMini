/*
Defines the main dashboard for the application.
Displays chore progress, assigned chores, and due dates.
Also allows the user to add, complete, and delete chores while
retrieving and updating data throught ChoreViewModel.
*/

import SwiftUI

// Main screen displaying chores and progress.
struct ContentView: View {
    // Creates and manages the view model for chore data
    @StateObject private var viewModel = ChoreViewModel()
    
    // Controls whether the Add Chore screen is displayed
    @State private var showAddChore = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Displays the number of completed chores
                // and a progress bar showing overall completion
                VStack(alignment: .leading, spacing: 10) {
                    Text("Household Progress")
                        .font(.headline)
                    
                    Text(
                        "\(viewModel.completedCount) of \(viewModel.chores.count) chores completed"
                    )
                    .foregroundStyle(.secondary)
                    
                    ProgressView(value: viewModel.progress)
                        .tint(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.purple.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .padding(.horizontal)

                // Displays a loading indicator while retrieving chores
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading chores...")
                    Spacer()
                // Displays a message if no chores
                } else if viewModel.chores.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Chores Yet",
                        systemImage: "checklist",
                        description: Text(
                            "Tap + to add your first household chore."
                        )
                    )
                    Spacer()
                } else {
                    // Displays all chores from Supabase
                    List {
                        ForEach(viewModel.chores) { chore in
                            HStack(spacing: 12) {
                                Button {
                                    // Toggles a chore between completed or incomplete
                                    Task {
                                        await viewModel.toggleChore(chore)
                                    }
                                } label: {
                                    Image(
                                        // Displays a filled green checkmark for completed chores
                                        // and purple for incomplete
                                        systemName: chore.isCompleted
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                    )
                                    .font(.title2)
                                    .foregroundStyle(
                                        chore.isCompleted
                                        ? .green : .purple
                                    )
                                }
                                .buttonStyle(.plain)
                                // Displays the chore's title,
                                // assigned roommate, and due date
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(chore.title)
                                        .font(.headline)
                                        .strikethrough(chore.isCompleted)
                                    
                                    Text(
                                        "Assigned to: \(chore.assignedTo)"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    
                                    Text("Due: \(chore.dueDate)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()

                                // Deletes the selected chore from Supabase
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteChore(chore)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("RoomEase Mini")
            // Adds a + button to open the Add Chore screen
            // The button is disabled while chores are loading
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddChore = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            // Presents AddChoreView as a sheet when the + button is tapped
            .sheet(isPresented: $showAddChore) {
                AddChoreView(viewModel: viewModel)
            }
            // Allows the users to pull down on the list to get chores from Supabase
            .refreshable {
                await viewModel.refresh()
            }
            // Alerts when error occurs during a database or authentication operation
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Signs in the user and loads their chores when main screen first appears
            .task {
                await viewModel.initialize()
            }
        }
    }
}

