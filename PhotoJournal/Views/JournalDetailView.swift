import Photos
import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry
    @State private var fullImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Notebook background
            NotebookDetailBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Photo in polaroid frame
                    PolaroidPhotoView(image: fullImage, date: entry.date)

                    // Date header
                    DateHeaderView(date: entry.date)

                    // Journal display area (read-only)
                    JournalDisplayArea(text: entry.text)

                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("📖 我的回忆")
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
            }
        }
        .onAppear {
            loadFullImage()
        }
    }

    private func loadFullImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        manager.requestImage(
            for: entry.asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit,
            options: options
        ) { result, _ in
            self.fullImage = result
        }
    }
}

// MARK: - Notebook Detail Background
struct NotebookDetailBackground: View {
    var body: some View {
        ZStack {
            // Cream paper
            Color(red: 1.0, green: 0.98, blue: 0.94)

            // Ruled lines
            GeometryReader { geometry in
                VStack(spacing: 28) {
                    ForEach(0..<60, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.5))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 100)
            }

            // Left margin
            HStack {
                Rectangle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 2)
                    .padding(.leading, 30)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Polaroid Photo View
struct PolaroidPhotoView: View {
    let image: UIImage?
    let date: Date
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月 d日"
        return formatter.string(from: date)
    }

    var body: some View {
        ZStack {
            // Polaroid frame
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 3, y: 5)

            VStack(spacing: 8) {
                // Photo
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .clipped()

                // Date caption
                Text(formattedDate)
                    .font(.custom("Noteworthy", size: 14))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
        }
        .frame(width: 290, height: 330)
        .rotationEffect(.degrees(-2))
        .overlay(
            // Decorative tape
            VStack {
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.yellow.opacity(0.7))
                        .frame(width: 50, height: 18)
                        .rotationEffect(.degrees(35))
                        .offset(x: 10, y: -8)
                }
                Spacer()
            }
        )
    }
}

// MARK: - Date Header
struct DateHeaderView: View {
    let date: Date

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年 M月 d日 EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack {
            Text("📅")
            Text(formattedDate)
                .font(.custom("Noteworthy-Bold", size: 18))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
        )
    }
}

// MARK: - Journal Display Area (Read-Only)
struct JournalDisplayArea: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📖 照片说明")
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                Spacer()
            }

            // Display area with notebook style
            ZStack(alignment: .topLeading) {
                // Background lines
                VStack(spacing: 28) {
                    ForEach(0..<10, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 22)

                if text.isEmpty {
                    Text("这张照片暂无说明 📷")
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                        .padding(.horizontal, 4)
                } else {
                    Text(text)
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.05), radius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pink.opacity(0.3), lineWidth: 2)
            )
        }
    }
}
