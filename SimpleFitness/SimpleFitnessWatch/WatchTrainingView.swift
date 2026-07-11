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

#Preview {
    WatchTrainingView()
}
#endif
