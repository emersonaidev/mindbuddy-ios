import Foundation
import SwiftUI

struct HealthData: Codable, Identifiable {
    let id: String
    let dataType: String
    let value: HealthDataValue
    let unit: String
    let timestamp: String
    let source: String
    let createdAt: String
}

enum HealthDataValue: Codable {
    case number(Double)
    case string(String)
    case object([String: String])
    case array([String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let dict = try? container.decode([String: String].self) {
            self = .object(dict)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(HealthDataValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode HealthDataValue"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .number(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Health Data DTOs

struct HealthDataSubmitRequest: Codable {
    let dataType: String
    let value: HealthDataValue
    let unit: String
    let timestamp: String
    let source: String
}

struct HealthDataBatchRequest: Codable {
    let data: [HealthDataSubmitRequest]
}

struct HealthDataBatchResponse: Codable {
    let submitted: Int
    let tokensEarned: String
    let errors: [HealthDataError]?
}

struct HealthDataError: Codable {
    let index: Int
    let error: String
}

struct HealthDataSummaryResponse: Codable {
    let totalRecords: Int
    let dataTypes: [String]
    let dateRange: DateRange
    let recentData: [HealthData]
}

struct DateRange: Codable {
    let start: String
    let end: String
}

// MARK: - Health Data Types

enum HealthDataType: String, CaseIterable {
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case stressLevel = "stress_level"
    case activity = "activity"
    case sleep = "sleep"
    case hrv = "hrv"
    case steps = "steps"
    case calories = "calories"
    
    var displayName: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .bloodPressure:
            return "Blood Pressure"
        case .stressLevel:
            return "Stress Level"
        case .activity:
            return "Activity"
        case .sleep:
            return "Sleep"
        case .hrv:
            return "Heart Rate Variability"
        case .steps:
            return "Steps"
        case .calories:
            return "Calories"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate:
            return "BPM"
        case .bloodPressure:
            return "mmHg"
        case .stressLevel:
            return "Level"
        case .activity:
            return "Minutes"
        case .sleep:
            return "Hours"
        case .hrv:
            return "ms"
        case .steps:
            return "Steps"
        case .calories:
            return "Cal"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate:
            return "heart.fill"
        case .bloodPressure:
            return "heart.text.square"
        case .stressLevel:
            return "brain.head.profile"
        case .activity:
            return "figure.walk"
        case .sleep:
            return "bed.double.fill"
        case .hrv:
            return "waveform.path.ecg"
        case .steps:
            return "figure.walk"
        case .calories:
            return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate:
            return .red
        case .bloodPressure:
            return .orange
        case .stressLevel:
            return .purple
        case .activity:
            return .green
        case .sleep:
            return .blue
        case .hrv:
            return .purple
        case .steps:
            return .green
        case .calories:
            return .orange
        }
    }
}

enum DataSource: String {
    case appleWatch = "apple_watch"
    case manual = "manual"
    case other = "other"
}

// MARK: - Simplified HealthData for UI

extension HealthData {
    // Convenience initializer for UI components
    init(type: String, value: HealthDataValue, unit: String, recordedAt: Date) {
        self.id = UUID().uuidString
        self.dataType = type
        self.value = value
        self.unit = unit
        self.timestamp = DateUtilities.toISO8601String(recordedAt)
        self.source = DataSource.appleWatch.rawValue
        self.createdAt = DateUtilities.toISO8601String(Date())
    }
    
    // Computed properties for UI
    var type: String {
        return dataType
    }
    
    var recordedAt: Date {
        return DateUtilities.fromISO8601String(timestamp) ?? Date()
    }
}

// Add double and integer cases to HealthDataValue for UI compatibility
extension HealthDataValue {
    static func double(_ value: Double) -> HealthDataValue {
        return .number(value)
    }
    
    static func integer(_ value: Int) -> HealthDataValue {
        return .number(Double(value))
    }
}