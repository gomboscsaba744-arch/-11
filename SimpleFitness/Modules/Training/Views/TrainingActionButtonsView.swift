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
        VStack(spacing: 16) {
            // 完成本组大绿按键
            Button(action: onCompleteSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("完成第 \(currentSet) 组")
                        .font(.title3.weight(.heavy))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Capsule()
                        .fill(Color.green)
                        .shadow(color: Color.green.opacity(0.35), radius: 12, x: 0, y: 5)
                )
            }
            
            // 上一动作 / 下一动作 切换 (轻量浮层设计)
            HStack(spacing: 20) {
                Button(action: onPrevExercise) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("上一动作")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                
                Button(action: onNextExercise) {
                    HStack(spacing: 4) {
                        Text("下一动作")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
