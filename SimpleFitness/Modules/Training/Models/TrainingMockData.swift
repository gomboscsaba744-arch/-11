import Foundation

public struct TrainingSessionMock {
    public var workoutTitle: String = "胸肌与肱三头肌强化日"
    public var currentExerciseIndex: Int = 5
    public var totalExercises: Int = 12
    
    public var modeTitle: String = "自由训练模式"
    public var exerciseName: String = "杠铃平板卧推"
    public var currentHeartRate: Int = 124
    public var currentCalories: Int = 186
    
    public var currentSet: Int = 1
    public var totalSets: Int = 4
    public var targetWeightKg: Double = 60.0
    
    public var currentReps: Int = 10
    public var watchTelemetry: WatchSensorTelemetryModel = WatchSensorTelemetryModel()
}

/// 预留给 Apple Watch / CoreMotion 的表端检测接口数据模型
public struct WatchSensorTelemetryModel {
    public var isWatchConnected: Bool = true
    public var detectedRepCount: Int = 10
    public var repDetectionConfidence: Double = 0.98
    public var gyroscopeAmplitudeDegPerSec: Double = 42.6
    public var motionTrajectoryStabilityString: String = "优 (发力向心稳定)"
    
    public init() {}
}

