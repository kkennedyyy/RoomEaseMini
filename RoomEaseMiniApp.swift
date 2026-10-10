/*
Main entry point for the application. Initializes the SwiftUI app and launches 
ContentView as the main screen when the app starts.
*/
import SwiftUI

// @Main identifies the structure as the app's entry/opening point
@main
struct RoomEaseMiniApp: App {
    // Defines the windows/screens showed by the app
    var body: some Scene {
        // Creates the main app window
        WindowGroup {
            // Shows the main dashboard when app launches
            ContentView()
        }
    }
}
