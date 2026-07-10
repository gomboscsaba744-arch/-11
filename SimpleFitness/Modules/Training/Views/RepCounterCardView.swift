import SwiftUI

public struct RepCounterCardView: View {
    @Binding public var reps: Int
    
    public init(reps: Binding<Int>) {
        self._reps = reps
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("本组完成次数")
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 40) {
                // 减次数按钮
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    if reps > 0 { reps -= 1 }
                }) {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                        .frame(width: 48, height: 48)
                        .background(AppColors.pillBackground)
                        .clipShape(Circle())
                }
                
                // 次数显示
                Text("\(reps)")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .frame(minWidth: 80)
                
                // 加次数按钮
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    reps += 1
                }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(AppColors.accentBlue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .standardCardStyle()
    }
}
