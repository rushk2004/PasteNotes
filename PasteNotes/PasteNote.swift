import Foundation

struct PasteNote: Identifiable, Codable, Equatable, Hashable {
    let id = UUID()
    var title: String
    var content: String
    var date: Date = Date()

    init(content: String, title: String? = nil) {
        self.content = content
        self.title = title ?? content
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled"
    }
}
