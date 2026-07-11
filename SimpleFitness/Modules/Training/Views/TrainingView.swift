import SwiftUI

public struct TrainingView: View {
    @ObservedObject private var libraryStore = TrainingPlanLibraryStore.shared
    @ObservedObject private var watchService = WatchConnectivityService.shared
    @State private var session = TrainingSessionMock()
    @State private var restTimer = RestTimerModel(defaultDuration: 90)
    
    // 弹窗与通知提示状态
    @State private var showingRoutinePicker: Bool = false
    @State private var showingExerciseListModal: Bool = false
    @State private var showingSetListModal: Bool = false
    @State private var completedExerciseNotice: String? = nil
    
    // Watch计次与自动流转状态
    @State private var recordedReps: Int = 0
    @AppStorage("isAutoFlowModeEnabled") private var isAutoFlowModeEnabled: Bool = true
    @AppStorage("autoRestBufferSeconds") private var autoRestBufferSeconds: Int = 10
    @State private var isAutoBufferActive: Bool = false
    @State private var autoBufferRemaining: Int = 10
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                // 自动进阶提示顶部横幅提示 (防止多做动作)
                if let notice = completedExerciseNotice {
                    VStack {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 34, height: 34)
                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("动作完成 · 自动进阶")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color.green)
                                Text(notice)
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundColor(AppColors.primaryText)
                            }
                            Spacer()
                            Button(action: {
                                withAnimation { completedExerciseNotice = nil }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 26, height: 26)
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
                                        .frame(width: 26, height: 26)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppColors.primaryText.opacity(0.85))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.85))
                            }
                            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.green.opacity(0.45), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                        Spacer()
                    }
                    .zIndex(200)
                }
                
                // 主体训练内容
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        TrainingHeaderView(
                            session: session,
                            isRestPhase: restTimer.isRunning,
                            onSelectRoutine: {
                                showingRoutinePicker = true
                            },
                            onTapExerciseListModal: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showingExerciseListModal = true
                                }
                            },
                            onTapSetListModal: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showingSetListModal = true
                                }
                            }
                        )
                        .padding(.top, 8)
                        
                        if restTimer.isRunning || restTimer.isPaused {
                            RestTimerCardView(timerModel: $restTimer)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            
                            VStack(spacing: 14) {
                                RepCounterCardView(
                                    recordedReps: $recordedReps,
                                    targetReps: $session.currentReps,
                                    isAutoMode: $isAutoFlowModeEnabled,
                                    isBufferActive: isAutoBufferActive,
                                    bufferRemaining: autoBufferRemaining,
                                    onCancelBuffer: {
                                        withAnimation {
                                            isAutoBufferActive = false
                                            isAutoFlowModeEnabled = false
                                        }
                                    },
                                    onImmediateRest: {
                                        isAutoBufferActive = false
                                        completeCurrentSet()
                                    }
                                )
                                
                                TrainingActionButtonsView(
                                    currentSet: session.currentSet,
                                    onCompleteSet: { completeCurrentSet() },
                                    onPrevExercise: { prevExercise() },
                                    onNextExercise: { nextExercise() }
                                )
                            }
                        } else {
                            VStack(spacing: 14) {
                                RepCounterCardView(
                                    recordedReps: $recordedReps,
                                    targetReps: $session.currentReps,
                                    isAutoMode: $isAutoFlowModeEnabled,
                                    isBufferActive: isAutoBufferActive,
                                    bufferRemaining: autoBufferRemaining,
                                    onCancelBuffer: {
                                        withAnimation {
                                            isAutoBufferActive = false
                                            isAutoFlowModeEnabled = false
                                        }
                                    },
                                    onImmediateRest: {
                                        isAutoBufferActive = false
                                        completeCurrentSet()
                                    }
                                )
                                
                                TrainingActionButtonsView(
                                    currentSet: session.currentSet,
                                    onCompleteSet: { completeCurrentSet() },
                                    onPrevExercise: { prevExercise() },
                                    onNextExercise: { nextExercise() }
                                )
                            }
                            
                            RestTimerCompactPreviewCardView(timerModel: $restTimer)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
                }
                .blur(radius: restTimer.isPrecisionZoomed || showingExerciseListModal || showingSetListModal ? 12 : 0)
                .animation(.easeInOut(duration: 0.25), value: restTimer.isPrecisionZoomed)
                
                // 1. 巨型无边界悬浮倒计时表盘（高阶清爽白色调磨砂感，全底模糊背景）
                if restTimer.isPrecisionZoomed {
                    Color.white.opacity(0.32)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                restTimer.isPrecisionZoomed = false
                            }
                        }
                    
                    GiantFloatingTimerDialView(timerModel: $restTimer)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .zIndex(100)
                }
                
                // 2. 动作列表圆盘式模糊遮罩弹窗
                if showingExerciseListModal {
                    TrainingExerciseListGlassModalView(
                        exercises: currentRoutineExercises,
                        currentIndex: session.currentExerciseIndex,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingExerciseListModal = false
                            }
                        },
                        onSelectExerciseIndex: { newIdx in
                            switchToExercise(at: newIdx)
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(101)
                }
                
                // 3. 当前动作组数明细圆盘式模糊遮罩弹窗
                if showingSetListModal {
                    let exercises = currentRoutineExercises
                    let idx = max(0, min(exercises.count - 1, session.currentExerciseIndex - 1))
                    let activeItem = idx < exercises.count ? exercises[idx] : nil
                    
                    TrainingSetListGlassModalView(
                        exerciseName: session.exerciseName,
                        totalSets: session.totalSets,
                        currentSet: session.currentSet,
                        targetWeightKg: session.targetWeightKg,
                        targetReps: session.currentReps,
                        exerciseItem: activeItem,
                        onClose: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingSetListModal = false
                            }
                        },
                        onSelectSet: { targetSet in
                            withAnimation {
                                session.currentSet = targetSet
                                if let item = activeItem {
                                    session.currentReps = item.getTargetReps(forSet: targetSet)
                                }
                            }
                        },
                        onAdjustSetReps: { setNum, newReps in
                            guard var item = activeItem else { return }
                            item.setTargetReps(newReps, forSet: setNum)
                            libraryStore.updateActivePlanExercise(item, at: idx)
                            if setNum == session.currentSet {
                                session.currentReps = newReps
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(102)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingRoutinePicker) {
                TrainingRoutinePickerGlassModalView { selectedRoutine in
                    switchRoutine(selectedRoutine)
                }
            }
            .onAppear {
                syncSessionWithActivePlan()
            }
            .onReceive(watchService.$currentHeartRate) { hr in
                session.currentHeartRate = hr
            }
            .onReceive(watchService.$activeEnergyBurnedKcal) { kcal in
                session.currentCalories = kcal
            }
            .onReceive(watchService.$detectedRepCount) { rep in
                session.watchTelemetry.detectedRepCount = rep
            }
            .onReceive(watchService.$repConfidence) { conf in
                session.watchTelemetry.repDetectionConfidence = conf
            }
            .onReceive(watchService.$gyroAmplitude) { gyro in
                session.watchTelemetry.gyroscopeAmplitudeDegPerSec = gyro
            }
            .onReceive(watchService.$isWatchReachable) { connected in
                session.watchTelemetry.isWatchConnected = connected
            }
            .onChange(of: session.currentReps) { _, newReps in
                let exercises = currentRoutineExercises
                let idx = max(0, min(exercises.count - 1, session.currentExerciseIndex - 1))
                guard idx < exercises.count else { return }
                var item = exercises[idx]
                if item.getTargetReps(forSet: session.currentSet) != newReps {
                    item.setTargetReps(newReps, forSet: session.currentSet)
                    libraryStore.updateActivePlanExercise(item, at: idx)
                }
            }
            .onChange(of: recordedReps) { _, newCount in
                if newCount >= session.currentReps && session.currentReps > 0 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    if isAutoFlowModeEnabled && !(restTimer.isRunning || restTimer.isPaused) {
                        autoBufferRemaining = autoRestBufferSeconds
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            isAutoBufferActive = true
                        }
                    }
                } else {
                    if isAutoBufferActive {
                        withAnimation { isAutoBufferActive = false }
                    }
                }
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                if isAutoBufferActive {
                    if autoBufferRemaining > 1 {
                        autoBufferRemaining -= 1
                    } else {
                        isAutoBufferActive = false
                        completeCurrentSet()
                    }
                }
                // 监听倒计时是否结束：倒计时结束自动进入下一组计数打卡模式，归零次计次
                if !restTimer.isRunning && !restTimer.isPaused && restTimer.remainingTime == 0 {
                    recordedReps = 0
                }
            }
        }
    }
    
    // 当前计划中的全部动作数据
    private var currentRoutineExercises: [PlanExerciseItemMock] {
        libraryStore.activePlan.exercises
    }
    
    private func syncSessionWithActivePlan() {
        let active = libraryStore.activePlan
        session.workoutTitle = active.name
        session.totalExercises = max(1, active.exercises.count)
        if session.currentExerciseIndex > session.totalExercises {
            session.currentExerciseIndex = 1
        }
        updateExerciseDetails()
    }
    
    private func switchRoutine(_ routine: TrainingRoutinePlan) {
        libraryStore.selectActivePlan(routine)
        session.workoutTitle = routine.name
        session.totalExercises = max(1, routine.exercises.count)
        session.currentExerciseIndex = 1
        session.currentSet = 1
        updateExerciseDetails()
    }
    
    private func completeCurrentSet() {
        recordedReps = 0
        isAutoBufferActive = false
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        
        let exercises = currentRoutineExercises
        let idx = max(0, min(exercises.count - 1, session.currentExerciseIndex - 1))
        guard idx < exercises.count else { return }
        
        // 记录当组次数
        var currentItem = exercises[idx]
        currentItem.setTargetReps(session.currentReps, forSet: session.currentSet)
        libraryStore.updateActivePlanExercise(currentItem, at: idx)
        
        if session.currentSet < session.totalSets {
            session.currentSet += 1
            session.currentReps = currentItem.getTargetReps(forSet: session.currentSet)
            restTimer.defaultDuration = currentItem.restSeconds
            restTimer.totalDuration = currentItem.restSeconds
            restTimer.isExerciseRestPhase = false
            restTimer.nextExerciseTitle = nil
            restTimer.reset()
            restTimer.start()
        } else {
            // 已完成当前动作最后一组：自动切换至下一动作并出明显提示，避免误多做
            let oldName = session.exerciseName
            if session.currentExerciseIndex < session.totalExercises {
                session.currentExerciseIndex += 1
                session.currentSet = 1
                updateExerciseDetails()
                
                restTimer.defaultDuration = currentItem.exerciseRestSeconds
                restTimer.totalDuration = currentItem.exerciseRestSeconds
                restTimer.isExerciseRestPhase = true
                restTimer.nextExerciseTitle = session.exerciseName
                restTimer.reset()
                restTimer.start()
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    completedExerciseNotice = "已完成「\(oldName)」！自动进入新动作：\(session.exerciseName)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    withAnimation { completedExerciseNotice = nil }
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    completedExerciseNotice = "恭喜！今日训练计划所有动作已通关打卡！"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation { completedExerciseNotice = nil }
                }
            }
        }
    }
    
    private func prevExercise() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        if session.currentExerciseIndex > 1 {
            session.currentExerciseIndex -= 1
            session.currentSet = 1
            updateExerciseDetails()
        }
    }
    
    private func nextExercise() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        if session.currentExerciseIndex < session.totalExercises {
            session.currentExerciseIndex += 1
            session.currentSet = 1
            updateExerciseDetails()
        }
    }
    
    private func switchToExercise(at index: Int) {
        guard index >= 1 && index <= session.totalExercises else { return }
        session.currentExerciseIndex = index
        session.currentSet = 1
        updateExerciseDetails()
    }
    
    private func updateExerciseDetails() {
        recordedReps = 0
        isAutoBufferActive = false
        
        let exercises = currentRoutineExercises
        let idx = max(0, min(exercises.count - 1, session.currentExerciseIndex - 1))
        guard idx < exercises.count else { return }
        let currentItem = exercises[idx]
        session.exerciseName = currentItem.name
        session.totalSets = currentItem.sets
        session.targetWeightKg = currentItem.targetWeightKg
        session.currentReps = currentItem.getTargetReps(forSet: session.currentSet)
        restTimer.defaultDuration = currentItem.restSeconds
        restTimer.totalDuration = currentItem.restSeconds
        restTimer.remainingTime = Double(currentItem.restSeconds)
        
        watchService.syncWorkoutStateToWatch(
            exerciseName: currentItem.name,
            currentSet: session.currentSet,
            totalSets: currentItem.sets,
            targetReps: session.currentReps,
            targetWeightKg: currentItem.targetWeightKg,
            isResting: restTimer.isRunning
        )
    }
}
