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
            // 1. 全局训练路径进度栏 (可点击左侧切换训练日，可点击右侧弹窗浏览全部动作)
            HStack(alignment: .center, spacing: 6) {
                Button(action: onSelectRoutine) {
                    HStack(alignment: .center, spacing: 5) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.body.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                        
                        Text(session.workoutTitle)
                            .font(.system(size: 21, weight: .heavy))
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
                .buttonStyle(.plain)
                .layoutPriority(2)
                
                Spacer(minLength: 6)
                
                // 当前动作进度指示条 (绝对禁止折行被挤压，强制保持横向精致单行胶囊)
                Button(action: onTapExerciseListModal) {
                    HStack(spacing: 6) {
                        Text("动作 \(session.currentExerciseIndex)/\(session.totalExercises)")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(AppColors.accentBlue)
                            .lineLimit(1)
                        
                        ExerciseProgressDotsView(
                            current: session.currentExerciseIndex,
                            total: session.totalExercises
                        )
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(10)
            }
            
            // 2. 当前阶段状态横幅 (可点击右侧第X/Y组展开组数明细浮层)
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isRestPhase ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(isRestPhase ? "组间休息" : "训练进行中")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(isRestPhase ? .orange : .green)
                }
                Spacer()
                
                Button(action: onTapSetListModal) {
                    HStack(spacing: 4) {
                        Text("第 \(session.currentSet)/\(session.totalSets) 组")
                            .font(.footnote)
                            .fontWeight(.black)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((isRestPhase ? Color.orange : Color.green).opacity(0.12))
                    .foregroundColor(isRestPhase ? .orange : .green)
                    .clipShape(Capsule())
                }
            }
            
            // 3. 动作主体与体征信息
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.exerciseName)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(String(format: "目标负重 %.1f kg", session.targetWeightKg))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("\(session.currentHeartRate)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                    
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(session.currentCalories)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .standardCardStyle()
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
