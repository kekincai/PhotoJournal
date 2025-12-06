import Foundation
import Photos
import UIKit

class PhotoLibraryManager: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var isAuthorized = false

    private let journalKey = "PhotoJournalEntries"

    func checkAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
            self.fetchPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.isAuthorized = true
                        self.fetchPhotos()
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.isAuthorized = false
            }
        }
    }

    func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var newEntries: [JournalEntry] = []
        let savedJournals = loadJournals()

        fetchResult.enumerateObjects { asset, _, _ in
            var entry = JournalEntry(asset: asset)
            if let savedText = savedJournals[asset.localIdentifier] {
                entry.text = savedText
            }
            newEntries.append(entry)
        }

        DispatchQueue.main.async {
            self.journalEntries = newEntries
        }
    }

    // MARK: - Local Storage

    private func loadJournals() -> [String: String] {
        if let data = UserDefaults.standard.data(forKey: journalKey),
            let journals = try? JSONDecoder().decode([String: String].self, from: data)
        {
            return journals
        }
        return [:]
    }

    private func saveJournals(_ journals: [String: String]) {
        if let data = try? JSONEncoder().encode(journals) {
            UserDefaults.standard.set(data, forKey: journalKey)
        }
    }

    // MARK: - Save Caption (Local Storage Only)
    // Note: iOS Photos app stores captions in Apple's internal database.
    // There is NO public API for third-party apps to write to it.
    // Journals are saved locally in this app.

    func saveCaption(
        for asset: PHAsset, caption: String, completion: @escaping (Bool, Error?) -> Void
    ) {
        var journals = loadJournals()
        journals[asset.localIdentifier] = caption
        saveJournals(journals)

        DispatchQueue.main.async {
            if let index = self.journalEntries.firstIndex(where: { $0.id == asset.localIdentifier })
            {
                self.journalEntries[index].text = caption
            }
            completion(true, nil)
        }
    }
}
