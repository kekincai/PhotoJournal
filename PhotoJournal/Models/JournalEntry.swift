import Foundation
import Photos
import UIKit

struct JournalEntry: Identifiable {
    let id: String
    let date: Date
    let text: String
    let asset: PHAsset

    init(asset: PHAsset, description: String) {
        self.id = asset.localIdentifier
        self.date = asset.creationDate ?? Date()
        self.text = description
        self.asset = asset
    }
}
