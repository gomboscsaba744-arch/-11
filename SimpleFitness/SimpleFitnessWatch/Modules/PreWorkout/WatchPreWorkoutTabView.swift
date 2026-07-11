import SwiftUI
#if os(watchOS)

/// 未开启运动时的专属多分页就绪主页
/// 经典双屏布局 + 全屏隐形触碰底板，百分之百感知黑边空白区域手势滑动
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
                    onStartTapped: {
                        withAnimation {
                            showCountdown = true
                        }
                    }
                )
                .tag(0)
                
                WatchPreWorkoutPlanPage(workoutManager: workoutManager)
                    .tag(1)
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
}

// MARK: - 开训前首屏：整段运动计划开启屏
private struct WatchPreWorkoutHeroPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let onStartTapped: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Spacer(minLength: 2)
                
                VStack(spacing: 4) {
                    Text("今日训练计划")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text(workoutManager.planTitle)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\(workoutManager.totalExercises) 个动作 · 共 18 组")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 4)
                
                Button(action: onStartTapped) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("开始训练")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                }
                .tint(.green)
                .cornerRadius(20)
            }
            .padding(.horizontal, 6)
        }
    }
}

// MARK: - 开训前第二屏：计划课表预览
private struct WatchPreWorkoutPlanPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日动作清单")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.top, 4)
                    
                    VStack(spacing: 6) {
                        HStack {
                            Text("1. 哑铃平卧推举")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("4×12")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(9)
                        
                        HStack {
                            Text("2. 上斜杠铃卧推")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("4×10")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(9)
                        
                        HStack {
                            Text("3. 绳索夹胸")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("4×15")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(9)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
#endif
