import SwiftUI
import Combine

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
    
    // 左右滑动分页选择 (0: 极致核心训练主页, 1: 数据监测与计划明细页)
    @State private var selectedPageIndex: Int = 0
    
    // 进场准备倒计时 3 -> 2 -> 1 -> GO!
    @State private var isPrepCountdownActive: Bool = true
    @State private var prepCountdownValue: Int = 3
    @State private var prepTimerSubscription: AnyCancellable? = nil
    
    // 长按结束运动进度 (0.0 ~ 1.0)
    @State private var holdToEndProgress: CGFloat = 0.0
    @State private var isHoldingToEnd: Bool = false
    @State private var holdTimerSubscription: AnyCancellable? = nil
    
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
            
            VStack(spacing: 0) {
                topMinimalStatusBar()
                
                TabView(selection: $selectedPageIndex) {
                    coreMinimalWorkoutPage()
                        .tag(0)
                    
                    detailsAndTelemetryPage()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                pageIndicatorAndHoldToEndBar()
            }
            .blur(radius: isPrepCountdownActive ? 16 : 0)
            
            // 顶部横幅提示：动作完成进阶
            completionNoticeOverlay()
            
            // 悬浮放大表盘与圆盘弹窗
            modalsAndFloatingDialsOverlay()
            
            // 进场 3 2 1 GO! 倒计时全屏遮罩
            if isPrepCountdownActive {
                prepCountdownOverlay()
                    .zIndex(300)
                    .transition(.opacity)
            }
        }
        .onAppear {
            startPrepCountdown()
        }
        .onDisappear {
            prepTimerSubscription?.cancel()
            holdTimerSubscription?.cancel()
        }
    }
    
    // MARK: - 极简顶栏状态栏 (无突兀结束按钮)
    @ViewBuilder
    private func topMinimalStatusBar() -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text(selectedPageIndex == 0 ? "专注训练页 · 左右滑动看数据" : "手表传感器遥测 · 计划明细")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 11))
                Text("左右滑动切换")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(AppColors.secondaryText.opacity(0.8))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.05))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
    
    // MARK: - Page 0: 绝对精简的核心训练页 (绝对不杂乱)
    @ViewBuilder
    private func coreMinimalWorkoutPage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
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
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
        }
    }
    
    // MARK: - Page 1: 次要信息滑动展示页 (手表遥测 & 计划全览)
    @ViewBuilder
    private func detailsAndTelemetryPage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("全场动作一览")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(AppColors.primaryText)
                        Spacer()
                        Text("共 \(currentRoutineExercises.count) 个动作")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(Array(currentRoutineExercises.enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(index + 1 == session.currentExerciseIndex ? Color.green : Color.black.opacity(0.06))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(index + 1 == session.currentExerciseIndex ? .white : AppColors.primaryText)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppColors.primaryText)
                                    Text("\(item.sets) 组 · 约 \(item.reps) 次")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                Spacer()
                                Text("\(Int(item.targetWeightKg)) kg")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(AppColors.primaryText)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.75))
                            )
                        }
                    }
                }
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - 底部指示点与长按结束按钮
    @ViewBuilder
    private func pageIndicatorAndHoldToEndBar() -> some View {
        VStack(spacing: 10) {
            // 分页圆点指示
            HStack(spacing: 8) {
                Circle()
                    .fill(selectedPageIndex == 0 ? AppColors.primaryText : Color.black.opacity(0.2))
                    .frame(width: 7, height: 7)
                Circle()
                    .fill(selectedPageIndex == 1 ? AppColors.primaryText : Color.black.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
            
            // 长按结束按钮 (Hold to End Workout)
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.red.opacity(0.12))
                
                // 红色进度填充
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.red.opacity(0.75))
                        .frame(width: geo.size.width * holdToEndProgress)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: isHoldingToEnd ? "hand.tap.fill" : "lock.open.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(isHoldingToEnd ? "正在长按解锁结束..." : "长按此键 1.8 秒结束当前训练")
                        .font(.system(size: 14, weight: .heavy))
                }
                .foregroundColor(holdToEndProgress > 0.45 ? .white : Color.red)
            }
            .frame(height: 48)
            .padding(.horizontal, 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHoldingToEnd {
                            startHoldToEndTimer()
                        }
                    }
                    .onEnded { _ in
                        cancelHoldToEndTimer()
                    }
            )
        }
        .padding(.bottom, 20)
        .background(
            Color.white.opacity(0.85)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - 横幅与弹窗等叠加层
    @ViewBuilder
    private func completionNoticeOverlay() -> some View {
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
    }
    
    @ViewBuilder
    private func modalsAndFloatingDialsOverlay() -> some View {
        ZStack {
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
    
    // MARK: - 3 2 1 GO 准备倒计时全屏遮罩
    @ViewBuilder
    private func prepCountdownOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("准备就绪 · 开启沉浸训练")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 180, height: 180)
                    
                    Text(prepCountdownValue > 0 ? "\(prepCountdownValue)" : "GO!")
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .foregroundColor(prepCountdownValue > 0 ? .white : .green)
                        .scaleEffect(prepCountdownValue > 0 ? 1.0 : 1.2)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: prepCountdownValue)
                }
            }
        }
    }
    
    // MARK: - 计时器控制逻辑
    private func startPrepCountdown() {
        prepCountdownValue = 3
        isPrepCountdownActive = true
        prepTimerSubscription?.cancel()
        prepTimerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if prepCountdownValue > 1 {
                    withAnimation {
                        prepCountdownValue -= 1
                    }
                } else if prepCountdownValue == 1 {
                    withAnimation {
                        prepCountdownValue = 0
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPrepCountdownActive = false
                    }
                    prepTimerSubscription?.cancel()
                }
            }
    }
    
    private func startHoldToEndTimer() {
        isHoldingToEnd = true
        holdToEndProgress = 0.0
        holdTimerSubscription?.cancel()
        
        // 经过 1.8 秒完成长按结束
        let tick: CGFloat = 0.05 / 1.8
        holdTimerSubscription = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                withAnimation(.linear(duration: 0.05)) {
                    holdToEndProgress = min(1.0, holdToEndProgress + tick)
                }
                if holdToEndProgress >= 1.0 {
                    holdTimerSubscription?.cancel()
                    isHoldingToEnd = false
                    onEndWorkout()
                }
            }
    }
    
    private func cancelHoldToEndTimer() {
        holdTimerSubscription?.cancel()
        isHoldingToEnd = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            holdToEndProgress = 0.0
        }
    }
}
