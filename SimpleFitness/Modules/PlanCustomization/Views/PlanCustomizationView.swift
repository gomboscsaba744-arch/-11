import SwiftUI

public struct PlanCustomizationView: View {
    @State private var planName: String = "定制力量训练日"
    @State private var planNotes: String = "个性化定制课表"
    @State private var exercises: [PlanExerciseItemMock] = PlanMockData.sampleExercises
    @State private var showingExercisePicker: Bool = false
    @State private var exerciseToConfigure: ExerciseItemMock? = nil
    @State private var showingPlanOverviewModal: Bool = false
    @State private var saveToastMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("定制训练课表")
                                .font(.largeTitle)
                                .fontWeight(.black)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showingPlanOverviewModal = true
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("全量总览与快调")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(AppColors.pillBackground)
                                .foregroundColor(AppColors.accentBlue)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 8)
                        
                        HStack {
                            Text("课表名称与备注")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            Spacer()
                            Text("\(planName.count)/8 字")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(planName.count >= 8 ? .orange : AppColors.secondaryText)
                        }
                        
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
                            
                            TextField("简要备注...", text: $planNotes)
                                .padding()
                        }
                        .standardCardStyle()
                        
                        HStack {
                            Text("动作编排列表 (可拖拽排序)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Spacer()
                            
                            Button(action: {
                                showingExercisePicker = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("从动作库添加")
                                }
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.accentBlue)
                            }
                        }
                        
                        // 编排列表容器
                        VStack(spacing: 0) {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                                PlanExerciseRowView(item: item) {
                                    if index < exercises.count {
                                        withAnimation {
                                            _ = exercises.remove(at: index)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                if index < exercises.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .standardCardStyle()
                        
                        Spacer(minLength: 110)
                    }
                    .padding(.horizontal, 20)
                }
                .blur(radius: showingPlanOverviewModal ? 12 : 0)
                
                // 底部悬浮操作按钮区
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        // 1. 保存课表到训练日库
                        Button(action: {
                            let routine = TrainingRoutinePlan(name: planName, notes: planNotes, exercises: exercises)
                            TrainingPlanLibraryStore.shared.savePlan(routine)
                            showToast("成功添加到训练日课表库！")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.badge.plus")
                                Text("添加/保存至训练日课表库")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .foregroundColor(AppColors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.accentBlue, lineWidth: 1.5)
                            )
                        }
                        
                        // 2. 设为今日首选并开始训练
                        Button(action: {
                            let routine = TrainingRoutinePlan(name: planName, notes: planNotes, exercises: exercises)
                            TrainingPlanLibraryStore.shared.savePlan(routine)
                            TrainingPlanLibraryStore.shared.selectActivePlan(routine)
                            showToast("已设为今日活跃课表！在主页左上角也可自由切换")
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("保存并设为今日首选训练日")
                                    .fontWeight(.bold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.accentBlue)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                
                // 液态玻璃模糊总计划动作快捷微调浮层
                if showingPlanOverviewModal {
                    PlanOverviewGlassModalView(
                        exercises: $exercises,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPlanOverviewModal = false
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(200)
                }
                
                // Toast 提示
                if let msg = saveToastMessage {
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
                            .padding(.bottom, 150)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingExercisePicker) {
                ExerciseSelectionSheetView { selectedExercise in
                    // 选中动作后弹出详细参数配置窗口
                    exerciseToConfigure = selectedExercise
                }
            }
            .sheet(item: $exerciseToConfigure) { exercise in
                ExerciseConfigModalSheetView(exercise: exercise) { configuredItem in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        exercises.append(configuredItem)
                    }
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation { saveToastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { saveToastMessage = nil }
        }
    }
}

#Preview {
    PlanCustomizationView()
}
