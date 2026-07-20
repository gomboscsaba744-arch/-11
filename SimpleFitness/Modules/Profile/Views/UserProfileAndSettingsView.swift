import SwiftUI

// MARK: - 个人中心与全局设置 ("我的"模块独立页面)
public typealias AppSettingsView = UserProfileAndSettingsView

public struct UserProfileAndSettingsView: View {
    @AppStorage("userNickname") private var userNickname: String = "硬核力量先锋"
    @AppStorage("userBio") private var userBio: String = "自律无界 · 每一组都在铸就最强体魄"
    @AppStorage("appThemeMode") private var appThemeMode: String = AppThemeMode.system.rawValue
    @AppStorage("isAutoFlowModeEnabled") private var isAutoFlowModeEnabled: Bool = true
    @AppStorage("autoRestBufferSeconds") private var autoRestBufferSeconds: Int = 10
    @AppStorage("isWatchSimulationEnabled") private var isWatchSimulationEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("soundAlertsEnabled") private var soundAlertsEnabled: Bool = true
    @AppStorage("repCountdownHapticCount") private var repCountdownHapticCount: Int = 3
    @AppStorage("restCountdownHapticSeconds") private var restCountdownHapticSeconds: Int = 5
    @AppStorage("exerciseLanguage") private var exerciseLanguage: String = "zh"
    
    @State private var showingEditProfileModal: Bool = false
    @State private var showingAccountNotice: Bool = false
    @StateObject private var motionLogManager = MotionSensorLogManager.shared
    @State private var shareURLWrapper: ShareSheetURLWrapper? = nil
    
    private let bufferOptions: [Int] = [5, 10, 15, 20, 30]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("我的")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .padding(.top, 8)
                        
                        // 1. 顶部身份与账号预留卡片
                        profileHeaderCard
                        
                        // 2. 身体档案指标网格 (Body Profile Metrics)
                        bodyMetricsGrid
                        
