import SwiftUI

/// 呈现 Apple Watch 记录次数与手腕陀螺仪动作幅度的遥感卡片视图
/// 独立模块化解耦：预留了与 CoreMotion 及 HealthKit 实时通讯的总线对接接口
public struct WatchSensorTelemetryCardView: View {
    public var telemetry: WatchSensorTelemetryModel
    
    public init(telemetry: WatchSensorTelemetryModel) {
        self.telemetry = telemetry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 顶部状态导视栏
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .font(.subheadline)
                        .foregroundColor(AppColors.accentBlue)
                    Text("Watch 动作检测与陀螺仪")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(telemetry.isWatchConnected ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                    Text(telemetry.isWatchConnected ? "已连接 · 实时同步" : "未连接")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(telemetry.isWatchConnected ? .green : .secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColors.pillBackground)
                .clipShape(Capsule())
            }
            
            // 核心监测指标分列卡
            HStack(spacing: 12) {
                // 指标卡 1：手表示教次数与置信度
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(AppColors.accentBlue)
                        Text("手表自动计次")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(telemetry.detectedRepCount)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                            .monospacedDigit()
                        Text("次")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Text(String(format: "识别置信度 %.0f%%", telemetry.repDetectionConfidence * 100))
                        .font(.caption2)
                        .foregroundColor(AppColors.accentBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.pillBackground)
                .cornerRadius(12)
                
                // 指标卡 2：三轴角速度与轨迹稳定度
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "gyroscope")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("陀螺仪峰值振幅")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "±%.1f", telemetry.gyroscopeAmplitudeDegPerSec))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                            .monospacedDigit()
                        Text("°/s")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Text(telemetry.motionTrajectoryStabilityString)
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.pillBackground)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}
