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
    /// 是否处于倒计时暂停状态
    public var isPaused: Bool = false
    /// 是否开启全屏浮空巨型表盘（虚化背景，无边界悬浮）
    public var isPrecisionZoomed: Bool = false
    /// 是否为“动作间切换休息”（而非普通组间休息）
    public var isExerciseRestPhase: Bool = false
    /// 动作间休息即将过渡到的新动作名称
    public var nextExerciseTitle: String? = nil
    
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
    
    /// 真实物理时钟锚点（消除主线程帧率抖动导致的先慢后快）
    public var targetEndTime: Date? = nil
    
    /// 核心计时器滴答更新（绑定真实 Date 时间流逝）
    public mutating func tick() {
        guard isRunning else { return }
        if targetEndTime == nil {
            targetEndTime = Date().addingTimeInterval(remainingTime)
        }
        if let target = targetEndTime {
            let left = target.timeIntervalSinceNow
            if left <= 0 {
                remainingTime = 0
                isRunning = false
                isPaused = false
                targetEndTime = nil
            } else {
                remainingTime = left
            }
        }
    }
    
    /// 启动倒计时
    public mutating func start() {
        isRunning = true
        isPaused = false
        targetEndTime = Date().addingTimeInterval(remainingTime)
    }
    
    /// 暂停倒计时
    public mutating func pause() {
        isRunning = false
        isPaused = true
        targetEndTime = nil
    }
    
    /// 继续倒计时
    public mutating func resume() {
        isRunning = true
        isPaused = false
        targetEndTime = Date().addingTimeInterval(remainingTime)
    }
    
    /// 重置为当前设定总时长
    public mutating func reset() {
        isRunning = false
        isPaused = false
        remainingTime = Double(totalDuration)
        targetEndTime = nil
    }
    
    /// 增加或减少总时长
    public mutating func adjustDuration(by deltaSeconds: Int) {
        let newDuration = max(10, min(1800, totalDuration + deltaSeconds))
        totalDuration = newDuration
        defaultDuration = newDuration
        if !isRunning {
            remainingTime = Double(newDuration)
            targetEndTime = nil
        } else {
            remainingTime = max(0, remainingTime + Double(deltaSeconds))
            targetEndTime = Date().addingTimeInterval(remainingTime)
        }
    }
}
