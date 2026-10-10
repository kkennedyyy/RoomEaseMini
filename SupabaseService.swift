/*
Communication between the app and database. Manages anonymous user authentication, session storage,
HTTP requests, and database operation for creating, retrieving, updating, 
and deleting household chores
*/
/* Security Overview Learned:
    - Uses HTTPS to encrypt communcation with Supabase
    - Uses a publishable API key to identify the Supabase database/project
    - Uses authentication tokens to authorize database requests
    - Relies on Supabase RLS to resrict data access
    - Stores authentication sessions locally for reuse
*/ 
/* TODO/Implement for RoomEaseApp for Security Improvements:
    - Impelment email/password authentication for individual accounts
    - Use secure token storage and automatic session refresh
    - Add household-based authorization for shared roommate data
    - Improve error handling to avoid exposing internal server details
*/ 
import Foundation

// Defines errors that may occur during authentication or communcation
// with the Supabase API
enum SupabaseError: LocalizedError {
    case invalidResponse
    case notAuthenticated
    case server(String)

    // Provides readable error messages for the user.
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

// Represents the authentication reponse returned by Supabase
// Contains the access token and authenticated user's information.
struct AuthResponse: Decodable {
    let access_token: String
    let user: AuthUser
}

// Stores the unique identifier assigned to the authenticated user
struct AuthUser: Decodable {
    let id: UUID
}

// Stores session information so user doesnt need to create a new anon account
// on every app launch
/* SECURITY IMPROVEMENTS for RoomEaseApp:
Use keychain or Supabase supported authentication for session management, instead of user
defaults (obviously) 
*/
struct SavedSession: Codable {
    let accessToken: String
    let userID: UUID
}

// Provides a shared service for authentication and database access.
final class SupabaseService {
    // Singleton instance used throughout the app
    static let shared = SupabaseService()

    // SECURITY: Never publish secure database information (obvisouly)
    // HTTPS encrypts data transmitted between the app and Supbase
    private let baseURL =
    "SUPABASE_BASE_URL"

    // API key identifies Supabase prokect
    private let apiKey =
    "SUPABASE_PUBLISHABLE_KEY"

    // Identifier to store session on device
    private let sessionKey = "roomease-demo-session"

    // Stores active user's authentication information
    private var currentSession: SavedSession?

    // Prevents additional instances of this service
    private init() {}

    // Sends HTTP requests to SupaBase.
    // Adds authentication headers, handles reponses, and reports unseuccessful requests
    private func send(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws -> Data {

        // Constructs requested Supabase API endpoint
        guard let url = URL(string: baseURL + path)
        else {
            throw SupabaseError.invalidResponse
        }

        // Configures the request method and JSON headers
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
         /* Adds the user's access token to authenticated requests.
            SECURITY: Supabase uses the token to identify the current user.
            RLS policies must verify which database rows the authenticated 
            user is allowed to access.
        */
        if authenticated {
            guard let token = currentSession?.accessToken else {
                throw SupabaseError.server("Not signed in.")
            }
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        // Attatches request data for operations such as creating/updating chores
        request.httpBody = body

        // Sends request securely over HTTPS
        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        // Confirms that the server returned an HTTP response
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        // Checks whether Supabase accepted the request.
        /* SECURITY:
            Prod apps should display safer messages without exposing backend info.
        */
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

    // Authenticates the user using an existing session or creates a new anon Supabase account
    func signIn() async throws -> UUID {
        // Attempts to retrieve a previously saved session
        if let stored = UserDefaults.standard.data(
            forKey: sessionKey
        ),
           let saved = try? JSONDecoder().decode(
            SavedSession.self,
            from: stored
           ) {
            currentSession = saved
            
            // Tests the stored token by requesting chores.
               /* SECURITY: Validate or refresh session through Supabase Auth instead 
               of using fetchChores b/c a failed database request doesn't always mean
               the access token is expired.
               */
            do {
                _ = try await fetchChores()
                return saved.userID
            } catch {
                currentSession = nil
            }
        }
        // Creates empty JSON body for anon signup
        let body = Data("{}".utf8)

        /*
        SECURITY: Anon authentication assigns a unique user ID, however doesnt verify
        a person's real world identity (problem especially with rise of AI and deep fakes)

        TODO:
        Replace anon signup with individual user accounts for actual implementation
        (obviously)
        */
        let data = try await send(
            path: "/auth/v1/signup",
            method: "POST",
            body: body,
            authenticated: false
        )
        // Decodes auth token and user info
        let result = try JSONDecoder().decode(
            AuthResponse.self,
            from: data
        )
        // Create a session containing token and user ID
        let saved = SavedSession(
            accessToken: result.access_token,
            userID: result.user.id
        )
        
        currentSession = saved

        /* Saves the session for future application launches
            TODO: Move token storage to keychain and support
            access-token expiration and refresh
        */
        let encoded = try JSONEncoder().encode(saved)
        UserDefaults.standard.set(
            encoded,
            forKey: sessionKey
        )
        
        return result.user.id
    }
    /* Retrieves chores from the Supabase database, sorted by creation date from newest to oldest
    SECURITY: The database SELECT RLS policy should restrict returned 
    rows to those owned by the auth user
    */
    func fetchChores() async throws -> [Chore] {
        let data = try await send(
            path: "/rest/v1/chores?select=*&order=created_at.desc"
        )

        // Converts the JSON response into Chore objects
        return try JSONDecoder().decode(
            [Chore].self,
            from: data
        )
    }
    /* Creates a new chore in the Supabase database.
    SECURITY: The INSERT RLS policy should verify that the chore's 
    user id matches the authenticated user's ID. Prevents users from assigning database 
    ownership to another account without auth
    */
    func addChore(_ chore: NewChore) async throws {
        let data = try JSONEncoder().encode(chore)
        
        _ = try await send(
            path: "/rest/v1/chores",
            method: "POST",
            body: data
        )
    }
     /* Updates an existing chore's completion status.
        SECURITY: The UPDATE RLS policy should prevent users from modifying chores belonging to others
    */
    func updateChore(
        id: UUID,
        completed: Bool
    ) async throws {
        // converst the new completion status into JSON
        let body = try JSONEncoder().encode(
            ChoreUpdate(isCompleted: completed)
        )
            // updates the chores matching the specific ID
        _ = try await send(
            path: "/rest/v1/chores?id=eq.\(id.uuidString)",
            method: "PATCH",
            body: body
        )
    }
    /*
    Deletes a chore from database
    SECURITY: DELETE RLS policy should only allow auth user that owns the chore to delete
    */
    func deleteChore(id: UUID) async throws {
        // DELETE removes the record matching the provided ID
        _ = try await send(
            path: "/rest/v1/chores?id=eq.\(id.uuidString)",
            method: "DELETE"
        )
    }
}
