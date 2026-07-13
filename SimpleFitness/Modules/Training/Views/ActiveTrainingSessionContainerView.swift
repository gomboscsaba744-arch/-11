import SwiftUI

public struct ActiveTrainingSessionContainerView: View {
    @Binding var session: TrainingSessionMock
    @Binding var restTimer: RestTimerModel
    @Binding var recordedReps: Int
    @Binding var isAutoFlowModeEnabled: Bool
    @Binding var isAutoBufferActive: Bool
    @Binding var autoBufferRemaining: Int
    @Binding var completedExerciseNotice: String?
    
    @Binding var showingExerciseListModal: Bool
    @Binding var showingSetListModal: Bool
    
    var currentRoutineExercises: [PlanExerciseItemMock]
    var onEndWorkout: () -> Void
    var onSelectRoutine: () -> Void
    var onCompleteSet: () -> Void
    var onPrevExercise: () -> Void
    var onNextExercise: () -> Void
    var onSwitchExercise: (Int) -> Void
    
    @ObservedObject private var libraryStore = TrainingPlanLibraryStore.shared
    
    public init(
        session: Binding<TrainingSessionMock>,
        restTimer: Binding<RestTimerModel>,
        recordedReps: Binding<Int>,
        isAutoFlowModeEnabled: Binding<Bool>,
        isAutoBufferActive: Binding<Bool>,
        autoBufferRemaining: Binding<Int>,
        completedExerciseNotice: Binding<String?>,
        showingExerciseListModal: Binding<Bool>,
        showingSetListModal: Binding<Bool>,
        currentRoutineExercises: [PlanExerciseItemMock],
        onEndWorkout: @escaping () -> Void,
        onSelectRoutine: @escaping () -> Void,
        onCompleteSet: @escaping () -> Void,
        onPrevExercise: @escaping () -> Void,
        onNextExercise: @escaping () -> Void,
        onSwitchExercise: @escaping (Int) -> Void
    ) {
        self._session = session
        self._restTimer = restTimer
        self._recordedReps = recordedReps
        self._isAutoFlowModeEnabled = isAutoFlowModeEnabled
        self._isAutoBufferActive = isAutoBufferActive
        self._autoBufferRemaining = autoBufferRemaining
        self._completedExerciseNotice = completedExerciseNotice
        self._showingExerciseListModal = showingExerciseListModal
        self._showingSetListModal = showingSetListModal
        self.currentRoutineExercises = currentRoutineExercises
        self.onEndWorkout = onEndWorkout
        self.onSelectRoutine = onSelectRoutine
        self.onCompleteSet = onCompleteSet
        self.onPrevExercise = onPrevExercise
        self.onNextExercise = onNextExercise
        self.onSwitchExercise = onSwitchExercise
    }
    
    public var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            // 顶部提示：完成动作横幅
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
            
            VStack(spacing: 0) {
                // 沉浸式顶栏：带有右上角二次确认结束运动
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("沉浸训练中 · 锁屏守护")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    Spacer()
                    Button(action: {
                        onEndWorkout()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("结束运动")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(Color.red)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 6)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // 1. 原样保留 Header 遥测组件
                        TrainingHeaderView(
                            session: session,
                            isRestPhase: restTimer.isRunning,
                            onSelectRoutine: onSelectRoutine,
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
                        
                        // 2. 原样保留 休息倒计时 / 计次打卡组件
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
                                        onCompleteSet()
                                    }
                                )
                                
                                TrainingActionButtonsView(
                                    currentSet: session.currentSet,
                                    onCompleteSet: { onCompleteSet() },
                                    onPrevExercise: { onPrevExercise() },
                                    onNextExercise: { onNextExercise() }
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
                                        onCompleteSet()
                                    }
                                )
                                
                                TrainingActionButtonsView(
                                    currentSet: session.currentSet,
                                    onCompleteSet: { onCompleteSet() },
                                    onPrevExercise: { onPrevExercise() },
                                    onNextExercise: { onNextExercise() }
                                )
                            }
                            
                            RestTimerCompactPreviewCardView(timerModel: $restTimer)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // 3. 原样保留 手表传感器卡片
                        WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
                }
                .blur(radius: restTimer.isPrecisionZoomed || showingExerciseListModal || showingSetListModal ? 12 : 0)
                .animation(.easeInOut(duration: 0.25), value: restTimer.isPrecisionZoomed)
            }
            
            // 悬浮表盘与圆盘弹窗
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
                        onSwitchExercise(newIdx)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(101)
            }
            
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
    }
}
