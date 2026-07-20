import SwiftUI
import WatchKit

public struct WatchLongPressEndButton: View {
    let action: () -> Void
    @State private var progress: CGFloat = 0.0
    @State private var isPressing: Bool = false
    @State private var workItem: DispatchWorkItem? = nil
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                AppColors.adaptiveCardBackground
                
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.22, blue: 0.32))
                    .frame(width: max(0, geo.size.width * progress))
                
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(progress > 0.3 ? .white : AppColors.primaryText)
                    
                    Text(isPressing ? "正在结束..." : "长按 1.2s 结束训练")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(progress > 0.3 ? .white : AppColors.primaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 1)
            )
        }
        .frame(height: 44)
        .scaleEffect(isPressing ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isPressing)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        workItem?.cancel()
                        WKInterfaceDevice.current().play(.click)
                        
                        withAnimation(.linear(duration: 1.2)) {
                            progress = 1.0
                        }
                        
                        let item = DispatchWorkItem {
                            if isPressing {
                                isPressing = false
                                WKInterfaceDevice.current().play(.success)
                                action()
                            }
                        }
                        workItem = item
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: item)
                    }
                }
                .onEnded { _ in
                    workItem?.cancel()
                    workItem = nil
                    isPressing = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        progress = 0.0
                    }
                }
        )
    }
}
