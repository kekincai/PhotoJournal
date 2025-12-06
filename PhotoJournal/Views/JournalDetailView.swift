import Photos
import SwiftUI

struct JournalDetailView: View {
    @State var entry: JournalEntry
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager
    @State private var fullImage: UIImage? = nil
    @State private var isEditing = false
    @State private var editedText: String = ""
    @State private var isSaving = false
    @State private var saveMessage: String? = nil
    @Environment(\.dismiss) var dismiss

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

                    // Journal writing area
                    JournalWritingArea(
                        text: $editedText,
                        isEditing: $isEditing,
                        originalText: entry.text
                    )

                    // Save button
                    if isEditing || editedText != entry.text {
                        SaveButton(isSaving: isSaving) {
                            saveJournal()
                        }
                    }

                    // Status message
                    if let message = saveMessage {
                        Text(message)
                            .font(.custom("Noteworthy", size: 14))
                            .foregroundColor(.green)
                            .transition(.opacity)
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("✏️ My Memory")
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
            }
        }
        .onAppear {
            loadFullImage()
            editedText = entry.text
        }
    }

    private func saveJournal() {
        isSaving = true
        saveMessage = nil

        photoLibraryManager.saveCaption(for: entry.asset, caption: editedText) { success, error in
            isSaving = false
            if success {
                entry.text = editedText
                isEditing = false
                withAnimation {
                    saveMessage = "✨ Saved to photo!"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        saveMessage = nil
                    }
                }
            } else {
                saveMessage = "❌ Error: \(error?.localizedDescription ?? "Unknown")"
            }
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
                Text(date, style: .date)
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
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
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

// MARK: - Journal Writing Area
struct JournalWritingArea: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let originalText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("✍️ My Journal")
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                Spacer()

                if !isEditing && !originalText.isEmpty {
                    Button(action: { isEditing = true }) {
                        Text("Edit ✏️")
                            .font(.custom("Noteworthy", size: 14))
                            .foregroundColor(.blue)
                    }
                }
            }

            // Writing area with notebook style
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

                if text.isEmpty && !isEditing {
                    Text("Tap here to write your thoughts... ✨")
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.horizontal, 4)
                        .onTapGesture {
                            isEditing = true
                        }
                } else {
                    TextEditor(text: $text)
                        .font(.custom("Noteworthy", size: 16))
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 200)
                        .onTapGesture {
                            isEditing = true
                        }
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

// MARK: - Save Button
struct SaveButton: View {
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("💾")
                }
                Text(isSaving ? "Saving..." : "Save Journal")
                    .font(.custom("Noteworthy-Bold", size: 18))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.pink, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
            )
        }
        .disabled(isSaving)
        .padding(.horizontal)
    }
}
