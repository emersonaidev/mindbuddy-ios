import Foundation

// MARK: - Date Utilities

class DateUtilities {
    
    // MARK: - Shared Formatters (Performance Optimization)
    
    private static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    // MARK: - Public Methods
    
    /// Formats a date string from the API to a user-friendly display format
    static func formatDate(_ dateString: String) -> String {
        guard let date = iso8601Formatter.date(from: dateString) else {
            return "Unknown"
        }
        return displayFormatter.string(from: date)
    }
    
    /// Formats a date to a short display format (e.g., "Jan 15")
    static func formatShortDate(_ date: Date) -> String {
        return shortDateFormatter.string(from: date)
    }
    
    /// Formats a date to show only time (e.g., "14:30")
    static func formatTime(_ date: Date) -> String {
        return timeOnlyFormatter.string(from: date)
    }
    
    /// Formats a date relative to now (e.g., "2 hours ago")
    static func formatRelativeDate(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Converts a Date to ISO8601 string for API requests
    static func toISO8601String(_ date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
    
    /// Converts ISO8601 string from API to Date
    static func fromISO8601String(_ dateString: String) -> Date? {
        return iso8601Formatter.date(from: dateString)
    }
    
    /// Gets the start of day for a given date
    static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    /// Gets the end of day for a given date
    static func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay(for: date)) ?? date
    }
    
    /// Gets date range for the last N days
    static func lastDays(_ numberOfDays: Int, from date: Date = Date()) -> (start: Date, end: Date) {
        let endDate = endOfDay(for: date)
        let startDate = Calendar.current.date(byAdding: .day, value: -numberOfDays, to: startOfDay(for: date)) ?? date
        return (start: startDate, end: endDate)
    }
    
    /// Checks if a date is today
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    /// Checks if a date is yesterday
    static func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    /// Gets age in seconds from a date
    static func ageInSeconds(from date: Date) -> TimeInterval {
        return Date().timeIntervalSince(date)
    }
    
    /// Checks if data is fresh (within specified max age)
    static func isFresh(_ date: Date, maxAge: TimeInterval) -> Bool {
        return ageInSeconds(from: date) < maxAge
    }
}

// MARK: - Date Extensions

extension Date {
    
    /// Convenient accessor for date utilities
    var formatted: String {
        return DateUtilities.formatShortDate(self)
    }
    
    var timeFormatted: String {
        return DateUtilities.formatTime(self)
    }
    
    var relativeFormatted: String {
        return DateUtilities.formatRelativeDate(self)
    }
    
    var iso8601String: String {
        return DateUtilities.toISO8601String(self)
    }
    
    var isToday: Bool {
        return DateUtilities.isToday(self)
    }
    
    var isYesterday: Bool {
        return DateUtilities.isYesterday(self)
    }
    
    var startOfDay: Date {
        return DateUtilities.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        return DateUtilities.endOfDay(for: self)
    }
}

// MARK: - String Extensions

extension String {
    
    /// Converts ISO8601 date string to Date
    var iso8601Date: Date? {
        return DateUtilities.fromISO8601String(self)
    }
    
    /// Formats ISO8601 date string for display
    var formattedDate: String {
        return DateUtilities.formatDate(self)
    }
}