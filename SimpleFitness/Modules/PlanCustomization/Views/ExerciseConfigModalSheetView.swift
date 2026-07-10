import SwiftUI

/// 动作参数自定义弹窗：在将动作库选中的动作加入课表前，让用户手动设定具体组数、推荐次数、目标负重与组间休息时长
public struct ExerciseConfigModalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseItemMock
    let onConfirm: (PlanExerciseItemMock) -> Void
    
    @State private var sets: Int = 4
    @State private var reps: Int = 12
    @State private var weight: Double = 30.0
    @State private var restSeconds: Int = 90
    @State private var exerciseRestSeconds: Int = 120
    @State private var customRepsPerSet: [Int: Int] = [:]
    
    private let restOptions = [45, 60, 90, 120, 180]
    private let exerciseRestOptions = [60, 90, 120, 180, 240]
    
    public init(exercise: ExerciseItemMock, onConfirm: @escaping (PlanExerciseItemMock) -> Void) {
        self.exercise = exercise
        self.onConfirm = onConfirm
        self._restSeconds = State(initialValue: exercise.restSeconds)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部动作概要卡片
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.accentBlue.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Text(exercise.badgeLetter)
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.primaryText)
                                Text(exercise.category)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.pillBackground)
                                    .foregroundColor(AppColors.secondaryText)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        // 1. 组数配置卡片
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("计划组数 (Sets)")
                                    .font(.headline)
                                Spacer()
                                Text("\(sets) 组")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            Stepper("设定组数", value: $sets, in: 1...15)
                                .labelsHidden()
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        // 2. 每组次数配置卡片
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("目标次数 (Reps / 组)")
                                    .font(.headline)
                                Spacer()
                                Text("\(reps) 次")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            Stepper("设定次数", value: $reps, in: 1...50)
                                .labelsHidden()
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        // 2.1 各组独立定制次数卡片
                        if sets > 1 {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("各组次数独立定制")
                                            .font(.headline)
                                        Text("可为每一组单独调整目标次数")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    Spacer()
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(1...sets, id: \.self) { setIdx in
                                        let currentSetReps = customRepsPerSet[setIdx] ?? reps
                                        HStack {
                                            Text("第 \(setIdx) 组")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(AppColors.primaryText)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 0) {
                                                Button(action: {
                                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                                    impact.impactOccurred()
                                                    if currentSetReps > 1 {
                                                        customRepsPerSet[setIdx] = currentSetReps - 1
                                                    }
                                                }) {
                                                    Image(systemName: "minus")
                                                        .font(.system(size: 11, weight: .heavy))
                                                        .foregroundColor(AppColors.primaryText)
                                                        .frame(width: 28, height: 28)
                                                        .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                
                                                Text("\(currentSetReps) 次")
                                                    .font(.subheadline.weight(.heavy))
                                                    .foregroundColor(AppColors.accentBlue)
                                                    .frame(minWidth: 42)
                                                    .monospacedDigit()
                                                
                                                Button(action: {
                                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                                    impact.impactOccurred()
                                                    customRepsPerSet[setIdx] = currentSetReps + 1
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
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.secondary.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(16)
                            .standardCardStyle()
                        }
                        
                        // 3. 目标负重配置卡片
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("建议负重 (Weight)")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.1f kg", weight))
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(AppColors.accentBlue)
                            }
                            HStack(spacing: 12) {
                                Button("- 2.5 kg") {
                                    if weight >= 2.5 { weight -= 2.5 }
                                }
                                .buttonStyle(.bordered)
                                
                                Slider(value: $weight, in: 0...200, step: 2.5)
                                
                                Button("+ 2.5 kg") {
                                    if weight <= 197.5 { weight += 2.5 }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        // 4. 组间休息时长卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text("组间休息时长 (Set Rest)")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(restOptions, id: \.self) { sec in
                                    Button(action: {
                                        restSeconds = sec
                                    }) {
                                        Text("\(sec)秒")
                                            .font(.subheadline)
                                            .fontWeight(restSeconds == sec ? .bold : .medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(restSeconds == sec ? AppColors.accentBlue : AppColors.pillBackground)
                                            .foregroundColor(restSeconds == sec ? .white : AppColors.primaryText)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        // 5. 动作间切换休息时长卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text("动作切换后休息 (Exercise Rest)")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(exerciseRestOptions, id: \.self) { sec in
                                    Button(action: {
                                        exerciseRestSeconds = sec
                                    }) {
                                        Text("\(sec)秒")
                                            .font(.subheadline)
                                            .fontWeight(exerciseRestSeconds == sec ? .bold : .medium)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(exerciseRestSeconds == sec ? Color.orange : AppColors.pillBackground)
                                            .foregroundColor(exerciseRestSeconds == sec ? .white : AppColors.primaryText)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .standardCardStyle()
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                
                // 底部确定按钮
                VStack {
                    Spacer()
                    Button(action: {
                        let configuredItem = PlanExerciseItemMock(
                            name: exercise.name,
                            sets: sets,
                            reps: reps,
                            targetWeightKg: weight,
                            restSeconds: restSeconds,
                            exerciseRestSeconds: exerciseRestSeconds,
                            customRepsPerSet: customRepsPerSet
                        )
                        onConfirm(configuredItem)
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("确认参数并添至当次课表")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentBlue)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("动作训练参数配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.accentBlue)
                }
            }
        }
    }
}
