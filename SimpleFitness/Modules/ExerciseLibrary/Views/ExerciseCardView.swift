import SwiftUI

public struct ExerciseCardView: View {
    public var item: ExerciseItemMock
    
    public init(item: ExerciseItemMock) {
        self.item = item
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶行：图标 + 名称 + 部位 + 绿色角标
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                    Text(item.badgeLetter)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundColor(Color.green)
                .cornerRadius(6)
            }
            
            // 说明文字
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(2)
            
            // 底部元信息
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("默认组间休息: \(item.restSeconds)秒")
                }
                
                Spacer()
                
                Text("波峰阈值: \(item.thresholdG)")
            }
            .font(.caption)
            .foregroundColor(AppColors.secondaryText)
        }
        .padding()
        .standardCardStyle()
    }
}
