import SwiftUI

struct ContentView: View {
    @StateObject private var clipboard = ClipboardManager()
    @State private var searchText = ""
    @State private var selectedNoteID: PasteNote.ID? = nil
    @State private var hoveredNoteID: PasteNote.ID? = nil

    var filteredNotes: [PasteNote] {
        if searchText.isEmpty { return clipboard.notes }
        return clipboard.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
            || $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Clipboard History")
                        .font(.headline)
                        .padding(.leading)
                    Spacer()
                    if !clipboard.notes.isEmpty {
                        Button(role: .destructive) {
                            withAnimation { clipboard.notes.removeAll() }
                        } label: {
                            Label("Clear All", systemImage: "trash")
                                .labelStyle(.iconOnly)
                                .help("Delete all saved clips")
                        }
                        .buttonStyle(.borderless)
                        .padding(.trailing)
                    }
                }
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .overlay(Divider(), alignment: .bottom)

                // List of notes
                List(filteredNotes, id: \.id, selection: $selectedNoteID) { note in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(note.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(note.content)
                            .lineLimit(2)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)

                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(
                                selectedNoteID == note.id ? 0.2 :
                                hoveredNoteID == note.id ? 0.08 : 0
                            ))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedNoteID == note.id ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1)
                    )
                    .onHover { hovering in
                        hoveredNoteID = hovering ? note.id : nil
                    }
                    .contextMenu {
                        Button {
                            clipboard.copyToClipboard(note)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }

                        ShareLink(item: note.content) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            delete(note: note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: hoveredNoteID)
                }
                .listStyle(.inset)
                .searchable(text: $searchText, prompt: "Search clips...")
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .navigationTitle("PasteNotes")
        } detail: {
            if let selectedID = selectedNoteID,
               let index = clipboard.notes.firstIndex(where: { $0.id == selectedID }) {
                let noteBinding = $clipboard.notes[index]
                VStack(spacing: 12) {
                    TextField("Title", text: noteBinding.title)
                        .font(.title2)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    ScrollView {
                        Text(noteBinding.wrappedValue.content)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                            .padding()
                    }

                    Divider()

                    HStack {
                        Button {
                            clipboard.copyToClipboard(noteBinding.wrappedValue)
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }

                        ShareLink(item: noteBinding.wrappedValue.content) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            delete(note: noteBinding.wrappedValue)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Spacer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                .animation(.easeInOut, value: selectedNoteID)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "clipboard")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    Text("No note selected")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Copy something to get started!")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(minWidth: 850, minHeight: 550)
        .onDeleteCommand {
            if let selectedID = selectedNoteID,
               let note = clipboard.notes.first(where: { $0.id == selectedID }) {
                delete(note: note)
            }
        }
    }

    // MARK: - Helpers
    private func delete(note: PasteNote) {
        withAnimation {
            clipboard.notes.removeAll { $0.id == note.id }
        }
    }
}

