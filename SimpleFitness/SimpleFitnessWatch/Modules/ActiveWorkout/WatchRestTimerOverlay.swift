import SwiftUI
#if os(watchOS)

/// Apple Watch 力量训练专属组间休息秒表与触觉提醒组件
public struct WatchRestTimerOverlay: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    
    public init(workoutManager: WatchWorkoutManager) {
        self.workoutManager = workoutManager
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.96).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    Text("组间休息")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 5)
                    
                    let progress = Double(workoutManager.restTimeRemaining) / Double(max(1, workoutManager.totalRestTime))
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: progress)
                    
                    VStack(spacing: 1) {
                        Text("\(workoutManager.restTimeRemaining)")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        Text("秒")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }
                }
                .frame(width: 86, height: 86)
                
                Text("下组准备：\(workoutManager.exerciseName)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Button(action: {
                        workoutManager.addRestTime(15)
                    }) {
                        Text("+15s")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .tint(.blue.opacity(0.4))
                    
                    Button(action: {
                        workoutManager.skipRestPeriod()
                    }) {
                        Text("跳过休息")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    .tint(.green)
                }
                .frame(height: 32)
            }
            .padding(.horizontal, 4)
        }
    }
}
#endif
