import SwiftUI

/// 首页组间休息卡片
public struct RestTimerCardView: View {
    @Binding public var timerModel: RestTimerModel
    
    public init(timerModel: Binding<RestTimerModel>) {
        self._timerModel = timerModel
    }
    
    public var body: some View {
        VStack(spacing: 18) {
            topHeaderBar
            centerWatchDialSection
            standardQuickActionButtons
        }
        .padding(20)
        .standardCardStyle()
        .onReceive(Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()) { _ in
            guard timerModel.isRunning else { return }
            if timerModel.remainingTime > 0 {
                timerModel.remainingTime = max(0, timerModel.remainingTime - 0.03)
            } else {
                timerModel.isRunning = false
            }
        }
    }
    
    // MARK: - 顶部标题与展开
    private var topHeaderBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentBlue)
                Text("组间倒计时")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("\(timerModel.defaultDuration)s")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    timerModel.isPrecisionZoomed = true
                    timerModel.isRunning = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "dial.max.fill")
                    Text("展开")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.pillBackground)
                .foregroundColor(AppColors.secondaryText)
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - 首页圆形表盘
    private var centerWatchDialSection: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.14), lineWidth: 14)
            
            Circle()
                .trim(from: 0, to: CGFloat(timerModel.progress))
                .stroke(
                    lapGradient(for: timerModel.currentLap),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: timerModel.progress)
            
            VStack(spacing: 4) {
                Text(timerModel.formattedTimeString)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(AppColors.primaryText)
                
                Text(timerModel.isRunning ? "计时中" : "长按展开表盘")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(width: 190, height: 190)
        .padding(.vertical, 4)
        .contentShape(Circle())
        .onLongPressGesture(minimumDuration: 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                timerModel.isPrecisionZoomed = true
                timerModel.isRunning = false
            }
        }
    }
    
    // MARK: - 快捷微调与启动按键
    private var standardQuickActionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button(action: { timerModel.adjustDuration(by: -15) }) {
                    Text("-15s")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: { timerModel.adjustDuration(by: -1) }) {
                    Text("-1s")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                Button(action: { timerModel.adjustDuration(by: 1) }) {
                    Text("+1s")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: { timerModel.adjustDuration(by: 15) }) {
                    Text("+15s")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            HStack(spacing: 14) {
                Button(action: {
                    withAnimation {
                        timerModel.isRunning.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: timerModel.isRunning ? "pause.fill" : "play.fill")
                        Text(timerModel.isRunning ? "暂停" : "开始")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(timerModel.isRunning ? Color.orange : AppColors.accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    withAnimation {
                        timerModel.reset()
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(12)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(Circle())
                }
            }
        }
    }
}

/// 巨型无边界悬浮表盘
/// - 正向进圈：顺时针清零收拢。
/// - 逆向退圈架构：
///   1. 纯逆时针铺满整圈 (0.0s ~ 0.55s)：顶层圆环自 0 点出发严格逆时针填满全圆 (100%)；底层普通顺时针环保持隐藏，绝对无顺时针生长；
///   2. 顺位归拢着陆 (0.55s 后)：当 100% 满圈结束瞬间，真实进度环在 100% 满圈处接手，并借助缓动平滑收缩归拢至鼠标所在目标进度，彻底消灭突切与闪现。
public struct GiantFloatingTimerDialView: View {
    @Binding public var timerModel: RestTimerModel
    
    @State private var is60SecondPrecisionDial: Bool = false
    @State private var lastAngle: Double? = nil
    @State private var accumulatedAngleDelta: Double = 0.0
    @State private var holdTask: DispatchWorkItem? = nil
    
    @State private var touchDownLocation: CGPoint? = nil
    @State private var maxMoveDistance: CGFloat = 0.0
    
    @State private var isShowingLapRetraction: Bool = false
    @State private var retractionStartTrim: CGFloat = 0.0
    @State private var retractionEndTrim: CGFloat = 1.0
    @State private var retractionLapIndex: Int = 1
    @State private var isRetractionMirroredCounterClockwise: Bool = false
    @State private var postRetractionTrimOverride: CGFloat? = nil
    
    public init(timerModel: Binding<RestTimerModel>) {
        self._timerModel = timerModel
    }
    
    public var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        timerModel.isPrecisionZoomed = false
                    }
                }
            
            VStack(spacing: 34) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(is60SecondPrecisionDial ? "秒级精调 (1s)" : "标准调时 (10s)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryText)
                            
                            Text(lapTitle(for: timerModel.currentLap))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.accentBlue)
                                .clipShape(Capsule())
                                .foregroundColor(.white)
                        }
                        Text("长按表盘切换调秒精度")
                            .font(.caption2)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            timerModel.isPrecisionZoomed = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("收起")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Image(systemName: "xmark.circle.fill")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.18))
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 40)
                
                Spacer()
                
                ZStack {
                    DialTickRingView(isPrecision60sDial: is60SecondPrecisionDial, radius: 155)
                    
                    Circle()
                        .stroke(Color.secondary.opacity(0.14), lineWidth: 22)
                    
                    // 1. 活跃跟手层：逆向退圈时暂时隐藏；满圈完成后自 1.0 (100%) 平滑收缩归拢至鼠标真实进度
                    let targetProgress = CGFloat(is60SecondPrecisionDial ? Double(timerModel.totalDuration % 60) / 60.0 : timerModel.lapProgress)
                    Circle()
                        .trim(
                            from: 0,
                            to: postRetractionTrimOverride ?? targetProgress
                        )
                        .stroke(
                            lapGradient(for: timerModel.currentLap),
                            style: StrokeStyle(lineWidth: 22, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .opacity((isShowingLapRetraction && isRetractionMirroredCounterClockwise) ? 0.0 : 1.0)
                        .animation(.interactiveSpring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.2), value: timerModel.totalDuration)
                    
                    // 2. 跨界动效层：纯净自 0 点出发逆时针填充满圈
                    if isShowingLapRetraction {
                        Circle()
                            .trim(from: retractionStartTrim, to: retractionEndTrim)
                            .stroke(
                                lapGradient(for: retractionLapIndex),
                                style: StrokeStyle(lineWidth: 22, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .scaleEffect(x: isRetractionMirroredCounterClockwise ? -1 : 1, y: 1)
                    }
                    
                    VStack(spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            let displaySeconds = max(0, Int(ceil(timerModel.remainingTime)))
                            let mins = displaySeconds / 60
                            let secs = displaySeconds % 60
                            
                            Text(String(format: "%02d", mins))
                                .font(.system(size: 58, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(AppColors.primaryText.opacity(is60SecondPrecisionDial ? 0.65 : 1.0))
                            
                            Text(":")
                                .font(.system(size: 54, weight: .black, design: .rounded))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(String(format: "%02d", secs))
                                .font(.system(size: is60SecondPrecisionDial ? 68 : 58, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(is60SecondPrecisionDial ? AppColors.accentBlue : AppColors.primaryText)
                                .scaleEffect(is60SecondPrecisionDial ? 1.08 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: is60SecondPrecisionDial)
                        }
                        .contentTransition(.numericText(value: Double(timerModel.totalDuration)))
                        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: timerModel.totalDuration)
                        
                        Text(is60SecondPrecisionDial ? "1 圈 = 60 秒" : "1 圈 = 5 分钟")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .frame(width: 310, height: 310)
                .padding(36)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDialDragChanged(location: value.location, center: CGPoint(x: 191, y: 191))
                        }
                        .onEnded { value in
                            handleDialDragEnded(location: value.location, center: CGPoint(x: 191, y: 191))
                        }
                )
                
                Spacer()
                
                Button(action: {
                    timerModel.remainingTime = Double(timerModel.totalDuration)
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        timerModel.isPrecisionZoomed = false
                        timerModel.isRunning = true
                    }
                }) {
                    Text("完成并开始")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleDialDragChanged(location: CGPoint, center: CGPoint) {
        if touchDownLocation == nil {
            touchDownLocation = location
            maxMoveDistance = 0.0
            accumulatedAngleDelta = 0.0
            
            let workItem = DispatchWorkItem {
                if maxMoveDistance < 8.0 {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    
                    let dx = location.x - center.x
                    let dy = location.y - center.y
                    var pressAngle = atan2(dy, dx) * 180 / .pi + 90
                    if pressAngle < 0 { pressAngle += 360 }
                    
                    let fingerSecond = Int(round((pressAngle / 360.0) * 60.0)) % 60
                    let currentMinutes = timerModel.totalDuration / 60
                    let syncedDuration = max(5, min(1800, currentMinutes * 60 + fingerSecond))
                    
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
                        timerModel.totalDuration = syncedDuration
                        timerModel.remainingTime = Double(syncedDuration)
                        is60SecondPrecisionDial = true
                    }
                }
            }
            holdTask = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28, execute: workItem)
        }
        
        if let start = touchDownLocation {
            let dist = hypot(location.x - start.x, location.y - start.y)
            maxMoveDistance = max(maxMoveDistance, dist)
            if maxMoveDistance >= 8.0 {
                holdTask?.cancel()
            }
        }
        
        let dx = location.x - center.x
        let dy = location.y - center.y
        var currentAngle = atan2(dy, dx) * 180 / .pi + 90
        if currentAngle < 0 { currentAngle += 360 }
        
        guard let prev = lastAngle else {
            lastAngle = currentAngle
            return
        }
        
        var delta = currentAngle - prev
        if delta > 180 { delta -= 360 }
        else if delta < -180 { delta += 360 }
        
        accumulatedAngleDelta += delta
        lastAngle = currentAngle
        
        let sensitivity: Double = is60SecondPrecisionDial ? 6.0 : 12.0
        let step: Int = is60SecondPrecisionDial ? 1 : 10
        
        if abs(accumulatedAngleDelta) >= sensitivity {
            let steps = Int(accumulatedAngleDelta / sensitivity)
            
            let oldDuration = timerModel.totalDuration
            let oldLap = timerModel.currentLap
            let oldMinute = oldDuration / 60
            
            timerModel.adjustDuration(by: steps * step)
            
            let newDuration = timerModel.totalDuration
            let newLap = timerModel.currentLap
            let newMinute = newDuration / 60
            
            let isForwardCross = is60SecondPrecisionDial ? (newMinute > oldMinute) : (newLap > oldLap)
            let isBackwardCross = is60SecondPrecisionDial ? (newMinute < oldMinute) : (newLap < oldLap)
            
            if isForwardCross {
                triggerLapRetraction(lapIndex: oldLap, isBackwardCross: false)
            } else if isBackwardCross {
                triggerLapRetraction(lapIndex: newLap, isBackwardCross: true)
            }
            
            accumulatedAngleDelta -= Double(steps) * sensitivity
        }
    }
    
    private func triggerLapRetraction(lapIndex: Int, isBackwardCross: Bool) {
        retractionLapIndex = lapIndex
        isShowingLapRetraction = true
        
        if isBackwardCross {
            isRetractionMirroredCounterClockwise = true
            retractionStartTrim = 0.0
            retractionEndTrim = 0.0
            withAnimation(.easeInOut(duration: 0.55)) {
                retractionEndTrim = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                // 100% 满圈顺位接手，随即平滑缩回至指尖目标刻度
                postRetractionTrimOverride = 1.0
                isShowingLapRetraction = false
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    postRetractionTrimOverride = nil
                }
            }
        } else {
            isRetractionMirroredCounterClockwise = false
            retractionStartTrim = 0.0
            retractionEndTrim = 1.0
            withAnimation(.easeInOut(duration: 0.55)) {
                retractionStartTrim = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                isShowingLapRetraction = false
            }
        }
    }
    
    private func handleDialDragEnded(location: CGPoint, center: CGPoint) {
        holdTask?.cancel()
        
        if maxMoveDistance < 8.0 && !is60SecondPrecisionDial {
            let dx = location.x - center.x
            let dy = location.y - center.y
            var angle = atan2(dy, dx) * 180 / .pi + 90
            if angle < 0 { angle += 360 }
            
            let rawSeconds = Int(round((angle / 360.0) * 300.0))
            let snapped = max(10, min(300, (rawSeconds / 10) * 10))
            
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                timerModel.totalDuration = snapped
                timerModel.remainingTime = Double(snapped)
            }
        }
        
        lastAngle = nil
        touchDownLocation = nil
        maxMoveDistance = 0.0
        accumulatedAngleDelta = 0.0
        withAnimation(.easeInOut(duration: 0.2)) {
            is60SecondPrecisionDial = false
        }
    }
    
    private func lapTitle(for lap: Int) -> String {
        switch lap {
        case 1: return "第 1 圈"
        case 2: return "第 2 圈"
        case 3: return "第 3 圈"
        case 4: return "第 4 圈"
        default: return "第 \(lap) 圈"
        }
    }
}

