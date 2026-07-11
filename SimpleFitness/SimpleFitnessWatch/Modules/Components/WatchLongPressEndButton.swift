import SwiftUI
#if os(watchOS)
import WatchKit

/// Apple Watch 防误触长按蓄力动效按钮（全兼容 TabView 左右滑动，绝不吞掉横向翻页手势）
public struct WatchLongPressEndButton: View {
    let action: () -> Void
    
    @State private var isPressing: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var pressTimer: Timer?
    
    private let totalDuration: TimeInterval = 1.2
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.red.opacity(0.25))
            
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red)
                    .frame(width: geo.size.width * progress)
            }
            
            HStack(spacing: 6) {
                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "stop.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(isPressing ? "蓄力结束 \(Int(progress * 100))%" : "长按 1.2 秒结束训练")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundColor(.white)
        }
        .frame(height: 44)
        .scaleEffect(isPressing ? 0.96 : 1.0)
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isPressing)
        .onLongPressGesture(minimumDuration: totalDuration, pressing: { pressing in
            if pressing {
                startPressing()
            } else {
                cancelPressing()
            }
        }, perform: {
            finishPressing()
        })
    }
    
    private func startPressing() {
        isPressing = true
        WKInterfaceDevice.current().play(.click)
        
        let interval: TimeInterval = 0.03
        let step = CGFloat(interval / totalDuration)
        
        pressTimer?.invalidate()
        pressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.linear(duration: interval)) {
                progress = min(0.95, progress + step)
            }
        }
    }
    
    private func finishPressing() {
        pressTimer?.invalidate()
        pressTimer = nil
        withAnimation(.easeOut(duration: 0.15)) {
            progress = 1.0
        }
        WKInterfaceDevice.current().play(.success)
        action()
    }
    
    private func cancelPressing() {
        if progress < 1.0 {
            pressTimer?.invalidate()
            pressTimer = nil
            isPressing = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                progress = 0.0
            }
        }
    }
}
#endif
