import SwiftUI

/// 1. 训练日课表切换选择弹窗（主页左上角标题点击触发）
public struct TrainingRoutinePickerGlassModalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var libraryStore = TrainingPlanLibraryStore.shared
    public var onSelectRoutine: (TrainingRoutinePlan) -> Void
    
    public init(onSelectRoutine: @escaping (TrainingRoutinePlan) -> Void) {
        self.onSelectRoutine = onSelectRoutine
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(libraryStore.savedPlans) { plan in
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                onSelectRoutine(plan)
                                dismiss()
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(plan.id == libraryStore.activePlanId ? AppColors.accentBlue : AppColors.pillBackground)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: plan.id == libraryStore.activePlanId ? "checkmark" : "list.bullet.clipboard.fill")
                                            .font(.headline)
                                            .foregroundColor(plan.id == libraryStore.activePlanId ? .white : AppColors.accentBlue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.name)
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Text("共 \(plan.exercises.count) 个动作 · \(plan.notes)")
                                            .font(.caption)
                                            .foregroundColor(AppColors.secondaryText)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AppColors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(plan.id == libraryStore.activePlanId ? AppColors.accentBlue : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("切换训练计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primaryText.opacity(0.8))
                        }
                    }
                }
            }
        }
    }
}

/// 2. 动作总量展开列表模糊浮层（Apple 原生毛玻璃圆钮 + 高白透虚化）
public struct TrainingExerciseListGlassModalView: View {
    public let exercises: [PlanExerciseItemMock]
    public let currentIndex: Int
    public var onClose: () -> Void
    public var onSelectExerciseIndex: (Int) -> Void
    
    public init(
        exercises: [PlanExerciseItemMock],
        currentIndex: Int,
        onClose: @escaping () -> Void,
        onSelectExerciseIndex: @escaping (Int) -> Void
    ) {
        self.exercises = exercises
        self.currentIndex = currentIndex
        self.onClose = onClose
        self.onSelectExerciseIndex = onSelectExerciseIndex
    }
    
    public var body: some View {
        ZStack {
            Color.white.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    Text("计划明细")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Button(action: { onClose() }) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primaryText.opacity(0.8))
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                            let orderIndex = index + 1
                            let isCurrent = orderIndex == currentIndex
                            let isDone = orderIndex < currentIndex
                            
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                onSelectExerciseIndex(orderIndex)
                                onClose()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(isCurrent ? AppColors.accentBlue : (isDone ? Color.green : AppColors.pillBackground))
                                            .frame(width: 34, height: 34)
                                        
                                        if isDone {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(orderIndex)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(isCurrent ? .white : AppColors.primaryText)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .fontWeight(isCurrent ? .heavy : .bold)
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Text("\(item.sets)组 × \(item.reps)次 · \(String(format: "%.1f", item.targetWeightKg))kg")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(isCurrent ? "进行中" : (isDone ? "已完成" : "待训练"))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background((isCurrent ? AppColors.accentBlue : (isDone ? Color.green : Color.secondary)).opacity(0.12))
                                        .foregroundColor(isCurrent ? AppColors.accentBlue : (isDone ? Color.green : AppColors.secondaryText))
                                        .clipShape(Capsule())
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isCurrent ? AppColors.accentBlue.opacity(0.12) : Color.white.opacity(0.65))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(isCurrent ? AppColors.accentBlue : Color.clear, lineWidth: 1.5)
                                        )
                                )
                            }
                        }
                    }
                }
                .frame(maxHeight: 380)
            }
            .padding(22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.72)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 30, x: 0, y: 12)
            )
            .padding(.horizontal, 18)
        }
    }
}

/// 3. 当前动作组数明细展开模糊浮层 (支持每组独立调整次数)
public struct TrainingSetListGlassModalView: View {
    public let exerciseName: String
    public let totalSets: Int
    public let currentSet: Int
    public let targetWeightKg: Double
    public let targetReps: Int
    public var exerciseItem: PlanExerciseItemMock?
    public var onClose: () -> Void
    public var onSelectSet: (Int) -> Void
    public var onAdjustSetReps: ((Int, Int) -> Void)?
    
    public init(
        exerciseName: String,
        totalSets: Int,
        currentSet: Int,
        targetWeightKg: Double,
        targetReps: Int,
        exerciseItem: PlanExerciseItemMock? = nil,
        onClose: @escaping () -> Void,
        onSelectSet: @escaping (Int) -> Void,
        onAdjustSetReps: ((Int, Int) -> Void)? = nil
    ) {
        self.exerciseName = exerciseName
        self.totalSets = totalSets
        self.currentSet = currentSet
        self.targetWeightKg = targetWeightKg
        self.targetReps = targetReps
        self.exerciseItem = exerciseItem
        self.onClose = onClose
        self.onSelectSet = onSelectSet
        self.onAdjustSetReps = onAdjustSetReps
    }
    
