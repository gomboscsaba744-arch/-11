import Foundation

public struct HistoryRecordMock: Identifiable {
    public let id = UUID()
    public var title: String
    public var dateString: String
    public var durationMinutes: Int
    public var calories: Int
    public var sets: Int
    
    public init(title: String, dateString: String, durationMinutes: Int, calories: Int, sets: Int) {
        self.title = title
        self.dateString = dateString
        self.durationMinutes = durationMinutes
        self.calories = calories
        self.sets = sets
    }
}

public struct HistoryMockData {
    public static let sampleRecords: [HistoryRecordMock] = [
        HistoryRecordMock(title: "胸部与三头肌轰炸日", dateString: "今天 14:30", durationMinutes: 52, calories: 410, sets: 16),
        HistoryRecordMock(title: "背部与二头肌训练", dateString: "昨天 16:00", durationMinutes: 60, calories: 480, sets: 18),
        HistoryRecordMock(title: "王牌腿部训练日", dateString: "7月5日", durationMinutes: 65, calories: 550, sets: 20)
    ]
}
