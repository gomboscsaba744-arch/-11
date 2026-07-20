import SwiftUI

public struct RepCounterCardView: View {
    @Binding public var recordedReps: Int
    @Binding public var targetReps: Int
    @Binding public var isAutoMode: Bool
    public var isBufferActive: Bool
    public var bufferRemaining: Int
    public var onCancelBuffer: () -> Void
    public var onImmediateRest: () -> Void
    
    public init(
        recordedReps: Binding<Int>,
        targetReps: Binding<Int>,
        isAutoMode: Binding<Bool> = .constant(true),
        isBufferActive: Bool = false,
        bufferRemaining: Int = 10,
        onCancelBuffer: @escaping () -> Void = {},
        onImmediateRest: @escaping () -> Void = {}
    ) {
        self._recordedReps = recordedReps
        self._targetReps = targetReps
        self._isAutoMode = isAutoMode
        self.isBufferActive = isBufferActive
        self.bufferRemaining = bufferRemaining
        self.onCancelBuffer = onCancelBuffer
        self.onImmediateRest = onImmediateRest
    }
    
    @State private var buttonScale: CGFloat = 1.0
    @State private var pulseAura: Bool = false
    
    public var body: some View {
        VStack(spacing: 16) {
            // 顶部行：精炼中央微光状态条，带有 Apple Watch 动效呼吸感与触感回弹
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
                    buttonScale = 0.92
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        buttonScale = 1.0
                        isAutoMode.toggle()
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .foregroundColor(AppColors.accentBlue)
                        .scaleEffect(isAutoMode ? (pulseAura ? 1.08 : 0.96) : 1.0)
                    Text("自动计次")
                        .foregroundColor(AppColors.secondaryText)
                    Text("·")
                        .foregroundColor(AppColors.secondaryText.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: isAutoMode ? "bolt.fill" : "hand.tap.fill")
                            .foregroundColor(isAutoMode ? .orange : AppColors.primaryText)
                            .transition(.scale.combined(with: .opacity))
                            .id("icon_\(isAutoMode)")
                        Text(isAutoMode ? "已开启" : "手动")
                            .foregroundColor(isAutoMode ? .orange : AppColors.primaryText)
                            .transition(.opacity)
                            .id("text_\(isAutoMode)")
                    }
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isAutoMode ? Color.orange.opacity(0.18) : AppColors.adaptivePillBackground)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isAutoMode ? Color.orange.opacity(pulseAura ? 0.65 : 0.25) : Color.clear, lineWidth: 1)
                )
                .shadow(color: isAutoMode ? Color.orange.opacity(pulseAura ? 0.35 : 0.1) : Color.clear, radius: 8, y: 2)
                .scaleEffect(buttonScale)
            }
            .buttonStyle(.plain)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulseAura = true
                }
            }
             
            // 达标提示与 10s 倒计时缓冲横幅
            if isBufferActive {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.subheadline.weight(.bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已完成目标 \(targetReps) 次")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.primaryText)
                        Text("\(bufferRemaining) 秒后进入休息")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    Spacer(minLength: 4)
                    Button("转为手动") {
                        onCancelBuffer()
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppColors.adaptivePillBackground)
                    .clipShape(Capsule())
                    
                    Button("立即休息") {
                        onImmediateRest()
                    }
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .padding(12)
                .background(Color.orange.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 雕塑感环形光晕 HUD 中央计次台 (精准自适应真机屏幕宽高比，绝不挤压上下方组件)
            ZStack {
                // 背景微光环形渲染：严格约束在屏幕高度的 22% 或宽度 52% 内，确保 iPhone 16 真机放大显示或大字体下也不挤压其他元素
                let dialDiameter: CGFloat = min(UIScreen.main.bounds.width * 0.52, UIScreen.main.bounds.height * 0.22, 195)
                let btnSize: CGFloat = min(UIScreen.main.bounds.width * 0.12, 48)
                
                // 背景微光环形弥散渲染：去除硬切边界，使用双层高斯模糊（radius: 36 与 18）平滑弥散融进空气背景中
                ZStack {
                    // 外层深度弥散光晕：把蓝色/橙色微光完全扩散，自然过渡到透明无边界
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    (recordedReps >= targetReps && targetReps > 0 ? Color.orange : AppColors.accentBlue).opacity(0.32),
                                    (recordedReps >= targetReps && targetReps > 0 ? Color.orange : AppColors.accentBlue).opacity(0.12),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: dialDiameter * 0.55
                            )
                        )
                        .frame(width: dialDiameter * 1.5, height: dialDiameter * 1.5)
                        .blur(radius: 36)
                    
                    // 内层柔和通透焦点层：增强中心层次感，无明显圆环外框
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    (recordedReps >= targetReps && targetReps > 0 ? Color.orange : AppColors.accentBlue).opacity(0.20),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: dialDiameter * 0.35
                            )
                        )
                        .frame(width: dialDiameter * 1.1, height: dialDiameter * 1.1)
                        .blur(radius: 18)
                }
                .allowsHitTesting(false)
                
                HStack(spacing: min(UIScreen.main.bounds.width * 0.04, 16)) {
                    // 减次数触控
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        if recordedReps > 0 { recordedReps -= 1 }
                    }) {
                        Image(systemName: "minus")
                            .font(.title3.weight(.bold))
                            .foregroundColor(AppColors.primaryText)
                            .frame(width: btnSize, height: btnSize)
                            .background(AppColors.adaptivePillBackground)
                            .clipShape(Circle())
                            .shadow(color: AppColors.adaptiveCardShadow, radius: 5, x: 0, y: 2)
                    }
                    
                    // 核心数字 (高精度弹性适应屏幕，最小缩放 0.5)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(recordedReps)")
                            .font(.system(size: min(UIScreen.main.bounds.height * 0.08, 68), weight: .black, design: .rounded))
                            .foregroundColor(recordedReps >= targetReps && targetReps > 0 ? .orange : AppColors.primaryText)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText(value: Double(recordedReps)))
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: recordedReps)
                        Text("/ \(targetReps)")
                            .font(.system(size: min(UIScreen.main.bounds.height * 0.035, 26), weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText(value: Double(targetReps)))
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: targetReps)
                    }
                    .frame(minWidth: min(UIScreen.main.bounds.width * 0.32, 120))
                    
                    // 加次数触控
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        recordedReps += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: btnSize, height: btnSize)
                            .background(AppColors.accentBlue)
                            .clipShape(Circle())
                            .shadow(color: AppColors.accentBlue.opacity(0.35), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
    }
}
