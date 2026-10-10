
import Foundation

struct Chore: Identifiable, Codable {
    let id: UUID
    let title: String
    let assignedTo: String
    let dueDate: String
    var isCompleted: Bool
    let user_id: UUID
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case user_id
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case isCompleted = "is_completed"
    }
}

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

struct ChoreUpdate: Encodable {
    let isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case isCompleted = "is_completed"
    }
}
