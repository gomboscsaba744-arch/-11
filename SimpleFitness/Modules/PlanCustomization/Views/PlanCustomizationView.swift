import SwiftUI

/// 课表定制页主视图：进入即展示全部训练总计划库；点击“新建/添加训练计划”或“编辑”进入独立编排子页面
public struct PlanCustomizationView: View {
    @ObservedObject private var libraryStore = TrainingPlanLibraryStore.shared
    @State private var showingCreatePlanSheet: Bool = false
    @State private var planToEdit: TrainingRoutinePlan? = nil
    @State private var toastMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // 标题与新建按钮
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("全部训练计划")
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                    .foregroundColor(AppColors.primaryText)
                                Text("管理并切换所有预设及自定义课表")
                                    .font(.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                showingCreatePlanSheet = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("新建计划")
                                        .font(.subheadline.weight(.bold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(AppColors.accentBlue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 8)
                        
                        // 计划列表卡片区域
                        VStack(spacing: 16) {
                            ForEach(libraryStore.savedPlans) { plan in
                                planOverviewCard(plan: plan)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Toast 提示
                if let msg = toastMessage {
                    VStack {
                        Spacer()
                        Text(msg)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Capsule())
                            .padding(.bottom, 40)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCreatePlanSheet) {
                PlanBuilderEditorSheetView(
                    existingPlan: nil,
                    onSave: { newPlan in
                        libraryStore.savePlan(newPlan)
                        showToast("已成功添加新计划：\(newPlan.name)")
                    }
                )
            }
            .sheet(item: $planToEdit) { plan in
                PlanBuilderEditorSheetView(
                    existingPlan: plan,
                    onSave: { updatedPlan in
                        libraryStore.savePlan(updatedPlan)
                        showToast("已更新计划：\(updatedPlan.name)")
                    }
                )
            }
        }
    }
    
    private func planOverviewCard(plan: TrainingRoutinePlan) -> some View {
        let isActive = (plan.id == libraryStore.activePlanId)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.black)
                            .foregroundColor(AppColors.primaryText)
                        
                        if isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                Text("今日活跃中")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text(plan.notes)
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
            
            // 动作快览小标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(plan.exercises, id: \.id) { ex in
                        HStack(spacing: 4) {
                            Text(ex.name)
                                .font(.caption2.weight(.bold))
                            Text("\(ex.sets)组x\(ex.reps)次")
                                .font(.caption2)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.pillBackground)
                        .cornerRadius(8)
                    }
                }
            }
            
            Divider()
            
            // 操作按键组
            HStack(spacing: 12) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    planToEdit = plan
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil.circle.fill")
                        Text("编辑课表与动作")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppColors.pillBackground)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    libraryStore.selectActivePlan(plan)
                    showToast("已切换今日活跃计划为「\(plan.name)」")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isActive ? "checkmark.circle.fill" : "play.circle.fill")
                        Text(isActive ? "当前首选" : "设为今日训练")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundColor(isActive ? .white : AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(isActive ? Color.orange : AppColors.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive ? Color.clear : AppColors.accentBlue, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(18)
        .standardCardStyle()
    }
    
    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - 新建 / 编辑计划副页 (独立窗口，无需全量总览按钮，每行动作自带编辑键)
public struct PlanBuilderEditorSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let existingPlan: TrainingRoutinePlan?
    let onSave: (TrainingRoutinePlan) -> Void
    
    @State private var planName: String = ""
    @State private var planNotes: String = ""
    @State private var exercises: [PlanExerciseItemMock] = []
    
    @State private var showingExercisePicker: Bool = false
    @State private var exerciseToConfigureFromPicker: ExerciseItemMock? = nil
    @State private var editingExerciseIndex: Int? = nil
    
    public init(existingPlan: TrainingRoutinePlan?, onSave: @escaping (TrainingRoutinePlan) -> Void) {
        self.existingPlan = existingPlan
        self.onSave = onSave
        self._planName = State(initialValue: existingPlan?.name ?? "定制力量训练日")
        self._planNotes = State(initialValue: existingPlan?.notes ?? "个性化定制课表")
        self._exercises = State(initialValue: existingPlan?.exercises ?? PlanMockData.sampleExercises)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("名称与备注")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            Spacer()
                            Text("\(planName.count)/8 字")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(planName.count >= 8 ? .orange : AppColors.secondaryText)
                        }
                        .padding(.top, 8)
                        
                        // 名称与备注输入卡片
                        VStack(spacing: 0) {
                            TextField("例如：胸三头强化日 (限8字)", text: $planName)
                                .padding()
                                .onChange(of: planName) { _, newValue in
                                    if newValue.count > 8 {
                                        planName = String(newValue.prefix(8))
                                    }
                                }
                            
                            Divider()
                                .padding(.horizontal)
                            
                            TextField("简要备注说明...", text: $planNotes)
                                .padding()
                        }
                        .standardCardStyle()
                        
                        HStack {
                            Text("动作编排 (单卡支持直接编辑参数)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                showingExercisePicker = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("新增动作")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(AppColors.accentBlue)
                            }
                        }
                        
                        // 动作编排列表卡片
                        VStack(spacing: 0) {
                            if exercises.isEmpty {
                                Text("当前暂无动作，点击右上角“新增动作”添加")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(24)
                            } else {
                                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                                    PlanExerciseRowView(
                                        item: item,
                                        onEdit: {
                                            editingExerciseIndex = index
                                        },
                                        onDelete: {
                                            if index < exercises.count {
                                                withAnimation {
                                                    _ = exercises.remove(at: index)
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    
                                    if index < exercises.count - 1 {
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                        }
                        .standardCardStyle()
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle(existingPlan == nil ? "新建训练计划" : "编辑训练计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.secondaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成保存") {
                        let targetId = existingPlan?.id ?? UUID()
                        let plan = TrainingRoutinePlan(id: targetId, name: planName, notes: planNotes, exercises: exercises)
                        onSave(plan)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.accentBlue)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExerciseSelectionSheetView { selectedExercise in
                    exerciseToConfigureFromPicker = selectedExercise
                }
            }
            .sheet(item: $exerciseToConfigureFromPicker) { exercise in
                ExerciseConfigModalSheetView(exercise: exercise) { configuredItem in
                    withAnimation {
                        exercises.append(configuredItem)
                    }
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { editingExerciseIndex != nil },
                set: { if !$0 { editingExerciseIndex = nil } }
            )) {
                if let idx = editingExerciseIndex, idx < exercises.count {
                    ExerciseConfigModalSheetView(existingItem: exercises[idx]) { updatedItem in
                        withAnimation {
                            exercises[idx] = updatedItem
                        }
                        editingExerciseIndex = nil
                    }
                }
            }
        }
    }
}

#Preview {
    PlanCustomizationView()
}

#Preview {
    PlanCustomizationView()
}