    public var body: some View {
        ZStack {
            Color.white.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    Text("\(exerciseName) · 组数明细")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Button(action: { onClose() }) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primaryText.opacity(0.8))
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(1...max(1, totalSets), id: \.self) { setIdx in
                            let isCurrent = setIdx == currentSet
                            let isDone = setIdx < currentSet
                            let setReps = exerciseItem?.getTargetReps(forSet: setIdx) ?? targetReps
                            
                            HStack(spacing: 12) {
                                // 左侧区域：点击切换当前执行组数
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    onSelectSet(setIdx)
                                    onClose()
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(isCurrent ? AppColors.accentBlue : (isDone ? Color.green : AppColors.pillBackground))
                                                .frame(width: 34, height: 34)
                                            
                                            if isDone {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundColor(.white)
                                            } else {
                                                Text("\(setIdx)")
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(isCurrent ? .white : AppColors.primaryText)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("第 \(setIdx) 组")
                                                .font(.headline)
                                                .foregroundColor(AppColors.primaryText)
                                            
                                            Text("建议负重 \(String(format: "%.1f", targetWeightKg)) kg")
                                                .font(.caption)
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Spacer(minLength: 4)
                                
                                // 右侧高审美胶囊次数控制器 (Pill Stepper)
                                HStack(spacing: 0) {
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        if setReps > 1 {
                                            onAdjustSetReps?(setIdx, setReps - 1)
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(AppColors.primaryText)
                                            .frame(width: 28, height: 28)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(setReps) 次")
                                        .font(.subheadline.weight(.heavy))
                                        .foregroundColor(isCurrent ? AppColors.accentBlue : AppColors.primaryText)
                                        .frame(minWidth: 42)
                                        .monospacedDigit()
                                    
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        onAdjustSetReps?(setIdx, setReps + 1)
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(AppColors.primaryText)
                                            .frame(width: 28, height: 28)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.12))
                                )
                                
                                Text(isCurrent ? "当前" : (isDone ? "已完" : "待做"))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background((isCurrent ? AppColors.accentBlue : (isDone ? Color.green : Color.secondary)).opacity(0.12))
                                    .foregroundColor(isCurrent ? AppColors.accentBlue : (isDone ? Color.green : AppColors.secondaryText))
                                    .clipShape(Capsule())
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isCurrent ? AppColors.accentBlue.opacity(0.12) : Color.white.opacity(0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isCurrent ? AppColors.accentBlue : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
            .padding(22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.72)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 30, x: 0, y: 12)
            )
            .padding(.horizontal, 18)
        }
    }
}

/// 4. 课表定制页：总计划动作清单快速调整模糊浮层
public struct PlanOverviewGlassModalView: View {
    @Binding public var exercises: [PlanExerciseItemMock]
    public var onClose: () -> Void
    
    public init(exercises: Binding<[PlanExerciseItemMock]>, onClose: @escaping () -> Void) {
        self._exercises = exercises
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            Color.white.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    Text("课表动作微调")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Button(action: { onClose() }) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.18))
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.primaryText.opacity(0.8))
                        }
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach($exercises) { $item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.name)
                                        .font(.headline)
                                        .fontWeight(.heavy)
                                        .foregroundColor(AppColors.primaryText)
                                    Spacer()
                                    Button(action: {
                                        if let idx = exercises.firstIndex(where: { $0.id == item.id }) {
                                            withAnimation {
                                                _ = exercises.remove(at: idx)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.footnote)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 6) {
                                        Text("组数:")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.secondaryText)
                                        Stepper("\(item.sets)组", value: $item.sets, in: 1...20)
                                            .font(.caption.weight(.bold))
                                    }
                                    
                                    HStack(spacing: 6) {
                                        Text("次数:")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.secondaryText)
                                        Stepper("\(item.reps)次", value: $item.reps, in: 1...50)
                                            .font(.caption.weight(.bold))
                                    }
                                }
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 6) {
                                        Text("重量: \(String(format: "%.1f", item.targetWeightKg))kg")
                                            .font(.caption.weight(.bold))
                                        Spacer()
                                        Button("-5") { if item.targetWeightKg >= 5 { item.targetWeightKg -= 5 } }
                                            .buttonStyle(.bordered)
                                            .controlSize(.mini)
                                        Button("+5") { item.targetWeightKg += 5 }
                                            .buttonStyle(.bordered)
                                            .controlSize(.mini)
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.65))
                            )
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
            .padding(22)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.72)
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 30, x: 0, y: 12)
            )
            .padding(.horizontal, 18)
        }
    }
}
