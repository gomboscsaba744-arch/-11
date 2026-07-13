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
    
    // 页面分屏标签
    @State private var selectedPageIndex: Int = 0
    
    // 3 2 1 GO 倒计时
    @State private var isPrepCountdownActive: Bool = true
    @State private var prepCountdownValue: Int = 3
    @State private var prepTimerSubscription: AnyCancellable? = nil
    
    // 长按结束训练动画属性
    @State private var holdToEndProgress: CGFloat = 0.0
    @State private var isHoldingToEnd: Bool = false
    @State private var holdTimerSubscription: AnyCancellable? = nil
    @State private var isPulseAnimating: Bool = false
    
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
            // 背景层：轻微高级渐变烘托立体训练舱感
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.94, blue: 0.96),
                    Color(red: 0.96, green: 0.97, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 顶部座舱状态条与精致模式选择切签
                premiumCockpitHeader()
                
                // 2. 核心双分屏滑页区
                TabView(selection: $selectedPageIndex) {
                    coreFocusCockpitPage()
                        .tag(0)
                    
                    telemetryAndTimelinePage()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 3. 底部立体按压式防误触长按舱控区
                premiumHoldToFinishDock()
            }
            .blur(radius: isPrepCountdownActive ? 18 : 0)
            
            // 顶层横幅通知
            completionNoticeOverlay()
            
            // 全屏模态与倒计时表盘
            modalsAndFloatingDialsOverlay()
            
            // 进场全屏 3 2 1 GO!
            if isPrepCountdownActive {
                prepCountdownOverlay()
                    .zIndex(300)
                    .transition(.opacity)
            }
        }
        .onAppear {
            startPrepCountdown()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulseAnimating = true
            }
        }
        .onDisappear {
            prepTimerSubscription?.cancel()
            holdTimerSubscription?.cancel()
        }
    }
    
    // MARK: - 1. 顶部座舱状态条 (精简高端)
    @ViewBuilder
    private func premiumCockpitHeader() -> some View {
        HStack(spacing: 14) {
            // 左侧指示：LIVE 呼吸绿点
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                    .scaleEffect(isPulseAnimating ? 1.25 : 0.85)
                    .opacity(isPulseAnimating ? 1.0 : 0.6)
                
                Text("LIVE WORKOUT")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.4)
                    .foregroundColor(AppColors.primaryText.opacity(0.85))
            }
            
            Spacer()
            
            // 右侧分屏切签胶囊：轻触或滑动即可切换
            HStack(spacing: 2) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selectedPageIndex = 0
                    }
                }) {
                    Text("专注训练")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(selectedPageIndex == 0 ? .white : AppColors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedPageIndex == 0 ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        selectedPageIndex = 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 11, weight: .bold))
                        Text("手表 & 进度")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(selectedPageIndex == 1 ? .white : AppColors.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        selectedPageIndex == 1 ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.clear
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(3)
            .background(Color.white.opacity(0.8))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }
    
    // MARK: - 2. Page 0: 核心专注驾驶舱页面 (告别干瘪平铺，重塑空间焦点)
    @ViewBuilder
    private func coreFocusCockpitPage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // 动作头部信息
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
                
                // 根据当前是否正在组间休息进行空间焦点聚焦
                if restTimer.isRunning || restTimer.isPaused {
                    RestTimerCardView(timerModel: $restTimer)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 核心表现台组合 (将打卡计数卡片与控制按钮组合在一个呼吸感的性能矩阵容器中)
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
                
                if !restTimer.isRunning && !restTimer.isPaused {
                    RestTimerCompactPreviewCardView(timerModel: $restTimer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer(minLength: 130)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
        }
    }
    
    // MARK: - 3. Page 1: 手表传感器实时数据 & 动作进度轴 (专业杂志级排版)
    @ViewBuilder
    private func telemetryAndTimelinePage() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 手表传感器卡片
                WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                
                // 动作执行进度轴
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("全计划动作执行表")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(AppColors.primaryText)
                        Spacer()
                        Text("第 \(session.currentExerciseIndex) / \(currentRoutineExercises.count) 项")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(Array(currentRoutineExercises.enumerated()), id: \.offset) { index, item in
                            timelineRowView(for: item, at: index)
                        }
                    }
                }
                
                Spacer(minLength: 130)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    private func timelineRowView(for item: PlanExerciseItemMock, at index: Int) -> some View {
        let isCurrent = (index + 1 == session.currentExerciseIndex)
        let isCompleted = (index + 1 < session.currentExerciseIndex)
        
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isCurrent ? Color.black : (isCompleted ? Color.green.opacity(0.15) : Color.black.opacity(0.05)))
                    .frame(width: 34, height: 34)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(isCurrent ? .white : AppColors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    if isCurrent {
                        Text("当前进行中")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }
                Text("\(item.sets) 组 · 每组约 \(item.reps) 次")
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
                .fill(isCurrent ? Color.white : Color.white.opacity(0.65))
                .shadow(color: isCurrent ? Color.black.opacity(0.08) : Color.clear, radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCurrent ? Color.black.opacity(0.8) : Color.clear, lineWidth: 1.5)
        )
    }
    
    // MARK: - 4. 底部高奢工业感按压式安全舱底座 (Hold-to-Finish Dock)
    @ViewBuilder
    private func premiumHoldToFinishDock() -> some View {
        VStack(spacing: 8) {
            // 极简两页指示圆点
            HStack(spacing: 6) {
                Circle()
                    .fill(selectedPageIndex == 0 ? Color.black : Color.black.opacity(0.18))
                    .frame(width: 5, height: 5)
                Circle()
                    .fill(selectedPageIndex == 1 ? Color.black : Color.black.opacity(0.18))
                    .frame(width: 5, height: 5)
            }
            
            // 工业奢华感防误触长按结束键
            ZStack {
                // 底部槽位底色
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.13))
                
                // 红色液化推进进度栏
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.9, green: 0.2, blue: 0.25), Color(red: 0.78, green: 0.12, blue: 0.18)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * holdToEndProgress)
                        .animation(.linear(duration: 0.05), value: holdToEndProgress)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                // 图标与重磅排版文字
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: isHoldingToEnd ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                    }
                    
                    Text(isHoldingToEnd ? "正在安全解锁... 保持按压" : "长按此键 1.8 秒安全结束训练")
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
            }
            .frame(height: 54)
            .scaleEffect(isHoldingToEnd ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHoldingToEnd)
            .padding(.horizontal, 20)
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
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            ZStack {
                Color.white.opacity(0.88)
                Color.white.opacity(0.4)
            }
            .ignoresSafeArea()
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: -6)
        )
    }
    
    // MARK: - 5. 顶部完成动作横幅
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
    
    // MARK: - 6. 模态与悬浮表盘
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
    
    // MARK: - 7. 3 2 1 GO 仪式感倒计时
    @ViewBuilder
    private func prepCountdownOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("专注训练即将展开")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 180, height: 180)
                    
                    Text(prepCountdownValue > 0 ? "\(prepCountdownValue)" : "GO!")
                        .font(.system(size: 78, weight: .black, design: .rounded))
                        .foregroundColor(prepCountdownValue > 0 ? .white : .green)
                        .scaleEffect(prepCountdownValue > 0 ? 1.0 : 1.25)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: prepCountdownValue)
                }
            }
        }
    }
    
    // MARK: - 定时器相关逻辑
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
