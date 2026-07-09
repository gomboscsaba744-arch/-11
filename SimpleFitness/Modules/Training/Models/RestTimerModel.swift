import Foundation
import SwiftUI

/// 组间休息倒计时核心状态模型 (支持最大 30 分钟/6 圈无极层递、双轨圈层美学)
public struct RestTimerModel {
    /// 默认分配给当前动作的休息总时长（秒），默认 90 秒
    public var defaultDuration: Int = 90
    /// 当前设置的倒计时总长度（秒，最大 1800 秒即 30 分钟）
    public var totalDuration: Int = 90
    /// 当前剩余精确时间（秒，支持小数以实现 33fps 连续流走）
    public var remainingTime: Double = 90.0
    /// 是否正在倒计时运行中
    public var isRunning: Bool = false
    /// 是否开启全屏浮空巨型表盘（虚化背景，无边界悬浮）
    public var isPrecisionZoomed: Bool = false
    
    public init(defaultDuration: Int = 90) {
        self.defaultDuration = defaultDuration
        self.totalDuration = defaultDuration
        self.remainingTime = Double(defaultDuration)
    }
    
    /// 格式化显示分:秒 (如 01:30)
    public var formattedTimeString: String {
        let displaySeconds = max(0, Int(ceil(remainingTime)))
        let minutes = displaySeconds / 60
        let seconds = displaySeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 当前圈数 (1~6 圈，每圈 5 分钟 = 300 秒)
    public var currentLap: Int {
        let lap = (totalDuration - 1) / 300 + 1
        return max(1, min(6, lap))
    }
    
    /// 当前圈内的进度百分比 (0.0 ~ 1.0)
    public var lapProgress: Double {
        let remainder = Double(totalDuration % 300)
        if remainder == 0 && totalDuration > 0 {
            return 1.0
        }
        return remainder / 300.0
    }
    
    /// 倒计时运行时的总体进度 (0.0 ~ 1.0)
    public var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0.0, min(1.0, remainingTime / Double(totalDuration)))
    }
    
    /// 重置为当前设定总时长
    public mutating func reset() {
        isRunning = false
        remainingTime = Double(totalDuration)
    }
    
    /// 增加或减少总时长
    public mutating func adjustDuration(by deltaSeconds: Int) {
        let newDuration = max(10, min(1800, totalDuration + deltaSeconds))
        totalDuration = newDuration
        if !isRunning {
            remainingTime = Double(newDuration)
        } else {
            remainingTime = max(0, remainingTime + Double(deltaSeconds))
        }
    }
}