                        Text("系统外观与显示")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 6)
                        
                        // 3. 外观模式设置卡片 (Theme Mode Selector)
                        appearanceSettingsCard
                        
                        Text("多语言与动作显示")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 6)
                        
                        languageSettingsCard
                        
                        Text("训练偏好与设备管理")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 6)
                        
                        // 4. 智能连携与倒计时自动化设置
                        automationSettingsCard
                        
                        // 5. Apple Watch 联动与传感器集成
                        watchIntegrationCard
                        
                        // 5.1 动作陀螺仪与运动学日志下载中心 (独立文件导出)
                        motionSensorLogsExportCard
                        
                        // 6. 触觉反馈与系统提示声音
                        hapticsAndSoundCard
                        
                        // 7. 账号数据与云端说明
                        accountFooterSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("账号同步中心 (即将开放)", isPresented: $showingAccountNotice) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("我们正在开发全端账号通行证与云同步体系。目前您所有设置与训练历史均已通过设备 iCloud 本地安全持久化保存。")
            }
            .sheet(item: $shareURLWrapper) { wrapper in
                ShareSheetModalView(activityItems: [wrapper.url])
            }
        }
    }
    
    // MARK: - 个人名片区域
    private var profileHeaderCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentBlue, Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(userNickname)
                            .font(.title3.weight(.black))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("PRO")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(userBio)
                        .font(.caption)
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    showingAccountNotice = true
                }) {
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.accentBlue)
                        .padding(10)
                        .background(AppColors.pillBackground)
                        .clipShape(Circle())
                }
            }
            
            Divider()
            
            HStack {
                Text("当前状态")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("本地安全离线存储 · 就绪")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 身体档案速览网格
    private var bodyMetricsGrid: some View {
        HStack(spacing: 12) {
            metricBox(title: "体重记录", value: "72.4", unit: "KG", icon: "scalemass.fill", color: .blue)
            metricBox(title: "预估体脂", value: "14.2", unit: "%", icon: "flame.fill", color: .orange)
            metricBox(title: "深蹲最大E1RM", value: "145", unit: "KG", icon: "trophy.fill", color: .yellow)
        }
    }
    
    private func metricBox(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(1)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(unit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .standardCardStyle()
    }
    
    // MARK: - 外观模式设置卡片
    private var appearanceSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("显示外观模式")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("选择您偏好的视觉外观，可随时一键切换为深邃 OLED 深色模式、通透浅色模式或跟随系统。")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 10) {
                ForEach(AppThemeMode.allCases) { mode in
                    let isSelected = appThemeMode == mode.rawValue
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            appThemeMode = mode.rawValue
                            WatchConnectivityService.shared.syncThemeModeToWatch(mode.rawValue)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                            Text(mode.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? .white : AppColors.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                if isSelected {
                                    LinearGradient(
                                        colors: [AppColors.accentBlue, Color.blue.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    AppColors.pillBackground
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isSelected ? Color.white.opacity(0.35) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? AppColors.accentBlue.opacity(0.35) : Color.clear, radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 多语言与动作库显示卡片
    private var languageSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("动作库中英双语热切换")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("实时无缝切换全部 1,324 个训练动作的名称、部位分类、分步要领以及器械说明的显示语言。")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: 12) {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        exerciseLanguage = "zh"
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("🇨🇳")
                            .font(.title3)
                        Text("中文 (默认)")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(exerciseLanguage == "zh" ? AppColors.accentBlue : AppColors.pillBackground)
                    .foregroundColor(exerciseLanguage == "zh" ? .white : AppColors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: exerciseLanguage == "zh" ? AppColors.accentBlue.opacity(0.35) : Color.clear, radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        exerciseLanguage = "en"
                    }
                }) {
                    HStack(spacing: 6) {
                        Text("🇬🇧")
                            .font(.title3)
                        Text("English")
                            .font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(exerciseLanguage == "en" ? AppColors.accentBlue : AppColors.pillBackground)
                    .foregroundColor(exerciseLanguage == "en" ? .white : AppColors.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: exerciseLanguage == "en" ? AppColors.accentBlue.opacity(0.35) : Color.clear, radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 智能连携与倒计时自动化卡片
    private var automationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("训练节奏自动化")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Toggle(isOn: $isAutoFlowModeEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("自动进入组间休息")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                    Text("组数完成时自动倒计时缓冲并进入组间休息。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .tint(AppColors.accentBlue)
            
            if isAutoFlowModeEnabled {
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("自动进入休息前的倒数缓冲时间")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.secondaryText)
                    
                    HStack(spacing: 8) {
                        ForEach(bufferOptions, id: \.self) { sec in
                            Button(action: {
                                withAnimation { autoRestBufferSeconds = sec }
                            }) {
                                Text("\(sec)秒")
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(autoRestBufferSeconds == sec ? AppColors.accentBlue : AppColors.pillBackground)
                                    .foregroundColor(autoRestBufferSeconds == sec ? .white : AppColors.primaryText)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - Watch传感器连携卡片
    private var watchIntegrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .foregroundColor(.green)
                    .font(.subheadline)
                Text("Apple Watch 硬件协同")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Toggle(isOn: $isWatchSimulationEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("手表动作感知与实时遥测")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                    Text("在训练中接收 Apple Watch 手腕运动轨迹与计次置信度数据。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .tint(.green)
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 触觉反馈与系统提示音
    private var hapticsAndSoundCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
                Text("感官触觉反馈")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
            }
            
            Toggle(isOn: $hapticFeedbackEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("高精度触感震动")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                    Text("倒计时结束、完成做组目标时触发 Taptic Engine 沉浸式冲击。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .tint(.orange)
            .onChange(of: appThemeMode) { _, newValue in
                WatchConnectivityService.shared.syncThemeModeToWatch(newValue)
            }
            .onChange(of: hapticFeedbackEnabled) { _, newValue in
                WatchConnectivityService.shared.syncHapticSettings(repCount: repCountdownHapticCount, restSeconds: restCountdownHapticSeconds, enabled: newValue)
            }
            
            if hapticFeedbackEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("做组末尾倒数渐进震动")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                        Picker("做组倒数", selection: $repCountdownHapticCount) {
                            Text("关闭").tag(0)
                            Text("倒数 3 次").tag(3)
                            Text("倒数 5 次").tag(5)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .onChange(of: repCountdownHapticCount) { _, newValue in
                            WatchConnectivityService.shared.syncHapticSettings(repCount: newValue, restSeconds: restCountdownHapticSeconds, enabled: hapticFeedbackEnabled)
                        }
                    }
                    Text("在每组最后几次重复中触发从无到有的渐进增强震动，最后一震明显区隔确认做完。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText.opacity(0.85))
                    
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        Text("休息末尾倒计时震动")
                            .font(.caption.weight(.medium))
                            .foregroundColor(AppColors.secondaryText)
                        Spacer()
                        Picker("休息倒计", selection: $restCountdownHapticSeconds) {
                            Text("关闭").tag(0)
                            Text("最后 3 秒").tag(3)
                            Text("最后 5 秒").tag(5)
                            Text("最后 10 秒").tag(10)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                        .onChange(of: restCountdownHapticSeconds) { _, newValue in
                            WatchConnectivityService.shared.syncHapticSettings(repCount: repCountdownHapticCount, restSeconds: newValue, enabled: hapticFeedbackEnabled)
                        }
                    }
                    Text("在组间休息结束前的最后几秒逐秒轻柔敲击，结束时强震冲锋提示。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText.opacity(0.85))
                }
                .padding(.leading, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(10)
            }
            
            Divider()
            
            Toggle(isOn: $soundAlertsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("关键音效提示")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(AppColors.primaryText)
                    Text("在组间休息仅剩 3 秒时给出清爽蜂鸣倒计时音效。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .tint(.orange)
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 动作陀螺仪与加速度传感器独立日志导出卡片
    private var motionSensorLogsExportCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gyroscope")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.subheadline)
                Text("动作陀螺仪与运动学日志库")
                    .font(.headline)
                    .foregroundColor(AppColors.primaryText)
                Spacer()
                Text("\(motionLogManager.logFiles.count) 份动作文件")
                    .font(.caption.weight(.bold))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Text("开始训练后每个动作自动记录并保存专属 3 轴陀螺仪与加速度计数据，生成标准化 CSV 文件可供分析研究。")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
            
            // 操作排：测试数据 / 批量导出 / 清空
            HStack(spacing: 12) {
                Button(action: {
                    let sampleExercises = ["杠铃平板卧推", "引体向上", "罗马尼亚硬拉", "深蹲", "杠铃划船"]
                    let name = sampleExercises.randomElement() ?? "杠铃平板卧推"
                    motionLogManager.startRecording(exerciseName: name, setNumber: Int.random(in: 1...4))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        motionLogManager.stopRecording()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("测试生成动作日志")
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.pillBackground)
                    .foregroundColor(AppColors.accentBlue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                if !motionLogManager.logFiles.isEmpty {
                    Button(action: {
                        motionLogManager.deleteAllLogs()
                    }) {
                        Text("清空全部")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if motionLogManager.logFiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(AppColors.secondaryText.opacity(0.6))
                    Text("暂无记录文件。训练开始后会自动为每一个动作建档。")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 10) {
                    ForEach(motionLogManager.logFiles.prefix(6)) { fileInfo in
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(AppColors.accentBlue)
                                .font(.subheadline)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(fileInfo.fileName)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(1)
                                Text(String(format: "%@ · 约 %.1f KB", fileInfo.exerciseName, fileInfo.fileSizeKB))
                                    .font(.caption2)
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Spacer(minLength: 8)
                            
                            // 下载 / 导出按钮
                            Button(action: {
                                shareURLWrapper = ShareSheetURLWrapper(url: fileInfo.url)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.doc.fill")
                                    Text("下载导出")
                                }
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(AppColors.accentBlue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(AppColors.pillBackground.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 账号与版本底部
    private var accountFooterSection: some View {
        VStack(spacing: 8) {
            Text("SimpleFitness Core v2.2.0 (Build 2026.07)")
                .font(.caption2)
                .foregroundColor(AppColors.secondaryText)
            Text("账号体系接入模块已就绪 · Ready for Cloud Account API")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.secondaryText.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - 文件分享下载与系统导出支持组件
public struct ShareSheetURLWrapper: Identifiable {
    public let id = UUID()
    public let url: URL
}

public struct ShareSheetModalView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    UserProfileAndSettingsView()
}
