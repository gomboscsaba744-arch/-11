import Foundation
import WatchConnectivity
import Combine

/// 与 Apple Watch S7 双向通信的核心总线服务类
/// 负责管理 WCSession、透传体能训练会话指令以及接收高频实时心率、卡路里与 S7 陀螺仪运动学遥测数据
public class WatchConnectivityService: NSObject, ObservableObject {
    public static let shared = WatchConnectivityService()
    
    @Published public var isWatchReachable: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    
    // 实时遥测指标（默认初始对齐模拟初值，收到表端实时包后平滑更新）
    @Published public var currentHeartRate: Int = 124
    @Published public var activeEnergyBurnedKcal: Int = 186
    @Published public var detectedRepCount: Int = 10
    @Published public var repConfidence: Double = 0.98
    @Published public var gyroAmplitude: Double = 42.6
    @Published public var motionStability: String = "优 (发力向心稳定)"
    
    private var wcSession: WCSession?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
    }
    
    /// 向 Apple Watch 发送同步当前训练上下文数据
    public func syncWorkoutStateToWatch(
        exerciseName: String,
        currentSet: Int,
        totalSets: Int,
        targetReps: Int,
        targetWeightKg: Double,
        isResting: Bool
    ) {
        guard let session = wcSession, session.activationState == .activated else { return }
        
        let payload: [String: Any] = [
            "command": "SYNC_WORKOUT_STATE",
            "exerciseName": exerciseName,
            "currentSet": currentSet,
            "totalSets": totalSets,
            "targetReps": targetReps,
            "targetWeightKg": targetWeightKg,
            "isResting": isResting,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 尝试即时消息透传，如果手腕不可达则写进上下文同步
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                #if DEBUG
                print("[WatchConnectivityService] 即时消息传输轻微延迟: \(error.localizedDescription)")
                #endif
            }
        } else {
            do {
                try session.updateApplicationContext(payload)
            } catch {
                #if DEBUG
                print("[WatchConnectivityService] ApplicationContext 更新失败: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    /// 发送唤醒 Apple Watch 启动体能训练高频监测的指令
    public func startWatchWorkoutSession(exerciseTitle: String) {
        guard let session = wcSession, session.activationState == .activated else { return }
        let payload: [String: Any] = [
            "command": "START_WORKOUT_SESSION",
            "exerciseTitle": exerciseTitle,
            "timestamp": Date().timeIntervalSince1970
        ]
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    /// 解析表端遥测字典
    private func applyIncomingTelemetry(_ userInfo: [String: Any]) {
        DispatchQueue.main.async {
            if let heartRate = userInfo["heartRate"] as? Int {
                self.currentHeartRate = heartRate
            }
            if let calories = userInfo["calories"] as? Int {
                self.activeEnergyBurnedKcal = calories
            }
            if let repCount = userInfo["detectedRepCount"] as? Int {
                self.detectedRepCount = repCount
            }
            if let confidence = userInfo["repConfidence"] as? Double {
                self.repConfidence = confidence
            }
            if let gyro = userInfo["gyroAmplitude"] as? Double {
                self.gyroAmplitude = gyro
            }
            if let stability = userInfo["motionStability"] as? String {
                self.motionStability = stability
            }
            self.isWatchReachable = true
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            #if os(iOS)
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
        }
    }
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        applyIncomingTelemetry(message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applyIncomingTelemetry(applicationContext)
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
