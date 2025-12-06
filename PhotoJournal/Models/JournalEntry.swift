import Foundation
import Photos
import UIKit

struct JournalEntry: Identifiable {
    let id: String
    let date: Date
    var text: String
    let asset: PHAsset

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.date = asset.creationDate ?? Date()
        self.text = ""  // Will be loaded asynchronously or passed in
        self.asset = asset
    }
}
