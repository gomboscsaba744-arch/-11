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
        VStack(alignment: .leading, spacing: 12) {
            // 1. 顶层导航栏：所属训练日切换 + 动作进度点阵
            HStack(alignment: .center, spacing: 8) {
                Button(action: onSelectRoutine) {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                        
                        Text(session.workoutTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
                .buttonStyle(.plain)
                .layoutPriority(1)
                
                Spacer(minLength: 4)
                
                // 动作点阵导航 (绝对单行防止 1/4 换行压缩)
                Button(action: onTapExerciseListModal) {
                    HStack(spacing: 5) {
                        Text("动作 \(session.currentExerciseIndex)/\(session.totalExercises)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        
                        ExerciseProgressDotsView(
                            current: session.currentExerciseIndex,
                            total: session.totalExercises
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(10)
            }
            
            // 2. 动作主标题 + 右侧当前组数入口
            HStack(alignment: .center) {
                Text(session.exerciseName)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                if isRestPhase {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("休息中")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Spacer(minLength: 8)
                
                // 组数明细导航
                Button(action: onTapSetListModal) {
                    HStack(spacing: 3) {
                        Text("第 \(session.currentSet)/\(session.totalSets) 组")
                            .font(.caption.weight(.heavy))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background((isRestPhase ? Color.orange : Color.green).opacity(0.14))
                    .foregroundColor(isRestPhase ? .orange : .green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(10)
            }
                
                // 体征与目标负重集成指标带 (精炼水平对齐)
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                            .foregroundColor(AppColors.secondaryText)
                        Text(String(format: "目标 %.1f kg", session.targetWeightKg))
                            .font(.caption.weight(.bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                        Text(session.currentHeartRate > 0 ? "\(session.currentHeartRate) bpm" : "--")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        Text("\(session.currentCalories) kcal")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(session.currentCalories)))
                            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: session.currentCalories)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                    
                    Spacer()
                }
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
