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
            
            HStack(spacing: 48) {
                // 减次数按钮
                Button(action: {
                    if reps > 0 { reps -= 1 }
                }) {
                    Image(systemName: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
                
                // 次数显示
                Text("\(reps)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                    .frame(minWidth: 90)
                
                // 加次数按钮
                Button(action: {
                    reps += 1
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(AppColors.accentBlue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .standardCardStyle()
    }
}
