import SwiftUI

/// 训练界面主视图底部的“紧凑型倒计时预览及表盘调出卡片”
/// 经过苹果级 UI 精细排版：确保快调按键水平舒展不折行、层级简洁
public struct RestTimerCompactPreviewCardView: View {
    @Binding public var timerModel: RestTimerModel
    
    public init(timerModel: Binding<RestTimerModel>) {
        self._timerModel = timerModel
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentBlue)
                Text("组间休息")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Spacer(minLength: 4)
            
            HStack(spacing: 7) {
                Button(action: { timerModel.adjustDuration(by: -15) }) {
                    Text("-15s")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(Capsule())
                }
                
                Text("\(timerModel.totalDuration)s")
                    .font(.subheadline.weight(.heavy))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(AppColors.accentBlue)
                    .contentTransition(.numericText())
                
                Button(action: { timerModel.adjustDuration(by: 15) }) {
                    Text("+15s")
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.primaryText)
                        .clipShape(Capsule())
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.82), value: "\(timerModel.totalDuration)s".count)
            
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                    timerModel.isPrecisionZoomed = true
                }
            }) {
                Image(systemName: "dial.max.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppColors.accentBlue)
                    .frame(width: 34, height: 34)
                    .background(AppColors.accentBlue.opacity(0.12))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .standardCardStyle()
    }
}
