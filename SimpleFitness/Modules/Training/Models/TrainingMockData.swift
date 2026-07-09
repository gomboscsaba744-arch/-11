import Foundation

public struct TrainingSessionMock {
    public var modeTitle: String = "自由训练模式"
    public var exerciseName: String = "杠铃平板卧推"
    public var currentHeartRate: Int = 0
    public var currentCalories: Int = 0
    
    public var currentSet: Int = 1
    public var totalSets: Int = 4
    public var targetWeightKg: Double = 60.0
    
    public var currentReps: Int = 10
}
