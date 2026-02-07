import Foundation
import AppKit
import Combine

@MainActor
class ClipboardManager: ObservableObject {
    @Published var notes: [PasteNote] = []

    private var changeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?
    private let saveURL: URL
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Use Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = appSupport.appendingPathComponent("PasteNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        saveURL = folder.appendingPathComponent("pastenotes.json")

        loadNotes()
        startMonitoring()
        setupAutoSave()
    }

    // MARK: - Clipboard Monitoring
    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        let pb = NSPasteboard.general
        if pb.changeCount != changeCount {
            changeCount = pb.changeCount

            if let copied = pb.string(forType: .string) {
                let cleaned = copied.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleaned.isEmpty else { return }

                let newNote = PasteNote(content: cleaned)
                if !notes.contains(where: { $0.content == newNote.content }) {
                    notes.insert(newNote, at: 0)
                }
            }
        }
    }

    // MARK: - Copy Back
    func copyToClipboard(_ note: PasteNote) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.content, forType: .string)
    }

    // MARK: - Persistence
    func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: saveURL)
        } catch {
            print("❌ Error saving notes: \(error)")
        }
    }

    private func loadNotes() {
        do {
            let data = try Data(contentsOf: saveURL)
            notes = try JSONDecoder().decode([PasteNote].self, from: data)
        } catch {
            notes = []
        }
    }

    // MARK: - Auto-Save
    private func setupAutoSave() {
        $notes
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNotes()
            }
            .store(in: &cancellables)
    }
}
