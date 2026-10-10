import Foundation

enum SupabaseError: LocalizedError {
    case invalidResponse
    case notAuthenticated
    case server(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server returned an invalid response."
        case .notAuthenticated:
            return "You must be signed in."
        case .server(let message):
            return message
        }
    }
}

struct AuthResponse: Decodable {
    let access_token: String
    let user: AuthUser
}

struct AuthUser: Decodable {
    let id: UUID
}

struct SavedSession: Codable {
    let accessToken: String
    let userID: UUID
}

final class SupabaseService {
    static let shared = SupabaseService()
    
    private let baseURL =
    "https://zrotgyjkqjneqwfsdenu.supabase.co"
    
    private let apiKey =
    "sb_publishable_fhgnw4zEKBOTqi4dkZ2bIg_MW_dLp7B"
    
    private let sessionKey = "roomease-demo-session"
    
    private var currentSession: SavedSession?
    
    private init() {}
    
    private func send(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Data {
        
        guard let url = URL(string: baseURL + path)
        else {
            throw SupabaseError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        if authenticated {
            guard let token = currentSession?.accessToken else {
                throw SupabaseError.server("Not signed in.")
            }
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            let message = String(
                data: data,
                encoding: .utf8
            ) ?? "Unknown error"
            
            throw SupabaseError.server(
                "HTTP \(http.statusCode): \(message)"
            )
        }
        
        return data
    }
    
    func signIn() async throws -> UUID {
        if let stored = UserDefaults.standard.data(
            forKey: sessionKey
        ),
           let saved = try? JSONDecoder().decode(
            SavedSession.self,
            from: stored
           ) {
            currentSession = saved
            
            // Confirm the stored access token is still valid.
            do {
                _ = try await fetchChores()
                return saved.userID
            } catch {
                currentSession = nil
            }
        }
        
        let body = Data("{}".utf8)
        
        let data = try await send(
            path: "/auth/v1/signup",
            method: "POST",
            body: body,
            authenticated: false
        )
        
        let result = try JSONDecoder().decode(
            AuthResponse.self,
            from: data
        )
        
        let saved = SavedSession(
            accessToken: result.access_token,
            userID: result.user.id
        )
        
        currentSession = saved
        
        let encoded = try JSONEncoder().encode(saved)
        UserDefaults.standard.set(
            encoded,
            forKey: sessionKey
        )
        
        return result.user.id
    }
    
    func fetchChores() async throws -> [Chore] {
        let data = try await send(
            path: "/rest/v1/chores?select=*&order=created_at.desc"
        )
        
        return try JSONDecoder().decode(
            [Chore].self,
            from: data
        )
    }
    
    func addChore(_ chore: NewChore) async throws {
        let data = try JSONEncoder().encode(chore)
        
        _ = try await send(
            path: "/rest/v1/chores",
            method: "POST",
            body: data
        )
    }
    
    func updateChore(
        id: UUID,
        completed: Bool
    ) async throws {
        let body = try JSONEncoder().encode(
            ChoreUpdate(isCompleted: completed)
        )
        
        _ = try await send(
            path: "/rest/v1/chores?id=eq.\(id.uuidString)",
            method: "PATCH",
            body: body
        )
    }
    
    func deleteChore(id: UUID) async throws {
        _ = try await send(
            path: "/rest/v1/chores?id=eq.\(id.uuidString)",
            method: "DELETE"
        )
    }
}
