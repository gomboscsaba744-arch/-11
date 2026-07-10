import SwiftUI

public struct TrainingActionButtonsView: View {
    public var currentSet: Int
    public var onCompleteSet: () -> Void
    public var onPrevExercise: () -> Void
    public var onNextExercise: () -> Void
    
    public init(
        currentSet: Int,
        onCompleteSet: @escaping () -> Void = {},
        onPrevExercise: @escaping () -> Void = {},
        onNextExercise: @escaping () -> Void = {}
    ) {
        self.currentSet = currentSet
        self.onCompleteSet = onCompleteSet
        self.onPrevExercise = onPrevExercise
        self.onNextExercise = onNextExercise
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            // 完成本组大绿按键
            Button(action: onCompleteSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("完成第 \(currentSet) 组")
                        .fontWeight(.heavy)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.green)
                        .shadow(color: Color.green.opacity(0.32), radius: 10, x: 0, y: 4)
                )
            }
            
            // 上一动作 / 下一动作 切换
            HStack(spacing: 12) {
                Button(action: onPrevExercise) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("上一动作")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                }
                
                Button(action: onNextExercise) {
                    HStack(spacing: 4) {
                        Text("下一动作")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppColors.pillBackground)
                    .clipShape(Capsule())
                }
            }
        }
    }
}
