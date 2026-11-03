import AppIntents

struct QueueEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Queue")
    static let defaultQuery = QueueEntityQuery()

    var id: String
    var displayName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName)")
    }

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    init(from queue: Queue) {
        self.id = queue.id
        self.displayName = queue.displayName
    }
}

struct QueueEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [QueueEntity] {
        Queue.all.filter { identifiers.contains($0.id) }.map { QueueEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [QueueEntity] {
        Queue.all.map { QueueEntity(from: $0) }
    }

    func defaultResult() async -> QueueEntity? {
        let config = SharedConfigManager().load()
        guard !config.selectedQueue.isEmpty else { return nil }
        return Queue.all.first { $0.id == config.selectedQueue }.map { QueueEntity(from: $0) }
    }
}

struct SelectQueueIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "widget.select_queue"
    static let description: IntentDescription = "widget.select_queue_description"

    @Parameter(title: "settings.queue")
    var queue: QueueEntity?
}
