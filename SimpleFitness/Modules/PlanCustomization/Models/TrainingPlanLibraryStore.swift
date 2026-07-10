import Foundation
import SwiftUI

/// 完整训练日课表结构体：支持保存到课表库并在主页随时切换选择
public struct TrainingRoutinePlan: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var notes: String
    public var exercises: [PlanExerciseItemMock]
    
    public init(id: UUID = UUID(), name: String, notes: String, exercises: [PlanExerciseItemMock]) {
        self.id = id
        self.name = name
        self.notes = notes
        self.exercises = exercises
    }
    
    public static func == (lhs: TrainingRoutinePlan, rhs: TrainingRoutinePlan) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.exercises.count == rhs.exercises.count
    }
}

/// 训练日课表库管理器（可全局共享或由各个业务模块访问）
public class TrainingPlanLibraryStore: ObservableObject {
    public static let shared = TrainingPlanLibraryStore()
    
    @Published public var savedPlans: [TrainingRoutinePlan]
    @Published public var activePlanId: UUID
    
    public var activePlan: TrainingRoutinePlan {
        savedPlans.first(where: { $0.id == activePlanId }) ?? savedPlans[0]
    }
    
    private init() {
        let chestDay = TrainingRoutinePlan(
            name: "胸与肱三头强化日",
            notes: "侧重胸大肌中下部与上胸塑形，三头力竭收尾",
            exercises: [
                PlanExerciseItemMock(name: "杠铃平板卧推", sets: 4, reps: 10, targetWeightKg: 60.0, restSeconds: 90),
                PlanExerciseItemMock(name: "哑铃上斜卧推", sets: 3, reps: 12, targetWeightKg: 24.0, restSeconds: 90),
                PlanExerciseItemMock(name: "双杠臂屈伸 (Dips)", sets: 3, reps: 12, targetWeightKg: 0.0, restSeconds: 60),
                PlanExerciseItemMock(name: "龙门架夹胸", sets: 3, reps: 15, targetWeightKg: 15.0, restSeconds: 60)
            ]
        )
        
        let backDay = TrainingRoutinePlan(
            name: "背部宽厚与肱二头肌日",
            notes: "高位下拉建立宽度，俯身划船强化厚度",
            exercises: [
                PlanExerciseItemMock(name: "引体向上 (标准宽握)", sets: 4, reps: 8, targetWeightKg: 0.0, restSeconds: 90),
                PlanExerciseItemMock(name: "高位下拉 (宽握)", sets: 4, reps: 12, targetWeightKg: 50.0, restSeconds: 90),
                PlanExerciseItemMock(name: "杠铃俯身划船", sets: 4, reps: 10, targetWeightKg: 55.0, restSeconds: 90),
                PlanExerciseItemMock(name: "哑铃交替弯举", sets: 3, reps: 12, targetWeightKg: 14.0, restSeconds: 60)
            ]
        )
        
        let legDay = TrainingRoutinePlan(
            name: "下肢力量与腹部核心日",
            notes: "深蹲与腿屈伸，结合悬垂举腿强化腹肌",
            exercises: [
                PlanExerciseItemMock(name: "杠铃深蹲", sets: 5, reps: 8, targetWeightKg: 80.0, restSeconds: 120),
                PlanExerciseItemMock(name: "坐姿腿屈伸", sets: 4, reps: 15, targetWeightKg: 45.0, restSeconds: 60),
                PlanExerciseItemMock(name: "悬垂举腿", sets: 3, reps: 15, targetWeightKg: 0.0, restSeconds: 45)
            ]
        )
        
        self.savedPlans = [chestDay, backDay, legDay]
        self.activePlanId = chestDay.id
    }
    
    public func savePlan(_ plan: TrainingRoutinePlan) {
        if let idx = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[idx] = plan
        } else {
            savedPlans.append(plan)
        }
    }
    
    public func selectActivePlan(_ plan: TrainingRoutinePlan) {
        activePlanId = plan.id
    }
    
    public func updateActivePlanExercise(_ exercise: PlanExerciseItemMock, at index: Int) {
        guard let planIdx = savedPlans.firstIndex(where: { $0.id == activePlanId }) else { return }
        guard index >= 0 && index < savedPlans[planIdx].exercises.count else { return }
        savedPlans[planIdx].exercises[index] = exercise
        objectWillChange.send()
    }
}
