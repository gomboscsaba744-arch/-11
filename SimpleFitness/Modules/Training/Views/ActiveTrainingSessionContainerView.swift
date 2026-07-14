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
    @ObservedObject private var watchService = WatchConnectivityService.shared
    
    // 左右滑动分页选择：
    // 0: 核心打卡页（极简，专注打卡与动作控制）
    // 1: 计时器与休息控制页
    // 2: 监测数据与计划明细页
    @State private var selectedPageIndex: Int = 0
    
    // 进场 3 2 1 GO 仪式感倒计时
    @State private var isPrepCountdownActive: Bool = true
    @State private var prepCountdownValue: Int = 3
    @State private var prepTimerSubscription: AnyCancellable? = nil
    
    // 长按与滑动结束运动进度
    @State private var holdToEndProgress: CGFloat = 0.0
    @State private var isHoldingToEnd: Bool = false
    @State private var holdWorkItem: DispatchWorkItem? = nil
    
    // 屏幕上锁与长按解锁功能
    @State private var isScreenLocked: Bool = false
    @State private var unlockProgress: CGFloat = 0.0
    @State private var isHoldingUnlock: Bool = false
    @State private var unlockWorkItem: DispatchWorkItem? = nil
    
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
            
            TabView(selection: $selectedPageIndex) {
                pageZeroCoreWorkout()
                    .tag(0)
                
                pageOneRestTimer()
                    .tag(1)
                
                pageTwoTelemetryAndSchedule()
                    .tag(2)
            }
            // 严格恢复最原始的模糊参数：12
            .blur(radius: isPrepCountdownActive || restTimer.isPrecisionZoomed || showingExerciseListModal || showingSetListModal ? 12 : 0)
            .animation(.easeInOut(duration: 0.25), value: restTimer.isPrecisionZoomed)
            
            // 顶部横幅提示
            completionNoticeOverlay()
            
            // 悬浮表盘与弹窗（严格恢复最初原始样式）
            modalsAndFloatingDialsOverlay()
            
            // 锁屏防护全屏遮罩（上锁后仅锁按钮可被点击解锁）
            if isScreenLocked {
                screenLockOverlay()
                    .zIndex(250)
                    .transition(.opacity)
            }
            
            // 进场 3 2 1 GO 倒计时全屏遮罩
            if isPrepCountdownActive {
                prepCountdownOverlay()
                    .zIndex(300)
                    .transition(.opacity)
            }
        }
        .onAppear {
            startPrepCountdown()
            MotionSensorLogManager.shared.startRecording(
                exerciseName: session.exerciseName,
                setNumber: session.currentSet
            )
            syncFullStateToWatch()
        }
        .onDisappear {
            prepTimerSubscription?.cancel()
            holdWorkItem?.cancel()
            MotionSensorLogManager.shared.stopRecording()
        }
        .onChange(of: session.currentSet) { newSet in
            MotionSensorLogManager.shared.startRecording(
                exerciseName: session.exerciseName,
                setNumber: newSet
            )
            syncFullStateToWatch()
        }
        .onChange(of: session.totalSets) { _ in
            syncFullStateToWatch()
        }
        .onChange(of: session.exerciseName) { newName in
            MotionSensorLogManager.shared.startRecording(
                exerciseName: newName,
                setNumber: session.currentSet
            )
            syncFullStateToWatch()
        }
        .onChange(of: restTimer.isRunning) { _ in
            syncFullStateToWatch()
        }
        // 表端数据实时遥测与双向同步绑定
        .onChange(of: watchService.syncedCurrentSet) { newSet in
            if newSet != session.currentSet {
                session.currentSet = newSet
            }
        }
        .onChange(of: watchService.syncedTotalSets) { newTotal in
            if newTotal != session.totalSets {
                session.totalSets = newTotal
            }
        }
        .onChange(of: watchService.syncedExerciseIndex) { newIndex in
            onSwitchExercise(newIndex)
        }
        .onChange(of: watchService.currentHeartRate) { hr in
            if hr > 0 { session.currentHeartRate = hr }
        }
        .onChange(of: watchService.activeEnergyBurnedKcal) { kcal in
            if kcal >= 0 { session.currentCalories = kcal }
        }
        .onChange(of: watchService.detectedRepCount) { reps in
            if reps > 0 { recordedReps = reps }
        }
    }
    
    private func syncFullStateToWatch() {
        watchService.syncWorkoutStateToWatch(
            exerciseName: session.exerciseName,
            currentSet: session.currentSet,
            totalSets: session.totalSets,
            targetReps: session.currentReps,
            targetWeightKg: session.targetWeightKg,
            isResting: restTimer.isRunning
        )
    }
    
    // MARK: - Page 0: 核心专注打卡主页 (极简清晰，毫无冗余卡片堆砌)
    @ViewBuilder
    private func pageZeroCoreWorkout() -> some View {
        VStack(spacing: 0) {
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
            
            Spacer(minLength: 12)
            
            if restTimer.isRunning || restTimer.isPaused {
                RestTimerCardView(timerModel: $restTimer)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer(minLength: 12)
            }
            
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
            
            Spacer(minLength: 14)
            
            TrainingActionButtonsView(
                currentSet: session.currentSet,
                onCompleteSet: { onCompleteSet() },
                onPrevExercise: { onPrevExercise() },
                onNextExercise: { onNextExercise() }
            )
            .padding(.bottom, 12)
            
            // 锁屏防误触按键 与 长按结束运动按键（仅限在第一页底部呈现）
            HStack(spacing: 12) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isScreenLocked = true
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .fill(Color(white: 0.15))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                bottomHoldToEndBar()
            }
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: restTimer.isRunning || restTimer.isPaused)
    }
    
    // MARK: - Page 1: 计时与休息管理页 (高端苹果审美 Studio 级视觉架构，绝不改动原组件内部逻辑)
    @ViewBuilder
    private func pageOneRestTimer() -> some View {
        VStack(spacing: 0) {
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
            
            Spacer(minLength: 12)
            
            // Studio 级极简黑金焦点导览舱
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.accentBlue)
                            .frame(width: 6, height: 6)
                        Text("REST & CADENCE")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(AppColors.accentBlue)
                            .tracking(1.2)
                    }
                    Text(session.exerciseName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                    Text("第 \(session.currentSet)/\(session.totalSets) 组")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(white: 0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.8)
                    )
            )
            
            Spacer(minLength: 14)
            
            // 核心休息与计次圆盘（原先设计的组件保持百分百完整不可变）
            RestTimerCardView(timerModel: $restTimer)
            
            Spacer(minLength: 14)
            
            // Apple Fitness+ 风格双列指标数据看板
            HStack(spacing: 12) {
                // 左数据块：建议负荷
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("下组负荷")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(Int(session.targetWeightKg))")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("KG")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(white: 0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8)
                        )
                )
                
                // 右数据块：建议目标次数
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("推荐目标")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                        Image(systemName: "repeat.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.accentBlue)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(session.currentReps)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("REPS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(white: 0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8)
                        )
                )
            }
            
            Spacer(minLength: 14)
            
            TrainingActionButtonsView(
                currentSet: session.currentSet,
                onCompleteSet: { onCompleteSet() },
                onPrevExercise: { onPrevExercise() },
                onNextExercise: { onNextExercise() }
            )
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Page 2: 手表传感器数据监测与全场计划页 (左滑切换)
    @ViewBuilder
    private func pageTwoTelemetryAndSchedule() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                WatchSensorTelemetryCardView(telemetry: session.watchTelemetry)
                    .padding(.top, 14)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("今日训练全部动作")
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
    
    // MARK: - 底部精致分页点与长按结束控制条（硬件加速平滑过渡·0卡顿）
    @ViewBuilder
    private func bottomHoldToEndBar() -> some View {
        VStack(spacing: 12) {
            // 分页指示点
            HStack(spacing: 6) {
                ForEach(0..<3) { idx in
                    Circle()
                        .fill(selectedPageIndex == idx ? AppColors.primaryText : Color.black.opacity(0.16))
                        .frame(width: 6, height: 6)
                }
            }
            
            // 长按 1.2 秒结束本场训练
            ZStack(alignment: .leading) {
                // 底色
                Color(white: 0.12)
                
                // 红色进度填充层（纯矩形从左向右平滑延伸，由最外层圆角严格裁切，左端圆角与外框绝对契合、绝不溢出或方形畸变）
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color(red: 0.95, green: 0.22, blue: 0.32))
                        .frame(width: max(0, geo.size.width * holdToEndProgress))
                }
                
                // 内容层：始终清晰居中对齐
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "stop.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    Text(isHoldingToEnd ? "正在结束... 松开取消" : "长按 1.2 秒结束本场训练")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 42, height: 32)
                }
            }
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 4)
            .scaleEffect(isHoldingToEnd ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHoldingToEnd)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHoldingToEnd {
                            startSmoothLongPress()
                        }
                    }
                    .onEnded { _ in
                        cancelSmoothLongPress()
                    }
            )
        }
    }
    
    // MARK: - 锁屏全透明防护层与长按解锁条 (完全透明不遮挡训练内容，仅拦截触控以防误触)
    @ViewBuilder
    private func screenLockOverlay() -> some View {
        ZStack {
            // 纯透明触控拦截层：画面 100% 清晰呈现，阻断一切底层误触动作
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                    impact.impactOccurred()
                }
            
            VStack(spacing: 0) {
                // 顶部胶囊指示标签：精炼单行，绝不遮挡或挤压
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                    Text("屏幕已锁定 · 防误触保护中")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(white: 0.12).opacity(0.92))
                        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.orange.opacity(0.4), lineWidth: 1)
                )
                .padding(.top, 8)
                
                Spacer()
                
                // 底部单行高级质感解锁条（单行自适应，长按 1 秒解锁）
                ZStack(alignment: .leading) {
                    Color(white: 0.13)
                    
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: max(0, geo.size.width * unlockProgress))
                    }
                    
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 32, height: 32)
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 8)
                        
                        Spacer(minLength: 4)
                        
                        Text(isHoldingUnlock ? "正在解锁..." : "长按 1 秒解锁")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        
                        Spacer(minLength: 4)
                        
                        Color.clear.frame(width: 40, height: 32)
                    }
                }
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .scaleEffect(isHoldingUnlock ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHoldingUnlock)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHoldingUnlock {
                                startSmoothUnlockPress()
                            }
                        }
                        .onEnded { _ in
                            cancelSmoothUnlockPress()
                        }
                )
            }
        }
    }
    
    
    // MARK: - 悬浮表盘与弹窗（完全修复到最原始样貌：Color.white.opacity(0.32) + blur 12）
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
    
    // MARK: - 顶部完成提示横幅
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
    
    // MARK: - 进场 3 2 1 GO 倒计时遮罩
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
    
    // MARK: - 计时器管理
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
    
    private func startSmoothLongPress() {
        isHoldingToEnd = true
        holdWorkItem?.cancel()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.linear(duration: 1.2)) {
            holdToEndProgress = 1.0
        }
        
        let item = DispatchWorkItem { [self] in
            if isHoldingToEnd {
                isHoldingToEnd = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onEndWorkout()
            }
        }
        holdWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: item)
    }
    
    private func cancelSmoothLongPress() {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        isHoldingToEnd = false
        
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            holdToEndProgress = 0.0
        }
    }
    
    private func startSmoothUnlockPress() {
        isHoldingUnlock = true
        unlockWorkItem?.cancel()
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        withAnimation(.linear(duration: 1.0)) {
            unlockProgress = 1.0
        }
        
        let item = DispatchWorkItem { [self] in
            if isHoldingUnlock {
                isHoldingUnlock = false
                unlockProgress = 0.0
                isScreenLocked = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        unlockWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }
    
    private func cancelSmoothUnlockPress() {
        unlockWorkItem?.cancel()
        unlockWorkItem = nil
        isHoldingUnlock = false
        
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            unlockProgress = 0.0
        }
    }
}
