import SwiftUI
#if os(watchOS)
import WatchKit

/// Apple Watch 经典 3-2-1 动感倒计时开训组件
/// 每次数字跳动伴随震动反馈，倒计时结束瞬间强震并正式启动会话
public struct WatchCountdownView: View {
    let onFinished: () -> Void
    
    @State private var count: Int = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 8) {
                Text(count > 0 ? "\(count)" : "GO!")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(count > 0 ? .green : .yellow)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("准备出发")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            runCountdownStep(number: 3)
        }
    }
    
    private func runCountdownStep(number: Int) {
        count = number
        scale = 0.6
        opacity = 0.0
        
        // 播放触感反馈震动
        if number > 0 {
            WKInterfaceDevice.current().play(.start)
        } else {
            WKInterfaceDevice.current().play(.success)
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            scale = 1.0
            opacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            if number > 1 {
                runCountdownStep(number: number - 1)
            } else if number == 1 {
                runCountdownStep(number: 0)
            } else {
                onFinished()
            }
        }
    }
}
#endif
