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
                    Text("Watch自动计次")
                        .foregroundColor(AppColors.secondaryText)
                    Text("·")
                        .foregroundColor(AppColors.secondaryText.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: isAutoMode ? "bolt.fill" : "hand.tap.fill")
                            .foregroundColor(isAutoMode ? .orange : AppColors.primaryText)
                            .transition(.scale.combined(with: .opacity))
                            .id("icon_\(isAutoMode)")
                        Text(isAutoMode ? "自动流转开" : "手动流转")
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
                        .fill(isAutoMode ? Color.orange.opacity(0.18) : AppColors.pillBackground)
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
             // 达标提示与 10s 倒计时缓冲横幅
            if isBufferActive {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.subheadline.weight(.bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已完成 \(targetReps) 次！达标反馈")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.primaryText)
                        Text("\(bufferRemaining)s 后自动进入休息倒计时")
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
                    .background(AppColors.pillBackground)
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
                .padding(14)
                .background(Color.orange.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 雕塑感环形光晕 HUD 中央计次台 (无任何方框束缚)
            ZStack {
                // 背景微光环形渲染
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                (recordedReps >= targetReps && targetReps > 0 ? Color.orange : AppColors.accentBlue).opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 150
                        )
                    )
                    .frame(width: 280, height: 280)
                
                HStack(spacing: 28) {
                    // 减次数大圆触控
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        if recordedReps > 0 { recordedReps -= 1 }
                    }) {
                        Image(systemName: "minus")
                            .font(.title.weight(.bold))
                            .foregroundColor(AppColors.primaryText)
                            .frame(width: 64, height: 64)
                            .background(AppColors.pillBackground)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    }
                    
                    // 核心数字 (96pt 视觉绝对主宰)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(recordedReps)")
                            .font(.system(size: 96, weight: .black, design: .rounded))
                            .foregroundColor(recordedReps >= targetReps && targetReps > 0 ? .orange : AppColors.primaryText)
                            .contentTransition(.numericText(value: Double(recordedReps)))
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: recordedReps)
                        Text("/ \(targetReps)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.secondaryText)
                            .contentTransition(.numericText(value: Double(targetReps)))
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: targetReps)
                    }
                    .frame(minWidth: 170)
                    
                    // 加次数大圆触控
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        recordedReps += 1
                    }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(AppColors.accentBlue)
                            .clipShape(Circle())
                            .shadow(color: AppColors.accentBlue.opacity(0.35), radius: 10, x: 0, y: 4)
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
    }
}
