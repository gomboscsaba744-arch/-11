import Foundation

public struct PlanExerciseItemMock: Identifiable {
    public let id = UUID()
    public var name: String
    public var sets: Int
    public var reps: Int
    public var targetWeightKg: Double
    public var restSeconds: Int
    
    public init(name: String, sets: Int, reps: Int, targetWeightKg: Double, restSeconds: Int) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.targetWeightKg = targetWeightKg
        self.restSeconds = restSeconds
    }
}

public struct PlanMockData {
    public static let sampleExercises: [PlanExerciseItemMock] = [
        PlanExerciseItemMock(name: "杠铃平板卧推", sets: 4, reps: 10, targetWeightKg: 60.0, restSeconds: 90),
        PlanExerciseItemMock(name: "哑铃上斜卧推", sets: 3, reps: 12, targetWeightKg: 24.0, restSeconds: 90),
        PlanExerciseItemMock(name: "绳索夹胸 (高位/低位)", sets: 3, reps: 15, targetWeightKg: 15.0, restSeconds: 60)
    ]
}
