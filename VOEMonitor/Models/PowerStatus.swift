/// Current power availability state for a given hour slot.
enum PowerStatus: Equatable {
    /// Power is available for the full hour.
    case on
    /// Power is disconnected for the full hour.
    case off
    /// Partial outage — either first or second half of the hour (`"first"` / `"second"`).
    case partial
    /// Status could not be determined.
    case unknown
}
