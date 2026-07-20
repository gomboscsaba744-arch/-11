import SwiftUI
#if os(watchOS)

/// Apple Watch 顶级运动伴侣主入口（模块化协调视图）
/// 严格根据训练状态路由至不同模块：
/// 1. 运动结果总结：展示 WatchPostWorkoutSummaryView（展示最高心率、平均心率、总卡路里及训练容量）
/// 2. 未开训：展示 WatchPreWorkoutTabView（主推一整段会话开启与连接概览）
/// 3. 运动进行中：展示 WatchActiveWorkoutTabView（超大计次比 + 体征心率 + 控制面板）
public struct WatchTrainingView: View {
    @ObservedObject private var workoutManager = WatchWorkoutManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            // 沉浸式高级暖橙光感底层渲染（消除手表沉闷压抑感，与 App 通透玻璃质感完美贴合）
            RadialGradient(
                colors: [Color.orange.opacity(AppColors.isWatchLightMode ? 0.16 : 0.26), Color.clear],
                center: .top,
                startRadius: 5,
                endRadius: 180
            )
            .ignoresSafeArea()
            
            Group {
                if workoutManager.showWorkoutSummary {
                    WatchPostWorkoutSummaryView(workoutManager: workoutManager) {
                        withAnimation {
                            workoutManager.dismissSummary()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if !workoutManager.isWorkoutRunning {
                    WatchPreWorkoutTabView(workoutManager: workoutManager)
                } else {
                    WatchActiveWorkoutTabView(workoutManager: workoutManager)
                }
            }
        }
        .preferredColorScheme(AppThemeMode(rawValue: workoutManager.appThemeMode)?.colorScheme)
    }
}

#Preview {
    WatchTrainingView()
}
#endif
