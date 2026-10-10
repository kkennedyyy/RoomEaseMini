/*
Defines the data models used to manage household chores. 
Also maps swift property names to the correct columns
within the Supabase database.
*/
import Foundation

/* Represents a chore retrieved from the daatabase. 
Identifiable allows SwiftUI to distinguish chores using their IDs.
Codable allows chore data to be encoded and decoded as JSON
*/
struct Chore: Identifiable, Codable {
    let id: UUID
    let title: String
    let assignedTo: String
    let dueDate: String
    var isCompleted: Bool
    let user_id: UUID

    // Maps Swift property names to the column names in Supabase
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case user_id
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case isCompleted = "is_completed"
    }
}

// Represents info needed to create a new chore
// Encodable converts the data to a JSON to send to Supabase
struct NewChore: Encodable {
    let title: String
    let assignedTo: String
    let dueDate: String
    let user_id: UUID
    
    enum CodingKeys: String, CodingKey {
        case title
        case user_id
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
    }
}

// Represents info needed to update a chore.
// Only completion status is sent to Supabase
struct ChoreUpdate: Encodable {
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case isCompleted = "is_completed"
    }
}
