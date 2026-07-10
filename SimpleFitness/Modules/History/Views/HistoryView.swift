import SwiftUI

public struct HistoryView: View {
    private let records: [HistoryRecordMock] = HistoryMockData.sampleRecords
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("训练历史与成果")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .padding(.top, 8)
                        
                        Text("本周概览")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        WeeklySummaryView()
                        
                        Text("近期记录 (支持 CloudKit iCloud 云同步)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                HistoryRecordRowView(record: record)
                                    .padding(.horizontal, 16)
                                
                                if index < records.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .standardCardStyle()
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - 个人中心与全局设置 ("我的"页面)
public typealias AppSettingsView = UserProfileAndSettingsView

public struct UserProfileAndSettingsView: View {
    @AppStorage("userNickname") private var userNickname: String = "硬核力量先锋"
    @AppStorage("userBio") private var userBio: String = "自律无界 · 每一组都在铸就最强体魄"
    @AppStorage("isAutoFlowModeEnabled") private var isAutoFlowModeEnabled: Bool = true
    @AppStorage("autoRestBufferSeconds") private var autoRestBufferSeconds: Int = 10
    @AppStorage("isWatchSimulationEnabled") private var isWatchSimulationEnabled: Bool = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @AppStorage("soundAlertsEnabled") private var soundAlertsEnabled: Bool = true
    
    @State private var showingEditProfileModal: Bool = false
    @State private var showingAccountNotice: Bool = false
    
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
                        
                        // 1. 顶部身份与账号预留卡片 (支持后续对接账户中心)
                        profileHeaderCard
                        
                        // 2. 身体档案指标网格 (Body Profile Metrics)
                        bodyMetricsGrid
                        
                        Text("训练偏好与设备管理")
                            .font(.headline)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 6)
                        
                        // 4. 智能连携与倒计时自动化设置 (已集成之前的设置)
                        automationSettingsCard
                        
                        // 5. Apple Watch 联动与传感器集成
                        watchIntegrationCard
                        
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
            
            // 绑定账号提示横幅
            Button(action: { showingAccountNotice = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    Text("当前处于单机离线极速模式 · 预留云通行证绑定接口")
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .padding(18)
        .standardCardStyle()
    }
    
    // MARK: - 身体基础指标网格
    private var bodyMetricsGrid: some View {
        HStack(spacing: 12) {
            metricBox(title: "体重", value: "72.5", unit: "kg", icon: "scalemass.fill", color: AppColors.accentBlue)
            metricBox(title: "体脂参考", value: "14.5", unit: "%", icon: "chart.pie.fill", color: .orange)
            metricBox(title: "身高", value: "178", unit: "cm", icon: "ruler.fill", color: .green)
        }
    }
    
    private func metricBox(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Spacer()
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Text(unit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .standardCardStyle()
    }
    
    // MARK: - 智能连携与倒计时自动化卡片
    private var automationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                    .font(.headline)
                Text("智能连携与倒计时自动化")
                    .font(.headline)
            }
            
            Toggle("启用自动流转模式 (Auto-Flow)", isOn: $isAutoFlowModeEnabled)
                .font(.subheadline.weight(.semibold))
                .tint(.orange)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("次数达标缓冲倒计时秒数")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("当单组动作完成目标次数后，系统提供缓冲等待时间，您可在缓冲期选择立即休息或改回手动模式。")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                HStack(spacing: 10) {
                    ForEach(bufferOptions, id: \.self) { seconds in
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            autoRestBufferSeconds = seconds
                        }) {
                            Text("\(seconds)秒")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(autoRestBufferSeconds == seconds ? Color.orange : AppColors.pillBackground)
                                .foregroundColor(autoRestBufferSeconds == seconds ? .white : AppColors.primaryText)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - Apple Watch 联动
    private var watchIntegrationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(AppColors.accentBlue)
                    .font(.headline)
                Text("Apple Watch 硬件联动与监测")
                    .font(.headline)
            }
            
            Toggle("开启 Watch 自动记数待命模式", isOn: $isWatchSimulationEnabled)
                .font(.subheadline.weight(.semibold))
                .tint(AppColors.accentBlue)
            
            Text("支持连接 Apple Watch 实时体态传感器计次。在开发就绪前，您可以直接通过训练页面次数卡片左右按钮进行高保真计次仿真。")
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(20)
        .standardCardStyle()
    }
    
    // MARK: - 触觉与声音反馈
    private var hapticsAndSoundCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.green)
                    .font(.headline)
                Text("触觉与声音提示偏好")
                    .font(.headline)
            }
            
            Toggle("动作达标强烈震动提示", isOn: $hapticFeedbackEnabled)
                .font(.subheadline.weight(.semibold))
                .tint(.green)
            
            Divider()
            
            Toggle("进阶与倒计时结束声效反馈", isOn: $soundAlertsEnabled)
                .font(.subheadline.weight(.semibold))
                .tint(.green)
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

#Preview {
    UserProfileAndSettingsView()
}
