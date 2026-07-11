import Foundation

public struct TrainingSessionMock {
    public var workoutTitle: String = "胸与肱三头强化日"
    public var currentExerciseIndex: Int = 5
    public var totalExercises: Int = 12
    
    public var modeTitle: String = "自由训练模式"
    public var exerciseName: String = "杠铃平板卧推"
    public var currentHeartRate: Int = 0
    public var currentCalories: Int = 0
    
    public var currentSet: Int = 1
    public var totalSets: Int = 4
    public var targetWeightKg: Double = 60.0
    
    public var currentReps: Int = 0
    public var watchTelemetry: WatchSensorTelemetryModel = WatchSensorTelemetryModel()
}

/// 预留给 Apple Watch / CoreMotion 的表端检测接口数据模型
public struct WatchSensorTelemetryModel {
    public var isWatchConnected: Bool = false
    public var detectedRepCount: Int = 0
    public var repDetectionConfidence: Double = 0.0
    public var gyroscopeAmplitudeDegPerSec: Double = 0.0
    public var motionTrajectoryStabilityString: String = "等待表端传感器连入"
    
    public init() {}
}

