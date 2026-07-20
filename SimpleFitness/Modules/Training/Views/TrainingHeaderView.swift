import SwiftUI

public struct TrainingHeaderView: View {
    public var session: TrainingSessionMock
    public var isRestPhase: Bool
    public var onSelectRoutine: () -> Void
    public var onTapExerciseListModal: () -> Void
    public var onTapSetListModal: () -> Void
    
    public init(
        session: TrainingSessionMock,
        isRestPhase: Bool = false,
        onSelectRoutine: @escaping () -> Void = {},
        onTapExerciseListModal: @escaping () -> Void = {},
        onTapSetListModal: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isRestPhase = isRestPhase
        self.onSelectRoutine = onSelectRoutine
        self.onTapExerciseListModal = onTapExerciseListModal
        self.onTapSetListModal = onTapSetListModal
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 顶部训练日层级与当前动作进度（轻盈无边框，极简优雅）
            HStack(alignment: .center) {
                Button(action: onSelectRoutine) {
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                        
                        Text(session.workoutTitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: onTapExerciseListModal) {
                    HStack(spacing: 6) {
                        Text("动作 \(session.currentExerciseIndex)/\(session.totalExercises)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.secondaryText)
                        
                        ExerciseProgressDotsView(
                            current: session.currentExerciseIndex,
                            total: session.totalExercises
                        )
                    }
                }
                .buttonStyle(.plain)
            }
            
            // 2. 动作主标题与对应组数切换（强烈的视觉中心与层级呼应）
            HStack(alignment: .center) {
                Text(session.exerciseName)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 12)
                
                Button(action: onTapSetListModal) {
                    HStack(spacing: 4) {
                        Text("第 \(session.currentSet)/\(session.totalSets) 组")
                            .font(.system(size: 14, weight: .heavy))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(isRestPhase ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(isRestPhase ? .orange : .green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // 3. 统一式 Apple Studio 遥测与负重指标带 (整齐合一，彻底替代原有凌乱的分散小方块)
            HStack(spacing: 0) {
                // 目标重量或自重模式 (严格防止两行换行与自重适配)
                HStack(spacing: 4) {
                    if session.targetWeightKg <= 0 {
                        Image(systemName: "figure.core.training")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.accentBlue)
                        Text("自重训练")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: true, vertical: false)
                    } else {
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.accentBlue)
                        let weightStr = session.targetWeightKg.truncatingRemainder(dividingBy: 1) == 0
                            ? "\(Int(session.targetWeightKg))"
                            : String(format: "%.1f", session.targetWeightKg)
                        Text("目标\(weightStr)kg")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 8)
                
                // 心率监测
                HStack(spacing: 5) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                    Text(session.currentHeartRate > 0 ? "\(session.currentHeartRate) bpm" : "--")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 8)
                
                // 动态卡路里
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("\(session.currentCalories) kcal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(session.currentCalories)))
                        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: session.currentCalories)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppColors.adaptivePillBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

/// 自适应圆点进度指示器：保留精美圆点设计，支持 12 动作精巧密点及超多动作时的 Apple iOS Page Control 滑动窗口圆点
private struct ExerciseProgressDotsView: View {
    var current: Int
    var total: Int
    
    var body: some View {
        if total <= 12 {
            // 12 个及以内动作：全部展示分立圆点，依动作总数动态优化圆点尺寸与间距，确保右侧药丸完美收纳不溢出
            let spacing: CGFloat = total <= 6 ? 3.5 : 2.0
            let dotSize: CGFloat = total <= 6 ? 6.0 : 4.5
            let activeWidth: CGFloat = total <= 6 ? 15.0 : 10.0
            
            HStack(spacing: spacing) {
                ForEach(1...max(1, total), id: \.self) { idx in
                    Capsule()
                        .fill(idx <= current ? AppColors.accentBlue : Color.secondary.opacity(0.22))
                        .frame(width: idx == current ? activeWidth : dotSize, height: total <= 6 ? 5.5 : 4.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: current)
                }
            }
        } else {
            // 超过 12 个动作：采用 Apple iOS Page Control 风格滑动透视圆点（展示 7 颗有效点，边缘渐渐缩小至透视感）
            let windowIndices = visibleIndices(current: current, total: total, maxVisible: 7)
            
            HStack(spacing: 2.2) {
                ForEach(windowIndices, id: \.self) { idx in
                    let isEdge = (idx == windowIndices.first && idx > 1) || (idx == windowIndices.last && idx < total)
                    let scale: CGFloat = isEdge ? 0.62 : 1.0
                    
                    Capsule()
                        .fill(idx <= current ? AppColors.accentBlue : Color.secondary.opacity(0.22))
                        .frame(width: idx == current ? 10.0 : 4.5, height: 4.5)
                        .scaleEffect(scale)
                        .opacity(isEdge ? 0.65 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: current)
                }
            }
        }
    }
    
    private func visibleIndices(current: Int, total: Int, maxVisible: Int) -> [Int] {
        guard total > maxVisible else { return Array(1...total) }
        let half = maxVisible / 2
        var start = max(1, current - half)
        var end = start + maxVisible - 1
        if end > total {
            end = total
            start = max(1, end - maxVisible + 1)
        }
        return Array(start...end)
    }
}
