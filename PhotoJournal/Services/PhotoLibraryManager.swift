import Foundation
import Photos
import UIKit
import ImageIO
import Vision

class PhotoLibraryManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var journalEntries: [JournalEntry] = []
    @Published var isAuthorized = false
    
    private var allAssets: PHFetchResult<PHAsset>?
    private let captionStorage = UserDefaults.standard
    private let captionKey = "PhotoCaptions_v2"

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("📸 照片库发生变更，重新加载...")
        DispatchQueue.main.async {
            self.fetchPhotos()
        }
    }

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
        self.allAssets = fetchResult

        print("\n📷 ========== 开始扫描照片 ==========")
        print("📷 总共找到 \(fetchResult.count) 张照片\n")
        
        // 加载已保存的说明
        let savedCaptions = loadCaptions()
        print("💾 已保存 \(savedCaptions.count) 条说明\n")
        
        var tempEntries: [JournalEntry] = []
        let dispatchGroup = DispatchGroup()
        
        fetchResult.enumerateObjects { asset, index, _ in
            print("🔍 [\(index + 1)/\(fetchResult.count)] 处理照片: \(asset.localIdentifier)")
            
            var description = ""
            
            // 优先使用本地保存的说明
            if let savedCaption = savedCaptions[asset.localIdentifier], !savedCaption.isEmpty {
                description = savedCaption
                print("  ✅ 找到本地保存的说明: \(description)")
            }
            
            // 如果没有本地说明，尝试其他方式
            if description.isEmpty {
                // 尝试读取元数据和识别文字
                dispatchGroup.enter()
                self.extractDescription(from: asset) { extractedDesc in
                    if !extractedDesc.isEmpty {
                        description = extractedDesc
                        print("  ✅ 提取到描述: \(extractedDesc)")
                        // 保存到本地
                        self.saveCaption(extractedDesc, for: asset.localIdentifier)
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 添加到列表（即使暂时没有描述，后续可能会更新）
            if !description.isEmpty {
                print("  ✨ 添加到列表\n")
                let entry = JournalEntry(asset: asset, description: description)
                tempEntries.append(entry)
            } else {
                print("  ⏭️ 暂时跳过（无描述）\n")
            }
        }
        
        // 等待所有异步操作完成
        dispatchGroup.notify(queue: .main) {
            // 重新检查是否有新的描述
            let updatedCaptions = self.loadCaptions()
            var finalEntries: [JournalEntry] = []
            
            fetchResult.enumerateObjects { asset, _, _ in
                if let caption = updatedCaptions[asset.localIdentifier], !caption.isEmpty {
                    let entry = JournalEntry(asset: asset, description: caption)
                    finalEntries.append(entry)
                }
            }
            
            self.journalEntries = finalEntries
            print("\n✅ ========== 扫描完成 ==========")
            print("✅ 最终显示 \(finalEntries.count) 张有描述的照片\n")
        }
    }
    
    // 提取照片的描述信息
    private func extractDescription(from asset: PHAsset, completion: @escaping (String) -> Void) {
        let options = PHContentEditingInputRequestOptions()
        options.isNetworkAccessAllowed = true
        
        asset.requestContentEditingInput(with: options) { [weak self] input, _ in
            guard let self = self, let input = input, let imageURL = input.fullSizeImageURL else {
                completion("")
                return
            }
            
            var description = ""
            
            // 1. 尝试读取元数据
            if let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
               let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                
                print("  📋 元数据字段: \(metadata.keys.joined(separator: ", "))")
                
                // EXIF UserComment
                if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                    print("  📝 EXIF 字段: \(exif.keys.joined(separator: ", "))")
                    if let userComment = exif[kCGImagePropertyExifUserComment as String] as? String, !userComment.isEmpty {
                        description = userComment
                        print("  ✅ EXIF UserComment: \(description)")
                    }
                }
                
                // IPTC Caption
                if description.isEmpty, let iptc = metadata[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
                    print("  📝 IPTC 字段: \(iptc.keys.joined(separator: ", "))")
                    if let caption = iptc[kCGImagePropertyIPTCCaptionAbstract as String] as? String, !caption.isEmpty {
                        description = caption
                        print("  ✅ IPTC Caption: \(description)")
                    }
                }
                
                // TIFF Description
                if description.isEmpty, let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
                    print("  📝 TIFF 字段: \(tiff.keys.joined(separator: ", "))")
                    if let tiffDesc = tiff[kCGImagePropertyTIFFImageDescription as String] as? String, !tiffDesc.isEmpty {
                        description = tiffDesc
                        print("  ✅ TIFF Description: \(description)")
                    }
                }
            }
            
            // 2. 如果元数据没有，尝试使用 Vision 识别图片中的文字
            if description.isEmpty {
                self.recognizeText(in: imageURL) { recognizedText in
                    if !recognizedText.isEmpty {
                        description = "📝 识别的文字: \(recognizedText)"
                        print("  ✅ Vision 识别: \(recognizedText)")
                    }
                    completion(description)
                }
            } else {
                completion(description)
            }
        }
    }
    
    // 使用 Vision 识别图片中的文字
    private func recognizeText(in imageURL: URL, completion: @escaping (String) -> Void) {
        guard let image = UIImage(contentsOfFile: imageURL.path),
              let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            let text = recognizedStrings.prefix(3).joined(separator: " ")
            completion(text)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
    
    // MARK: - 本地存储
    
    private func loadCaptions() -> [String: String] {
        if let data = captionStorage.data(forKey: captionKey),
           let captions = try? JSONDecoder().decode([String: String].self, from: data) {
            return captions
        }
        return [:]
    }
    
    private func saveCaption(_ caption: String, for assetID: String) {
        var captions = loadCaptions()
        captions[assetID] = caption
        if let data = try? JSONEncoder().encode(captions) {
            captionStorage.set(data, forKey: captionKey)
        }
    }
}
