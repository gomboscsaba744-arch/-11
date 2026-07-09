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
            // 完成本组大绿按钮
            Button(action: onCompleteSet) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("完成第 \(currentSet) 组 (进入组间休息)")
                        .fontWeight(.bold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.green)
                .cornerRadius(14)
            }
            
            // 上一动作 / 下一动作 切换
            HStack {
                Button(action: onPrevExercise) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("上一动作")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentBlue)
                }
                
                Spacer()
                
                Button(action: onNextExercise) {
                    HStack(spacing: 4) {
                        Text("下一动作")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentBlue)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
