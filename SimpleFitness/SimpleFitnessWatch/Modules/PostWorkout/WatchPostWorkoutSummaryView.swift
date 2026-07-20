import SwiftUI
#if os(watchOS)

/// 力量训练结束后的专业运动成果总结表盘
/// 具备原生 Apple Fitness 级高级质感动效：优雅进场微动效、真实会话指标统计与高品质视觉美学
public struct WatchPostWorkoutSummaryView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var appearHeader: Bool = false
    @State private var appearCards: Bool = false
    @State private var ringPulse: Bool = false
    
    public init(workoutManager: WatchWorkoutManager, onDismiss: @escaping () -> Void) {
        self.workoutManager = workoutManager
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // 1. 胜利达成头部卡片（带原生精致光晕与弹跳出现感）
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.orange.opacity(0.32), Color.clear],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(ringPulse ? 1.08 : 0.94)
                            .opacity(ringPulse ? 1.0 : 0.75)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .scaleEffect(appearHeader ? 1.0 : 0.7)
                    .opacity(appearHeader ? 1.0 : 0.0)
                    
                    Text("训练完成！")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(AppColors.primaryText)
                        .opacity(appearHeader ? 1.0 : 0.0)
                    
                    Text("力量挑战与突破")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.orange)
                        .opacity(appearHeader ? 1.0 : 0.0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                
                // 2. 核心指标卡片组（优雅层次入场，真实数据呈现）
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        SummaryMetricBox(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "总消耗",
                            value: "\(workoutManager.summaryTotalKcal)",
                            unit: "KCAL"
                        )
                        SummaryMetricBox(
                            icon: "clock.fill",
                            iconColor: AppColors.accentBlue,
                            title: "真实用时",
                            value: workoutManager.summaryDurationString,
                            unit: ""
                        )
                    }
                    
                    HStack(spacing: 6) {
                        SummaryMetricBox(
                            icon: "bolt.heart.fill",
                            iconColor: .red,
                            title: "最高心率",
                            value: "\(workoutManager.summaryMaxHeartRate)",
                            unit: "BPM"
                        )
                        SummaryMetricBox(
                            icon: "heart.fill",
                            iconColor: .pink,
                            title: "平均心率",
                            value: "\(workoutManager.summaryAvgHeartRate)",
                            unit: "BPM"
                        )
                    }
                }
                .offset(y: appearCards ? 0 : 12)
                .opacity(appearCards ? 1.0 : 0.0)
                
                // 3. 训练容量沉淀卡片
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("累计完成量")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.secondaryText)
                        Text("\(workoutManager.summaryCompletedSets) 组 · \(workoutManager.summaryTotalVolumeKg) kg")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                    }
                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.adaptiveCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 0.5)
                        )
                )
                .offset(y: appearCards ? 0 : 14)
                .opacity(appearCards ? 1.0 : 0.0)
                
                // 4. 完成保存按键
                Button(action: onDismiss) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("完成并保存")
                            .font(.system(size: 14, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .opacity(appearCards ? 1.0 : 0.0)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appearHeader = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.12)) {
                appearCards = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
    }
}

private struct SummaryMetricBox: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(iconColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.adaptiveCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 0.5)
                )
        )
    }
}
#endif
