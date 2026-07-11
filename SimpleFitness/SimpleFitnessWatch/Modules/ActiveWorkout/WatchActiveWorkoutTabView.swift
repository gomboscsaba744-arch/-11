import SwiftUI
#if os(watchOS)

/// 力量训练进行中的 3 屏专业体能训练伴侣视图
/// 全量关联动态数据池：动作名称、目标次数、组数与重量 100% 连贯互动
public struct WatchActiveWorkoutTabView: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    @State private var selectedTab: Int = 0
    
    public init(workoutManager: WatchWorkoutManager) {
        self.workoutManager = workoutManager
    }
    
    public var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                WatchActiveHeroSetPage(workoutManager: workoutManager)
                    .tag(0)
                
                WatchActivePerformancePage(workoutManager: workoutManager)
                    .tag(1)
                
                WatchActiveControlsPage(workoutManager: workoutManager)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            if workoutManager.showTargetReachedModal {
                WatchTargetReachedOverlay(workoutManager: workoutManager) {
                    withAnimation {
                        workoutManager.showTargetReachedModal = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                .zIndex(90)
            }
            
            if workoutManager.isResting {
                WatchRestTimerOverlay(workoutManager: workoutManager)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(100)
            }
        }
    }
}

// MARK: - 主屏：动作组计次打卡与实时动作联动屏
private struct WatchActiveHeroSetPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    @State private var isRepCountingDown: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 3) {
                HStack {
                    Text("动作 \(workoutManager.exerciseIndex)/\(workoutManager.totalExercises)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                    Spacer()
                    Text("第 \(workoutManager.currentSet)/\(workoutManager.totalSets) 组")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                HStack {
                    Text(workoutManager.exerciseName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.2), value: workoutManager.exerciseName)
                    Spacer()
                }
                .padding(.horizontal, 4)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.78, blendDuration: 0.15)) {
                            isRepCountingDown = true
                            workoutManager.adjustRepCount(by: -1)
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    VStack(spacing: 2) {
                        Text("\(workoutManager.detectedRepCount)")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(workoutManager.detectedRepCount >= workoutManager.targetReps ? .green : .white)
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: isRepCountingDown))
                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.78, blendDuration: 0.15), value: workoutManager.detectedRepCount)
                        
                        if workoutManager.detectedRepCount > workoutManager.targetReps {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.orange)
                                Text("超越目标 +\(workoutManager.detectedRepCount - workoutManager.targetReps)")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.orange)
                            }
                        } else if workoutManager.detectedRepCount == workoutManager.targetReps {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("已达标 \(workoutManager.targetReps) 次")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("目标 \(workoutManager.targetReps) 次 · \(Int(workoutManager.currentWeightKg)) kg")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.78, blendDuration: 0.15)) {
                            isRepCountingDown = false
                            workoutManager.adjustRepCount(by: 1)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.green.opacity(0.35))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
                
                Spacer(minLength: 0)
                
                Button(action: {
                    workoutManager.completeCurrentSet()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("完成第 \(workoutManager.currentSet) 组")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                }
                .tint(.green)
                .cornerRadius(16)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - 第二屏：体征数据与表现
private struct WatchActivePerformancePage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 6) {
                    HStack {
                        Text("体征与总表现")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("实时心率")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(workoutManager.currentHeartRate)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                Text("BPM")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("活动消耗")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(workoutManager.activeEnergyKcal)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                Text("KCAL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("今日训练总容量")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("1,420 kg")
                                .font(.system(size: 15, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - 第三屏：动态联动会话控制页
private struct WatchActiveControlsPage: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 8) {
                    // 1. 当前动作动态实时进度卡
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("会话控制")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.green)
                            Spacer()
                            Text("动作 \(workoutManager.exerciseIndex)/\(workoutManager.totalExercises)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        Text(workoutManager.exerciseName)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .animation(.easeInOut(duration: 0.2), value: workoutManager.exerciseName)
                        Text("当前第 \(workoutManager.currentSet)/\(workoutManager.totalSets) 组 · 目标 \(workoutManager.targetReps) 次")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(9)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(10)
                    .padding(.top, 4)
                    
                    // 2. 动态切换动作控制键（实时同步修改动作名与目标）
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation {
                                workoutManager.previousExercise()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .heavy))
                                Text("上一动作")
                                    .font(.system(size: 12, weight: .heavy))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(workoutManager.exerciseIndex > 1 ? Color.white.opacity(0.24) : Color.white.opacity(0.08))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(workoutManager.exerciseIndex <= 1)
                        
                        Button(action: {
                            withAnimation {
                                workoutManager.nextExercise()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("下一动作")
                                    .font(.system(size: 12, weight: .heavy))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .heavy))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(workoutManager.exerciseIndex < workoutManager.exercises.count ? Color.blue : Color.blue.opacity(0.3))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .disabled(workoutManager.exerciseIndex >= workoutManager.exercises.count)
                    }
                    
                    // 3. 底部醒目长按结束训练区域
                    WatchLongPressEndButton {
                        workoutManager.endWorkoutSession()
                    }
                    .padding(.bottom, 6)
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
#endif
