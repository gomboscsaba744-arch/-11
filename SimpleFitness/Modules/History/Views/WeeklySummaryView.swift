import SwiftUI

public struct WeeklySummaryView: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            // 本周次数
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.accentBlue)
                    Text("本周次数")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("3")
                        .font(.title2)
                        .fontWeight(.black)
                    Text("次")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .standardCardStyle()
            
            // 总消耗
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("总消耗")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("1440")
                        .font(.title2)
                        .fontWeight(.black)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .standardCardStyle()
            
            // 训练时长
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                    Text("训练时长")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("177")
                        .font(.title2)
                        .fontWeight(.black)
                    Text("分钟")
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .standardCardStyle()
        }
    }
}