/// 巨型刻度环
private struct DialTickRingView: View {
    var isPrecision60sDial: Bool
    var radius: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<60, id: \.self) { index in
                let angle = Double(index) * 6.0
                let isMajor = index % (isPrecision60sDial ? 5 : 2) == 0
                
                Capsule()
                    .fill(isMajor ? AppColors.primaryText.opacity(0.75) : AppColors.accentBlue.opacity(0.65))
                    .frame(width: isMajor ? 3 : 1.5, height: isMajor ? 14 : 7)
                    .offset(y: -radius + 12)
                    .rotationEffect(.degrees(angle))
            }
        }
    }
}

/// 0 点和 360 点闭环色彩配置
private func lapGradient(for lap: Int) -> AngularGradient {
    let colors: [Color]
    switch lap {
    case 1:
        colors = [AppColors.accentBlue, Color.cyan, Color(red: 0.1, green: 0.72, blue: 0.98), AppColors.accentBlue]
    case 2:
        colors = [AppColors.accentBlue, Color(red: 0.15, green: 0.85, blue: 0.75), Color(red: 0.0, green: 0.68, blue: 0.95), AppColors.accentBlue]
    case 3:
        colors = [AppColors.accentBlue, Color(red: 0.55, green: 0.52, blue: 0.95), Color(red: 0.35, green: 0.65, blue: 0.98), AppColors.accentBlue]
    case 4:
        colors = [AppColors.accentBlue, Color(red: 0.82, green: 0.68, blue: 0.95), Color.white, AppColors.accentBlue]
    default:
        colors = [AppColors.accentBlue, Color(red: 0.95, green: 0.82, blue: 0.62), Color.white, AppColors.accentBlue]
    }
    return AngularGradient(gradient: Gradient(colors: colors), center: .center)
}

#Preview {
    RestTimerCardView(timerModel: .constant(RestTimerModel()))
        .padding()
}
