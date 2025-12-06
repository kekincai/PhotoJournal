import Photos
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var photoLibraryManager: PhotoLibraryManager

    // Group entries by date
    private var groupedEntries: [(String, [(String, [JournalEntry])])] {
        let calendar = Calendar.current

        let byYear = Dictionary(grouping: photoLibraryManager.journalEntries) { entry in
            calendar.component(.year, from: entry.date)
        }

        return byYear.sorted { $0.key > $1.key }.map { (year, yearEntries) in
            let byMonth = Dictionary(grouping: yearEntries) { entry in
                calendar.component(.month, from: entry.date)
            }

            let monthGroups = byMonth.sorted { $0.key > $1.key }.map { (month, monthEntries) in
                let monthName = calendar.monthSymbols[month - 1]
                let sortedEntries = monthEntries.sorted { $0.date > $1.date }
                return (monthName, sortedEntries)
            }

            return ("\(year)", monthGroups)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if !photoLibraryManager.isAuthorized {
                    PermissionRequestView {
                        photoLibraryManager.checkAuthorization()
                    }
                } else if photoLibraryManager.journalEntries.isEmpty {
                    EmptyStateView()
                } else {
                    NotebookScrollView(groupedEntries: groupedEntries)
                }
            }
            .background(NotebookBackground())
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("📓")
                            .font(.title2)
                        Text("My Photo Journal")
                            .font(.custom("Noteworthy-Bold", size: 22))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                    }
                }
            }
        }
        .onAppear {
            photoLibraryManager.checkAuthorization()
        }
    }
}

// MARK: - Notebook Background
struct NotebookBackground: View {
    var body: some View {
        ZStack {
            // Paper texture color
            Color(red: 1.0, green: 0.98, blue: 0.94)

            // Subtle lines pattern
            GeometryReader { geometry in
                VStack(spacing: 28) {
                    ForEach(0..<50, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.5))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 60)
            }

            // Left margin line
            HStack {
                Rectangle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 2)
                    .padding(.leading, 50)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Permission Request View
struct PermissionRequestView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Cute illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.2), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Text("📸")
                    .font(.system(size: 70))
            }

            VStack(spacing: 12) {
                Text("Let's Start Journaling!")
                    .font(.custom("Noteworthy-Bold", size: 28))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))

                Text("Allow access to your photos to create beautiful memory pages ✨")
                    .font(.custom("Noteworthy", size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: onRequestPermission) {
                HStack {
                    Text("📷")
                    Text("Allow Photo Access")
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
                        .shadow(color: .pink.opacity(0.4), radius: 10, y: 5)
                )
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📭")
                .font(.system(size: 60))
            Text("No Photos Yet")
                .font(.custom("Noteworthy-Bold", size: 24))
                .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
            Text("Your journal pages will appear here")
                .font(.custom("Noteworthy", size: 16))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Notebook Scroll View
struct NotebookScrollView: View {
    let groupedEntries: [(String, [(String, [JournalEntry])])]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                ForEach(groupedEntries, id: \.0) { year, months in
                    YearSection(year: year, months: months)
                }
            }
            .padding()
        }
    }
}

// MARK: - Year Section
struct YearSection: View {
    let year: String
    let months: [(String, [JournalEntry])]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Year Header with decorative tape
            HStack {
                Text("📅 \(year)")
                    .font(.custom("Noteworthy-Bold", size: 28))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.3))
                            .rotationEffect(.degrees(-2))
                    )
                Spacer()
            }

            ForEach(months, id: \.0) { month, entries in
                MonthSection(month: month, entries: entries)
            }
        }
    }
}

// MARK: - Month Section
struct MonthSection: View {
    let month: String
    let entries: [JournalEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month Header
            HStack {
                Text("🌸 \(month)")
                    .font(.custom("Noteworthy-Bold", size: 20))
                    .foregroundColor(Color.pink.opacity(0.8))

                Spacer()

                Text("\(entries.count) pages")
                    .font(.custom("Noteworthy", size: 14))
                    .foregroundColor(.secondary)
            }

            // Journal Cards
            ForEach(entries) { entry in
                NavigationLink(destination: JournalDetailView(entry: entry)) {
                    JournalCard(entry: entry)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Decorative tape on top
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.mint.opacity(0.6))
                        .frame(width: 60, height: 20)
                        .rotationEffect(.degrees(-8))
                        .offset(x: 20, y: -10)
                    Spacer()
                }
                Spacer()
            }
        )
    }
}

// MARK: - Journal Card (Scrapbook Style)
struct JournalCard: View {
    let entry: JournalEntry
    @State private var image: UIImage? = nil

    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date Badge (like a stamp)
            VStack(spacing: 2) {
                Text(dayString)
                    .font(.custom("Noteworthy-Bold", size: 22))
                    .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.25))
                Text(weekdayString)
                    .font(.custom("Noteworthy", size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4]))
            )

            // Photo with polaroid style
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                    .frame(width: 88, height: 96)

                VStack(spacing: 4) {
                    Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                    }
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                    Spacer()
                }
                .padding(.top, 6)
            }
            .frame(width: 88, height: 96)
            .rotationEffect(.degrees(-2))

            // Journal Text
            VStack(alignment: .leading, spacing: 8) {
                if entry.text.isEmpty {
                    Text("Tap to write...")
                        .font(.custom("Noteworthy", size: 14))
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    Text(entry.text)
                        .font(.custom("Noteworthy", size: 14))
                        .lineLimit(3)
                        .foregroundColor(Color(red: 0.3, green: 0.25, blue: 0.2))
                }

                Spacer()

                // Sticker indicator
                HStack {
                    Spacer()
                    Text(entry.text.isEmpty ? "✏️" : "✅")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic

        manager.requestImage(
            for: entry.asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill,
            options: options
        ) { result, _ in
            self.image = result
        }
    }
}
