import SwiftUI
#if os(watchOS)

/// 未开启运动时的专属多分页就绪主页
/// 经典双屏布局 + 自适应深浅主题玻璃质感卡片
public struct WatchPreWorkoutTabView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    @State private var selectedTab: Int = 0
    @State private var showCountdown: Bool = false
    
    public init(workoutManager: WatchWorkoutManager) {
        self.workoutManager = workoutManager
    }
    
    public var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                WatchPreWorkoutHeroPage(
                    workoutManager: workoutManager,
                    onStartTapped: handleStartTapped
                )
                .tag(0 as Int)
                
                WatchPreWorkoutPlanPage(workoutManager: workoutManager)
                .tag(1 as Int)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            if showCountdown {
                WatchCountdownView {
                    withAnimation {
                        showCountdown = false
                        workoutManager.startWorkoutSession()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(100)
            }
        }
    }
    
    private func handleStartTapped() {
        withAnimation {
            showCountdown = true
        }
    }
}

// MARK: - 开训前首屏：整段运动计划开启屏
private struct WatchPreWorkoutHeroPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let onStartTapped: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.clear
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                Spacer(minLength: 1)
                
                VStack(spacing: 5) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text("今日训练计划")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.orange)
                    }
                    
                    Text(workoutManager.planTitle)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(workoutManager.totalExercises) 个动作 · 共 18 组")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.horizontal, 6)
                
                Spacer(minLength: 2)
                
                Button(action: onStartTapped) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("开始训练")
                            .font(.system(size: 15, weight: .heavy))
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
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
    }
}

// MARK: - 开训前第二屏：训练计划预览
private struct WatchPreWorkoutPlanPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.clear
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text("今日动作清单")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 6) {
                        ForEach(Array(workoutManager.exercises.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text("\(index + 1). \(item.name)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.totalSets)×\(item.targetReps)")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundColor(index == 0 ? .orange : AppColors.secondaryText)
                            }
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
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
    }
}
#endif
