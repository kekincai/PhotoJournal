import SwiftUI

@main
struct PhotoJournalApp: App {
    @StateObject private var photoLibraryManager = PhotoLibraryManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(photoLibraryManager)
        }
    }
}
