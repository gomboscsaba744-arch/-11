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
    
    public var body: some View {
        VStack(spacing: 16) {
             // 顶部行：标题 + 手动/自动模式切换按键（不干扰主页整体布局）
             HStack {
                 HStack(spacing: 6) {
                     Image(systemName: "applewatch")
                         .font(.subheadline)
                         .foregroundColor(AppColors.accentBlue)
                     Text("完成次数 (Watch自动记录)")
                         .font(.subheadline.weight(.medium))
                         .foregroundColor(AppColors.secondaryText)
                 }
                 
                 Spacer()
                 
                 // 手动 / 自动模式精美切换胶囊
                 Button(action: {
                     let impact = UIImpactFeedbackGenerator(style: .medium)
                     impact.impactOccurred()
                     withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                         isAutoMode.toggle()
                     }
                 }) {
                     HStack(spacing: 4) {
                         Image(systemName: isAutoMode ? "bolt.fill" : "hand.tap.fill")
                             .font(.caption2.weight(.bold))
                         Text(isAutoMode ? "自动流转·开" : "手动确认·开")
                             .font(.caption.weight(.bold))
                     }
                     .padding(.horizontal, 10)
                     .padding(.vertical, 5)
                     .background(isAutoMode ? Color.orange.opacity(0.18) : AppColors.pillBackground)
                     .foregroundColor(isAutoMode ? .orange : AppColors.primaryText)
                     .clipShape(Capsule())
                 }
             }
             
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
                 .padding(12)
                 .background(Color.orange.opacity(0.12))
                 .cornerRadius(12)
                 .transition(.move(edge: .top).combined(with: .opacity))
             }
            
            // 中间：x / 12 大字展示区域
            HStack(spacing: 36) {
                // 减次数按钮
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    if recordedReps > 0 { recordedReps -= 1 }
                }) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                        .frame(width: 48, height: 48)
                        .background(AppColors.pillBackground)
                        .clipShape(Circle())
                }
                
                // 次数显示：x / 12 形式
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(recordedReps)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundColor(recordedReps >= targetReps && targetReps > 0 ? .orange : AppColors.primaryText)
                    Text("/ \(targetReps)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(minWidth: 130)
                
                // 加次数按钮
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    recordedReps += 1
                }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(AppColors.accentBlue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .standardCardStyle()
    }
}
