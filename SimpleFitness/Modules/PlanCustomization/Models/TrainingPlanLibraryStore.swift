import Foundation
import SwiftUI

/// 完整训练日课表结构体：支持保存到课表库并在主页随时切换选择
public struct TrainingRoutinePlan: Identifiable, Equatable, Codable {
    public var id: UUID
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

/// 训练日课表库管理器（全局共享，支持持久化保存到本地UserDefaults并在主页随时切换选择）
public class TrainingPlanLibraryStore: ObservableObject {
    public static let shared = TrainingPlanLibraryStore()
    
    private let plansUserDefaultsKey = "user_saved_training_plans_v2"
    private let activeIdUserDefaultsKey = "user_active_plan_id_v2"
    
    @Published public var savedPlans: [TrainingRoutinePlan] = []
    @Published public var activePlanId: UUID = UUID()
    
    public var activePlan: TrainingRoutinePlan {
        savedPlans.first(where: { $0.id == activePlanId }) ?? (savedPlans.first ?? TrainingRoutinePlan(name: "默认计划", notes: "", exercises: []))
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: plansUserDefaultsKey),
           let decoded = try? JSONDecoder().decode([TrainingRoutinePlan].self, from: data),
           !decoded.isEmpty {
            self.savedPlans = decoded
            if let idString = UserDefaults.standard.string(forKey: activeIdUserDefaultsKey),
               let uuid = UUID(uuidString: idString),
               decoded.contains(where: { $0.id == uuid }) {
                self.activePlanId = uuid
            } else {
                self.activePlanId = decoded[0].id
            }
        } else {
            self.resetToDefaultOfficialPlans()
        }
    }
    
    /// 从当前已标定的1324动作库中精选动作，一键加载/重置三大官方标准训练计划（推、拉、腿）
    public func resetToDefaultOfficialPlans() {
        let pushDay = TrainingRoutinePlan(
            name: "周一 | 推：胸肩三头",
            notes: "第一周：高容量冲击周 · 胸肩与三头轰炸区（已全量适配高精准度解剖标定）",
            exercises: [
                PlanExerciseItemMock(name: "杠铃平板卧推", sets: 4, reps: 10, targetWeightKg: 40.0, restSeconds: 90),
                PlanExerciseItemMock(name: "杠铃上斜卧推", sets: 4, reps: 12, targetWeightKg: 30.0, restSeconds: 90),
                PlanExerciseItemMock(name: "哑铃夹胸/飞鸟", sets: 4, reps: 15, targetWeightKg: 12.0, restSeconds: 60),
                PlanExerciseItemMock(name: "哑铃坐姿肩部推举", sets: 4, reps: 12, targetWeightKg: 16.0, restSeconds: 90),
                PlanExerciseItemMock(name: "哑铃站姿侧平举", sets: 4, reps: 15, targetWeightKg: 8.0, restSeconds: 60),
                PlanExerciseItemMock(name: "绳索下压", sets: 4, reps: 15, targetWeightKg: 25.0, restSeconds: 60),
                PlanExerciseItemMock(name: "杠铃仰卧三头肌伸展", sets: 3, reps: 12, targetWeightKg: 20.0, restSeconds: 60),
                PlanExerciseItemMock(name: "臂屈伸", sets: 3, reps: 12, targetWeightKg: 0.0, restSeconds: 60)
            ]
        )
        
        let pullDay = TrainingRoutinePlan(
            name: "周二 | 拉：背部二头",
            notes: "背部垂直/水平双轨主导区 · 肱二头肌立体充血区（已精准对应Y轴/Z轴动力学特征）",
            exercises: [
                PlanExerciseItemMock(name: "对握引体向上", sets: 4, reps: 8, targetWeightKg: 0.0, restSeconds: 90),
                PlanExerciseItemMock(name: "绳索高位下拉", sets: 4, reps: 10, targetWeightKg: 45.0, restSeconds: 90),
                PlanExerciseItemMock(name: "杠铃划船", sets: 4, reps: 10, targetWeightKg: 40.0, restSeconds: 90),
                PlanExerciseItemMock(name: "绳索坐姿划船", sets: 4, reps: 12, targetWeightKg: 45.0, restSeconds: 90),
                PlanExerciseItemMock(name: "高位下拉", sets: 3, reps: 15, targetWeightKg: 35.0, restSeconds: 60),
                PlanExerciseItemMock(name: "杠铃二头弯举", sets: 4, reps: 12, targetWeightKg: 25.0, restSeconds: 60),
                PlanExerciseItemMock(name: "哑铃二头交替弯举", sets: 3, reps: 12, targetWeightKg: 12.0, restSeconds: 60),
                PlanExerciseItemMock(name: "绳索锤式弯举", sets: 3, reps: 15, targetWeightKg: 20.0, restSeconds: 60)
            ]
        )
        
        let legDay = TrainingRoutinePlan(
            name: "周四 | 腿：臀腿下肢",
            notes: "下肢复合大重量深蹲硬拉 · 器械孤立高频收缩强化骨盆与膝关节控制",
            exercises: [
                PlanExerciseItemMock(name: "杠铃深蹲", sets: 4, reps: 8, targetWeightKg: 70.0, restSeconds: 120),
                PlanExerciseItemMock(name: "哑铃深蹲", sets: 4, reps: 12, targetWeightKg: 24.0, restSeconds: 90),
                PlanExerciseItemMock(name: "杠铃硬拉", sets: 4, reps: 10, targetWeightKg: 60.0, restSeconds: 90),
                PlanExerciseItemMock(name: "器械推举", sets: 4, reps: 10, targetWeightKg: 100.0, restSeconds: 90),
                PlanExerciseItemMock(name: "器械臂屈伸", sets: 4, reps: 12, targetWeightKg: 40.0, restSeconds: 60),
                PlanExerciseItemMock(name: "器械仰卧二头弯举", sets: 4, reps: 12, targetWeightKg: 35.0, restSeconds: 60),
                PlanExerciseItemMock(name: "绳索站姿提踵", sets: 4, reps: 15, targetWeightKg: 35.0, restSeconds: 60),
                PlanExerciseItemMock(name: "悬垂举腿", sets: 3, reps: 15, targetWeightKg: 0.0, restSeconds: 60)
            ]
        )
        
        self.savedPlans = [pushDay, pullDay, legDay]
        self.activePlanId = pushDay.id
        self.saveToUserDefaults()
        self.objectWillChange.send()
    }
    
    private func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedPlans) {
            UserDefaults.standard.set(encoded, forKey: plansUserDefaultsKey)
        }
        UserDefaults.standard.set(activePlanId.uuidString, forKey: activeIdUserDefaultsKey)
    }
    
    public func savePlan(_ plan: TrainingRoutinePlan) {
        if let idx = savedPlans.firstIndex(where: { $0.id == plan.id }) {
            savedPlans[idx] = plan
        } else {
            savedPlans.append(plan)
        }
        saveToUserDefaults()
        objectWillChange.send()
    }
    
    public func selectActivePlan(_ plan: TrainingRoutinePlan) {
        activePlanId = plan.id
        saveToUserDefaults()
        objectWillChange.send()
    }
    
    public func updateActivePlanExercise(_ exercise: PlanExerciseItemMock, at index: Int) {
        guard let planIdx = savedPlans.firstIndex(where: { $0.id == activePlanId }) else { return }
        guard index >= 0 && index < savedPlans[planIdx].exercises.count else { return }
        savedPlans[planIdx].exercises[index] = exercise
        saveToUserDefaults()
        objectWillChange.send()
    }
}
