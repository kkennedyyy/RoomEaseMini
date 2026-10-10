import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChoreViewModel()
    @State private var showAddChore = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
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
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading chores...")
                    Spacer()
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
                    List {
                        ForEach(viewModel.chores) { chore in
                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await viewModel.toggleChore(chore)
                                    }
                                } label: {
                                    Image(
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
            .sheet(isPresented: $showAddChore) {
                AddChoreView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.refresh()
            }
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
            .task {
                await viewModel.initialize()
            }
        }
    }
}

