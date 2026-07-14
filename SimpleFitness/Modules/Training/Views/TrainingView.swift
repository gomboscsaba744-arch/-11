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
    @State private var isWorkoutActive: Bool = false
    @State private var elapsedTrainingSeconds: Int = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            TrainingHomeDashboardView(
                session: session,
                currentRoutineExercises: currentRoutineExercises,
                onStartWorkout: {
                    session.currentCalories = 0
                    elapsedTrainingSeconds = 0
                    watchService.activeEnergyBurnedKcal = 0
                    withAnimation { isWorkoutActive = true }
                    watchService.startWatchWorkoutSession(exerciseTitle: session.exerciseName)
                },
                onSelectRoutine: {
                    showingRoutinePicker = true
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isWorkoutActive) {
                ActiveTrainingSessionContainerView(
                    session: $session,
                    restTimer: $restTimer,
                    recordedReps: $recordedReps,
                    isAutoFlowModeEnabled: $isAutoFlowModeEnabled,
                    isAutoBufferActive: $isAutoBufferActive,
                    autoBufferRemaining: $autoBufferRemaining,
                    completedExerciseNotice: $completedExerciseNotice,
                    showingExerciseListModal: $showingExerciseListModal,
                    showingSetListModal: $showingSetListModal,
                    currentRoutineExercises: currentRoutineExercises,
                    onEndWorkout: {
                        withAnimation {
                            isWorkoutActive = false
                            restTimer.reset()
                        }
                        watchService.endWatchWorkoutSession()
                    },
                    onSelectRoutine: {
                        showingRoutinePicker = true
                    },
                    onCompleteSet: {
                        completeCurrentSet()
                    },
                    onPrevExercise: {
                        prevExercise()
                    },
                    onNextExercise: {
                        nextExercise()
                    },
                    onSwitchExercise: { newIdx in
                        switchToExercise(at: newIdx)
                    }
                )
                .interactiveDismissDisabled(true)
            }
            .sheet(isPresented: $showingRoutinePicker) {
                TrainingRoutinePickerGlassModalView { selectedRoutine in
                    switchRoutine(selectedRoutine)
                }
            }
            .onAppear {
                syncSessionWithActivePlan()
            }
            .onReceive(watchService.$currentHeartRate) { hr in
                if hr > 0 {
                    session.currentHeartRate = hr
                }
            }
            .onReceive(watchService.$activeEnergyBurnedKcal) { kcal in
                if kcal > 0 {
                    session.currentCalories = kcal
                }
            }
            .onReceive(watchService.$syncedIsResting) { resting in
                if resting {
                    restTimer.totalDuration = watchService.syncedRestSeconds
                    restTimer.remainingTime = Double(watchService.syncedRestSeconds)
                    restTimer.start()
                } else {
                    restTimer.reset()
                }
            }
            .onReceive(watchService.$syncedExerciseIndex) { index in
                guard index != session.currentExerciseIndex else { return }
                session.currentExerciseIndex = index
                syncSessionWithActivePlan()
            }
            .onReceive(watchService.$syncedCurrentSet) { set in
                guard set != session.currentSet, set >= 1 else { return }
                session.currentSet = set
            }
            .onReceive(watchService.$syncedTotalSets) { total in
                guard total != session.totalSets, total >= 1 else { return }
                session.totalSets = total
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
            .onChange(of: session.currentSet) { _, _ in
                syncStateToWatch()
            }
            .onChange(of: session.currentExerciseIndex) { _, _ in
                syncStateToWatch()
            }
            .onChange(of: watchService.syncedIsWorkoutStarted) { started in
                if started && !isWorkoutActive {
                    session.currentCalories = 0
                    elapsedTrainingSeconds = 0
                    watchService.activeEnergyBurnedKcal = 0
                    withAnimation { isWorkoutActive = true }
                }
            }
            .onChange(of: watchService.syncedIsWorkoutEnded) { ended in
                if ended && isWorkoutActive {
                    withAnimation {
                        isWorkoutActive = false
                        restTimer.reset()
                    }
                }
            }
            .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                elapsedTrainingSeconds += 1
                if watchService.activeEnergyBurnedKcal > 0 {
                    session.currentCalories = watchService.activeEnergyBurnedKcal
                } else {
                    session.currentCalories = Int(Double(elapsedTrainingSeconds) * 0.125)
                }
                
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
    
    private func syncStateToWatch() {
        watchService.syncWorkoutStateToWatch(
            exerciseName: session.exerciseName,
            currentSet: session.currentSet,
            totalSets: session.totalSets,
            targetReps: session.currentReps,
            targetWeightKg: session.targetWeightKg,
            isResting: restTimer.isRunning
        )
    }
}
