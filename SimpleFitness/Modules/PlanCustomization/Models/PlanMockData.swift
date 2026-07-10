import Foundation

public struct PlanExerciseItemMock: Identifiable {
    public let id = UUID()
    public var name: String
    public var sets: Int
    public var reps: Int
    public var targetWeightKg: Double
    public var restSeconds: Int
    public var customRepsPerSet: [Int: Int]
    
    public init(name: String, sets: Int, reps: Int, targetWeightKg: Double, restSeconds: Int, customRepsPerSet: [Int: Int] = [:]) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.targetWeightKg = targetWeightKg
        self.restSeconds = restSeconds
        self.customRepsPerSet = customRepsPerSet
    }
    
    /// 获取指定组号（1开始）的目标次数；若有自定义值则返回自定义，否则默认各组一致
    public func getTargetReps(forSet setIndex: Int) -> Int {
        return customRepsPerSet[setIndex] ?? reps
    }
    
    /// 单独设定某一特定组的次数
    public mutating func setTargetReps(_ newReps: Int, forSet setIndex: Int) {
        customRepsPerSet[setIndex] = newReps
    }
}

public struct PlanMockData {
    public static let sampleExercises: [PlanExerciseItemMock] = [
        PlanExerciseItemMock(name: "杠铃平板卧推", sets: 4, reps: 10, targetWeightKg: 60.0, restSeconds: 90),
        PlanExerciseItemMock(name: "哑铃上斜卧推", sets: 3, reps: 12, targetWeightKg: 24.0, restSeconds: 90),
        PlanExerciseItemMock(name: "绳索夹胸 (高位/低位)", sets: 3, reps: 15, targetWeightKg: 15.0, restSeconds: 60)
    ]
}
