import SwiftUI
#if canImport(WebKit)
import WebKit
#endif

/// 动作详情全景指导弹层：展示 GIF 动态演示、所需器械、分步要领要点与手表陀螺仪标定参数
public struct ExercisePanoramaModalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    public let item: ExerciseItemMock
    public var onAddToPlan: ((ExerciseItemMock) -> Void)?
    
    public init(item: ExerciseItemMock, onAddToPlan: ((ExerciseItemMock) -> Void)? = nil) {
        self.item = item
        self.onAddToPlan = onAddToPlan
    }
    
    private var dominantAxisDescription: String {
        switch item.dominantAxis {
        case 0: return "X 轴 (纵向摆动/倾角拉升)"
        case 1: return "Y 轴 (重力方向垂直起落)"
        case 2: return "Z 轴 (侧向扭转/水平飞鸟)"
        default: return "复合多维矢量综合 (Y 轴主导)"
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. 顶部双语标题与分类卡片
                        headerSection
                        
                        // 2. GIF 动态演示与缩略图卡片
                        demonstrationMediaCard
                        
                        // 3. 器械与训练肌群标签栏
                        equipmentAndTargetTags
                        
                        // 4. 分步动作要领指导要点
                        stepByStepInstructionsCard
                        
                        // 5. Apple Watch 陀螺仪与加速度传感器标定参数板块
                        gyroscopeCalibrationCard
                        
                        if let onAdd = onAddToPlan {
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                                onAdd(item)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("将此动作添加到训练计划")
                                        .font(.headline.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.accentBlue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: AppColors.accentBlue.opacity(0.4), radius: 10, y: 4)
                            }
                            .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("动作全景指导与参数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.15))
                    .frame(width: 56, height: 56)
                Text(item.badgeLetter)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(AppColors.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(AppColors.primaryText)
                
                if !item.nameEn.isEmpty && item.name != item.nameEn {
                    Text(item.nameEn)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                } else if !item.nameZh.isEmpty && item.name != item.nameZh {
                    Text(item.nameZh)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.accentBlue)
                        .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                        Text("\(item.restSeconds)s 休息")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundColor(AppColors.secondaryText)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(16)
        .standardCardStyle()
    }
    
    // MARK: - 动态演示卡片
    private var demonstrationMediaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.tv.fill")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("动作动态演示")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
                Spacer()
                if !item.gifUrl.isEmpty {
                    Text("GIF 循环")
                        .font(.system(size: 10, weight: .heavy))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .clipShape(Capsule())
                }
            }
            
            let urlString = !item.gifUrl.isEmpty ? item.gifUrl : item.imageUrl
            if let url = URL(string: urlString), !urlString.isEmpty {
                if urlString.lowercased().hasSuffix(".gif") || !item.gifUrl.isEmpty {
#if canImport(WebKit)
                    AnimatedGIFWebView(url: url)
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
#else
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.pillBackground)
                                    .frame(height: 240)
                                ProgressView("正在加载演示动画...")
                                    .font(.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
                        case .failure(_):
                            fallbackIllustrationView
                        @unknown default:
                            fallbackIllustrationView
                        }
                    }
#endif
                } else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppColors.pillBackground)
                                    .frame(height: 240)
                                ProgressView("正在加载演示图片...")
                                    .font(.caption)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 6, y: 3)
                        case .failure(_):
                            fallbackIllustrationView
                        @unknown default:
                            fallbackIllustrationView
                        }
                    }
                }
            } else {
                fallbackIllustrationView
            }
        }
        .padding(16)
        .standardCardStyle()
    }
    
    private var fallbackIllustrationView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(AppColors.accentBlue.opacity(0.85))
            Text("标准动作分解 · 参考分步指导")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppColors.primaryText)
            Text(item.description)
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(AppColors.pillBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - 器械与目标肌群
    private var equipmentAndTargetTags: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("所需器械")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppColors.secondaryText)
                }
                Text(item.equipment)
                    .font(.subheadline.weight(.heavy))
                    .foregroundColor(AppColors.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .standardCardStyle()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("主练肌群")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppColors.secondaryText)
                }
                Text(item.target)
                    .font(.subheadline.weight(.heavy))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .standardCardStyle()
        }
    }
    
    // MARK: - 分步动作要领
    private var stepByStepInstructionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("分步执行要领")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            if item.steps.isEmpty {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .lineSpacing(4)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(item.steps.enumerated()), id: \.offset) { index, stepText in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(AppColors.accentBlue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(stepText)
                                .font(.subheadline)
                                .foregroundColor(AppColors.primaryText)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .standardCardStyle()
    }
    
    // MARK: - 陀螺仪标定参数卡片
    private var gyroscopeCalibrationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text("Apple Watch 陀螺仪与加速度计标定")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("该动作已嵌入预计算运动学标定参数（Pre-calculated Calibration Profile）。当您在 iPhone 开启此动作训练时，主控端将以零延迟单向将下述专属阈值下发给 Apple Watch 传感器。")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
                .lineSpacing(3)
            
            VStack(spacing: 10) {
                calibrationRow(label: "主导感知轴向 (Dominant Axis)", value: dominantAxisDescription, icon: "arrow.up.and.down.and.arrow.left.and.right")
                calibrationRow(label: "波谷波峰回落比 (Min Peak Ratio)", value: String(format: "%.0f%%", item.minRatio * 100), icon: "chart.xyaxis.line")
                calibrationRow(label: "加速度触发门限 (Threshold G)", value: item.thresholdG, icon: "speedometer")
                calibrationRow(label: "动作轨迹分类 (Motion Profile)", value: item.motionProfile, icon: "waveform.path.ecg")
            }
            .padding(.top, 4)
        }
        .padding(16)
        .standardCardStyle()
    }
    
    private func calibrationRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.caption)
                .frame(width: 20)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(AppColors.secondaryText)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(AppColors.primaryText)
        }
        .padding(10)
        .background(AppColors.pillBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#if canImport(WebKit)
/// 支持真正循环播放网络或本地 GIF 动图的轻量级 WebKit 容器
public struct AnimatedGIFWebView: UIViewRepresentable {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.contentMode = .scaleAspectFit
        return webView
    }
    
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
        body {
            margin: 0;
            padding: 0;
            background-color: transparent;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
        }
        img {
            max-width: 100%;
            max-height: 100%;
            object-fit: contain;
            border-radius: 12px;
        }
        </style>
        </head>
        <body>
            <img src="\(url.absoluteString)" />
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: url)
    }
}
#endif
