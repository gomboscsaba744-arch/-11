import SwiftUI

public struct ExerciseCardView: View {
    public var item: ExerciseItemMock
    public var onTap: (() -> Void)?
    
    public init(item: ExerciseItemMock, onTap: (() -> Void)? = nil) {
        self.item = item
        self.onTap = onTap
    }
    
    private var axisBadgeText: String {
        switch item.dominantAxis {
        case 0: return "X轴主导"
        case 1: return "Y轴主导"
        case 2: return "Z轴主导"
        default: return "多维矢量"
        }
    }
    
    public var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // 顶行：缩略图/动图微缩标识 + 名称与分类 + 右侧缩写圆标
                HStack(alignment: .top, spacing: 12) {
                    // 左侧 GIF/图缩略微标
                    let urlString = !item.gifUrl.isEmpty ? item.gifUrl : item.imageUrl
                    if let url = URL(string: urlString), !urlString.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            default:
                                thumbnailFallback
                            }
                        }
                    } else {
                        thumbnailFallback
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.primaryText)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 6) {
                            Text(item.category)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(AppColors.pillBackground)
                                .foregroundColor(AppColors.secondaryText)
                                .clipShape(Capsule())
                            
                            Text(axisBadgeText)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    // 右上侧字母圆目标签
                    ZStack {
                        Circle()
                            .fill(AppColors.accentBlue.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Text(item.badgeLetter)
                            .font(.subheadline)
                            .fontWeight(.black)
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
                
                // 说明文字
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 底部元信息
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("休息: \(item.restSeconds)秒")
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "gyroscope")
                        Text("波峰门限: \(item.thresholdG)")
                    }
                    
                    if !item.gifUrl.isEmpty {
                        Text("GIF演示")
                            .font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(AppColors.accentBlue.opacity(0.15))
                            .foregroundColor(AppColors.accentBlue)
                            .clipShape(Capsule())
                    }
                }
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
            }
            .padding(14)
            .standardCardStyle()
        }
        .buttonStyle(.plain)
    }
    
    private var thumbnailFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppColors.accentBlue.opacity(0.2), AppColors.accentBlue.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppColors.accentBlue)
        }
    }
}
