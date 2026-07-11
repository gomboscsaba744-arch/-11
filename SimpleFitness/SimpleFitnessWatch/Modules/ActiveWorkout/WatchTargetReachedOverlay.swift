import SwiftUI
#if os(watchOS)
import WatchKit

/// 苹果原生美感与高清晰对比度的目标达成大提示屏（8 秒自动倒计时）
/// 充足呼吸感留白、亮眼无障碍高对比度按键设计
public struct WatchTargetReachedOverlay: View {
    @ObservedObject var workoutManager: WatchWorkoutManager
    let onDismiss: () -> Void
    
    @State private var remainingSeconds: Int = 8
    @State private var bannerTimer: Timer?
    @State private var iconScale: CGFloat = 0.8
    
    public init(workoutManager: WatchWorkoutManager, onDismiss: @escaping () -> Void) {
        self.workoutManager = workoutManager
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // 纯深色纯净底背板，彻底隔离背层干扰
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Spacer(minLength: 2)
                
                // 顶部达标印章与数字
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("\(workoutManager.targetReps) 次目标达成")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.green)
                }
                .scaleEffect(iconScale)
                
                Text("\(remainingSeconds)s 后返回监控或手动操作")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 2)
                
                // 主操作与次操作高对比度双按钮（上下分级展示，留出充足呼吸空间）
                VStack(spacing: 6) {
                    Button(action: {
                        stopTimer()
                        onDismiss()
                        workoutManager.completeCurrentSet()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                            Text("完成本组 · 休息")
                                .font(.system(size: 13, weight: .heavy))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        stopTimer()
                        onDismiss()
                    }) {
                        Text("继续超越挑战")
                            .font(.system(size: 12, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.18))
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                iconScale = 1.0
            }
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        bannerTimer?.invalidate()
        remainingSeconds = 8
        bannerTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 1 {
                remainingSeconds -= 1
            } else {
                stopTimer()
                onDismiss()
            }
        }
    }
    
    private func stopTimer() {
        bannerTimer?.invalidate()
        bannerTimer = nil
    }
}
#endif
