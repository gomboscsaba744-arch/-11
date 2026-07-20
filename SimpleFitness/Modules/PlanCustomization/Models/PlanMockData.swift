import Foundation

public struct PlanExerciseItemMock: Identifiable, Codable, Equatable {
    public var id = UUID()
    public var name: String
    public var sets: Int
    public var reps: Int
    public var targetWeightKg: Double
    public var restSeconds: Int
    /// 动作间切换休息时长（秒）
    public var exerciseRestSeconds: Int
    public var customRepsPerSet: [Int: Int]
    /// 当前训练中实际已完成的组数
    public var completedSets: Int
    /// 是否真正完成了目标组数
    public var isCompleted: Bool { completedSets >= sets && sets > 0 }
    
    public init(id: UUID = UUID(), name: String, sets: Int, reps: Int, targetWeightKg: Double, restSeconds: Int, exerciseRestSeconds: Int = 120, customRepsPerSet: [Int: Int] = [:], completedSets: Int = 0) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.targetWeightKg = targetWeightKg
        self.restSeconds = restSeconds
        self.exerciseRestSeconds = exerciseRestSeconds
        self.customRepsPerSet = customRepsPerSet
        self.completedSets = completedSets
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
        // 推 (Push)
        PlanExerciseItemMock(name: "杠铃平板卧推", sets: 4, reps: 10, targetWeightKg: 40.0, restSeconds: 90),
        PlanExerciseItemMock(name: "杠铃上斜卧推", sets: 4, reps: 12, targetWeightKg: 30.0, restSeconds: 90),
        PlanExerciseItemMock(name: "哑铃夹胸/飞鸟", sets: 4, reps: 15, targetWeightKg: 12.0, restSeconds: 60),
        PlanExerciseItemMock(name: "哑铃坐姿肩部推举", sets: 4, reps: 12, targetWeightKg: 16.0, restSeconds: 90),
        PlanExerciseItemMock(name: "哑铃站姿侧平举", sets: 4, reps: 15, targetWeightKg: 8.0, restSeconds: 60),
        PlanExerciseItemMock(name: "绳索下压", sets: 4, reps: 15, targetWeightKg: 25.0, restSeconds: 60),
        PlanExerciseItemMock(name: "杠铃仰卧三头肌伸展", sets: 3, reps: 12, targetWeightKg: 20.0, restSeconds: 60),
        PlanExerciseItemMock(name: "臂屈伸", sets: 3, reps: 12, targetWeightKg: 0.0, restSeconds: 60),
        
        // 拉 (Pull)
        PlanExerciseItemMock(name: "对握引体向上", sets: 4, reps: 8, targetWeightKg: 0.0, restSeconds: 90),
        PlanExerciseItemMock(name: "绳索高位下拉", sets: 4, reps: 10, targetWeightKg: 45.0, restSeconds: 90),
        PlanExerciseItemMock(name: "杠铃划船", sets: 4, reps: 10, targetWeightKg: 40.0, restSeconds: 90),
        PlanExerciseItemMock(name: "绳索坐姿划船", sets: 4, reps: 12, targetWeightKg: 45.0, restSeconds: 90),
        PlanExerciseItemMock(name: "高位下拉", sets: 3, reps: 15, targetWeightKg: 35.0, restSeconds: 60),
        PlanExerciseItemMock(name: "杠铃二头弯举", sets: 4, reps: 12, targetWeightKg: 25.0, restSeconds: 60),
        PlanExerciseItemMock(name: "哑铃二头交替弯举", sets: 3, reps: 12, targetWeightKg: 12.0, restSeconds: 60),
        PlanExerciseItemMock(name: "绳索锤式弯举", sets: 3, reps: 15, targetWeightKg: 20.0, restSeconds: 60),
        
        // 腿 (Legs & Core)
        PlanExerciseItemMock(name: "杠铃深蹲", sets: 4, reps: 8, targetWeightKg: 70.0, restSeconds: 120),
        PlanExerciseItemMock(name: "哑铃深蹲", sets: 4, reps: 12, targetWeightKg: 24.0, restSeconds: 90),
        PlanExerciseItemMock(name: "杠铃硬拉", sets: 4, reps: 10, targetWeightKg: 60.0, restSeconds: 90),
        PlanExerciseItemMock(name: "器械推举", sets: 4, reps: 10, targetWeightKg: 100.0, restSeconds: 90),
        PlanExerciseItemMock(name: "器械臂屈伸", sets: 4, reps: 12, targetWeightKg: 40.0, restSeconds: 60),
        PlanExerciseItemMock(name: "器械仰卧二头弯举", sets: 4, reps: 12, targetWeightKg: 35.0, restSeconds: 60),
        PlanExerciseItemMock(name: "绳索站姿提踵", sets: 4, reps: 15, targetWeightKg: 35.0, restSeconds: 60),
        PlanExerciseItemMock(name: "悬垂举腿", sets: 3, reps: 15, targetWeightKg: 0.0, restSeconds: 60)
    ]
}
