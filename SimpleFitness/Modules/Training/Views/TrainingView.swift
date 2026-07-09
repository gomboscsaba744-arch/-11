import SwiftUI

public struct TrainingView: View {
    @State private var session = TrainingSessionMock()
    @State private var restTimer = RestTimerModel(defaultDuration: 90)
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                // 主体训练内容（展开巨型表盘时背景呈现高阶苹果白色磨砂轻虚化）
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        TrainingHeaderView(session: session)
                            .padding(.top, 8)
                        
                        RepCounterCardView(reps: $session.currentReps)
                        
                        RestTimerCardView(timerModel: $restTimer)
                        
                        TrainingActionButtonsView(
                            currentSet: session.currentSet,
                            onCompleteSet: {
                                if session.currentSet < session.totalSets {
                                    session.currentSet += 1
                                }
                                restTimer.reset()
                                restTimer.isRunning = true
                            }
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                .blur(radius: restTimer.isPrecisionZoomed ? 12 : 0)
                .animation(.easeInOut(duration: 0.25), value: restTimer.isPrecisionZoomed)
                
                // 巨型无边界悬浮表盘（高阶清爽白色调磨砂感，无黑遮罩）
                if restTimer.isPrecisionZoomed {
                    Color.white.opacity(0.32)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                restTimer.isPrecisionZoomed = false
                            }
                        }
                    
                    GiantFloatingTimerDialView(timerModel: $restTimer)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .zIndex(100)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    TrainingView()
}
