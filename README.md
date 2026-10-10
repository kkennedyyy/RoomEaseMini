# RoomEaseMini
RoomEaseMini is an iOS application prototype developed using SwiftUI and Supabase. It demonstrates how household chores can be created, assigned, tracked, and managed through an interactive movile app connected to a cloud database.

## Technologies Used
- **Swift** - Programming language
- **SwiftUI** - User interface
- **Swift Playgrounds** - iOS development on iPad
- **PostgreSQL** - Database
- **REST API** - Communication between the app and Supabase

## Features
- Add chores with a title, assigned roommate, and due date
- View chores stored in database
- Mark chores as complete/incomplete
- Delete chores
- Track household chore completion progress
- Refresh chores to retrieve updated info
- Anonymous user authentication through Supabase

## Project Structure
- `RoomEaseMiniApp.swift` – Application entry point
- `ContentView.swift` – Main dashboard and chore list
- `AddChoreView.swift` – Form for creating chores
- `Chore.swift` – Chore data models
- `ChoreViewModel.swift` – Manages chore data and app logic
- `SupabaseService.swift` – Handles authentication and database requests

## Database and Security
RoomEaseMini uses Supabase PostgreSQL to store chore information
- HTTPS is used for API communication
- Supabase authentication provides user IDs and access tokens
- Row Level Security policies restrict database access when properly configured
- Chores are associated with individual users through a specialized ID
  
## Future Improvements
- Implement email/password authentication
- Improve authentication token storage and session management
- Add household-based RLS policies for shared roommate access
