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
    
    // 左右滑动分页选择 (0: 专注打卡主视角, 1: 监测遥测与全部动作计划)
    @State private var selectedPageIndex: Int = 0
    
    // 进场仪式感准备倒计时 3 -> 2 -> 1 -> GO!
    @State private var isPrepCountdownActive: Bool = true
    @State private var prepCountdownValue: Int = 3
    @State private var prepTimerSubscription: AnyCancellable? = nil
    
    // 长按结束运动进度圈 (0.0 ~ 1.0)
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
                TabView(selection: $selectedPageIndex) {
                    coreFocusWorkoutPage()
                        .tag(0)
                    
                    secondaryTelemetryAndSchedulePage()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                bottomMinimalistHoldToEndBar()
            }
            .blur(radius: isPrepCountdownActive || restTimer.isPrecisionZoomed || showingExerciseListModal || showingSetListModal ? 16 : 0)
            .animation(.easeInOut(duration: 0.28), value: restTimer.isPrecisionZoomed)
            .animation(.easeInOut(duration: 0.28), value: showingExerciseListModal || showingSetListModal)
            
            // 顶部自动进阶打卡提示横幅
            completionNoticeOverlay()
            
            // 悬浮表盘（带高阶毛玻璃背景模糊）与动作/组数选择玻璃弹窗
            modalsAndFloatingDialsOverlay()
            
            // 进场 3 2 1 GO! 倒计时仪式感全屏遮罩
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
    
    // MARK: - Page 0: 极致精简与高层级排版的专注打卡页 (主界面)
    @ViewBuilder
    private func coreFocusWorkoutPage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. 顶栏训练进度与快速动作菜单 (严格原样调用既有组件)
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
                .padding(.top, 6)
                
                // 2. 主次分明核心排版：休息状态高亮休息卡片，非休息状态优先高亮打卡及操作键
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
                    VStack(spacing: 16) {
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
                
                Spacer(minLength: 140)
            }
            .padding(.horizontal, 20)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
        }
    }
    
    // MARK: - Page 1: 左右滑动展出的辅助遥测与计划全景页 (次要界面)
    @ViewBuilder
    private func secondaryTelemetryAndSchedulePage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 手表运动健康实时遥测大卡片
                WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                    .padding(.top, 6)
                
                // 本次完整计划动作列表一览
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("全场动作进度")
                            .font(.system(size: 17, weight: .heavy))
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
                                
                                VStack(alignment: .leading, spacing: 3) {
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
                
                Spacer(minLength: 140)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - 精致且克制的底栏：极简分页指示点 & 沉浸锁屏长按结束胶囊
    @ViewBuilder
    private func bottomMinimalistHoldToEndBar() -> some View {
        VStack(spacing: 10) {
            // 精致极简分页微指示
            HStack(spacing: 6) {
                Circle()
                    .fill(selectedPageIndex == 0 ? AppColors.primaryText : Color.black.opacity(0.18))
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(selectedPageIndex == 1 ? AppColors.primaryText : Color.black.opacity(0.18))
                    .frame(width: 6, height: 6)
            }
            
            // 精致内敛的长按结束训练按钮（避免大面积红色对运动者的视觉干扰）
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                
                // 红色按压填墨进度条
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.red)
                        .frame(width: geo.size.width * holdToEndProgress)
                        .animation(.linear(duration: 0.04), value: holdToEndProgress)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: isHoldingToEnd ? "lock.open.fill" : "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(isHoldingToEnd ? "松开取消 · 继续长按结束..." : "长按此按键结束运动")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(holdToEndProgress > 0.45 ? .white : Color(red: 0.8, green: 0.2, blue: 0.2))
            }
            .frame(height: 42)
            .padding(.horizontal, 48)
            .contentShape(Capsule())
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
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            Color.white.opacity(0.72)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - 悬浮表盘（恢复高阶全屏背景模糊）与动作/组数弹窗
    @ViewBuilder
    private func modalsAndFloatingDialsOverlay() -> some View {
        ZStack {
            if restTimer.isPrecisionZoomed {
                // 彻底恢复高阶沉浸毛玻璃与遮罩
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        restTimer.isPrecisionZoomed = false
                    }
                }
                
                GiantFloatingTimerDialView(timerModel: $restTimer)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
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
    
    // MARK: - 动作完成顶部横幅
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
    
    // MARK: - 进场 3 2 1 GO 仪式感倒计时
    @ViewBuilder
    private func prepCountdownOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("准备就绪 · 开启沉浸训练")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 180, height: 180)
                    
                    Text(prepCountdownValue > 0 ? "\(prepCountdownValue)" : "GO!")
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .foregroundColor(prepCountdownValue > 0 ? .white : .green)
                        .scaleEffect(prepCountdownValue > 0 ? 1.0 : 1.15)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: prepCountdownValue)
                }
            }
        }
    }
    
    // MARK: - 定时器相关管理
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
