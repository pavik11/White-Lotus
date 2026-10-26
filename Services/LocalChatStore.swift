import Foundation

protocol ChatStoring {
    func save(_ session: ChatSession) throws
    func deleteAll() throws
}

final class LocalChatStore: ChatStoring {
    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var defaultDirectory = base.appendingPathComponent("WellnessChats", isDirectory: true)
        #if DEBUG
        if ProcessInfo.processInfo.environment["WELLNESS_ISOLATED_TEST_STATE"] == "1" {
            defaultDirectory = fileManager.temporaryDirectory.appendingPathComponent("WellnessUITestChats", isDirectory: true)
        }
        #endif
        self.directory = directory ?? defaultDirectory
    }

    func save(_ session: ChatSession) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        var protectedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(values)
        let file = directory.appendingPathComponent(session.id.uuidString).appendingPathExtension("json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // Atomic snapshots append turns to one JSON conversation; sessions are never fed into a new chat.
        let data = try encoder.encode(session)
        #if os(iOS)
        try data.write(to: file, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: file, options: .atomic)
        #endif
    }

    func deleteAll() throws {
        if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
    }
}
