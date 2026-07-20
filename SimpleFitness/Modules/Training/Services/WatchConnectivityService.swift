import Foundation
import WatchConnectivity
import Combine
import HealthKit
#if os(iOS)
import UIKit
#endif

/// 与 Apple Watch S7 双向通信的核心总线服务类
/// 负责管理 WCSession、透传体能训练会话指令以及接收高频实时心率、卡路里与 S7 陀螺仪运动学遥测数据
public class WatchConnectivityService: NSObject, ObservableObject {
    public static let shared = WatchConnectivityService()
    
    #if os(iOS)
    private var effectiveThemeModeForWatch: String {
        let saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "system"
        if saved == "system" {
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
        }
        return saved
    }
    #else
    private var effectiveThemeModeForWatch: String {
        return UserDefaults.standard.string(forKey: "appThemeMode") ?? "system"
    }
    #endif
    
    @Published public var isWatchReachable: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    
    // 实时遥测指标（初始设为 0，收到 Apple Watch 真实传感器包后动态驱动更新）
    @Published public var currentHeartRate: Int = 0
    @Published public var activeEnergyBurnedKcal: Int = 0
    @Published public var detectedRepCount: Int = 0
    @Published public var repConfidence: Double = 0.0
    @Published public var gyroAmplitude: Double = 0.0
    @Published public var motionStability: String = "等待表端连入"
    
    // 标记当前是否正在由表端遥测驱动更新计次，防止手机端 onChange 误回回滚
    public var isUpdatingFromWatch: Bool = false
    
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
        isResting: Bool,
        restSeconds: Int = 60
    ) {
        DispatchQueue.main.async {
            self.syncedCurrentSet = currentSet
            self.syncedTotalSets = totalSets
            self.syncedIsResting = isResting
            self.syncedRestSeconds = restSeconds
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let matchedExercise = ExerciseMockData.sampleItems.first {
                $0.nameZh == exerciseName || $0.name == exerciseName || $0.nameEn.lowercased() == exerciseName.lowercased() || exerciseName.contains($0.nameZh)
            }
            let payload: [String: Any] = [
                "command": "SYNC_WORKOUT_STATE",
                "exerciseName": exerciseName,
                "currentSet": currentSet,
                "totalSets": totalSets,
                "targetReps": targetReps,
                "targetWeightKg": targetWeightKg,
                "isResting": isResting,
                "restSeconds": restSeconds,
                "dominantAxis": matchedExercise?.dominantAxis ?? 1,
                "minRatio": matchedExercise?.minRatio ?? 0.35,
                "thresholdG": matchedExercise?.thresholdG ?? "+0.50g",
                "motionProfile": matchedExercise?.motionProfile ?? "upperBodyPull",
                "repCountdownHapticCount": UserDefaults.standard.object(forKey: "repCountdownHapticCount") as? Int ?? 3,
                "restCountdownHapticSeconds": UserDefaults.standard.object(forKey: "restCountdownHapticSeconds") as? Int ?? 5,
                "hapticFeedbackEnabled": UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true,
                "appThemeMode": self.effectiveThemeModeForWatch,
                "timestamp": Date().timeIntervalSince1970
            ]
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
    }
    
    /// 同步当前动作已记录次数给 Watch，确保手机改次数（如清0）后手表立刻对齐
    public func syncRepCountToWatch(_ repCount: Int, isUserInitiated: Bool = false) {
        if isUpdatingFromWatch && !isUserInitiated {
            return
        }
        DispatchQueue.main.async {
            self.detectedRepCount = repCount
        }
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let payload: [String: Any] = [
                "command": "SYNC_REP_COUNT",
                "detectedRepCount": repCount,
                "appThemeMode": self.effectiveThemeModeForWatch,
                "timestamp": Date().timeIntervalSince1970
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(payload)
                session.transferUserInfo(payload)
            }
        }
    }
    
    /// 同步触觉反馈设置至 Watch
    public func syncHapticSettings(repCount: Int, restSeconds: Int, enabled: Bool) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let payload: [String: Any] = [
                "command": "SYNC_HAPTIC_SETTINGS",
                "repCountdownHapticCount": repCount,
                "restCountdownHapticSeconds": restSeconds,
                "hapticFeedbackEnabled": enabled,
                "appThemeMode": self.effectiveThemeModeForWatch,
                "timestamp": Date().timeIntervalSince1970
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(payload)
                session.transferUserInfo(payload)
            }
        }
    }
    
    /// 同步深浅模式主题配置至 Watch
    public func syncThemeModeToWatch(_ themeMode: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let payload: [String: Any] = [
                "command": "SYNC_THEME_MODE",
                "appThemeMode": self.effectiveThemeModeForWatch,
                "timestamp": Date().timeIntervalSince1970
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(payload)
                session.transferUserInfo(payload)
            }
        }
    }
    
    /// 发送唤醒 Apple Watch 启动体能训练高频监测的指令
    public func startWatchWorkoutSession(exerciseTitle: String) {
        #if os(iOS)
        DispatchQueue.global(qos: .utility).async {
            if HKHealthStore.isHealthDataAvailable() {
                let config = HKWorkoutConfiguration()
                config.activityType = .traditionalStrengthTraining
                config.locationType = .indoor
                let healthStore = HKHealthStore()
                healthStore.startWatchApp(with: config) { success, error in
                    #if DEBUG
                    if let error = error {
                        print("[WatchConnectivityService] startWatchApp 唤醒手表应用轻微提示: \(error.localizedDescription)")
                    } else {
                        print("[WatchConnectivityService] startWatchApp 成功唤醒 Apple Watch 应用并启动监测")
                    }
                    #endif
                }
            }
        }
        #endif
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let matchedExercise = ExerciseMockData.sampleItems.first {
                $0.nameZh == exerciseTitle || $0.name == exerciseTitle || $0.nameEn.lowercased() == exerciseTitle.lowercased() || exerciseTitle.contains($0.nameZh)
            }
            let payload: [String: Any] = [
                "command": "START_WORKOUT_SESSION",
                "exerciseTitle": exerciseTitle,
                "exerciseName": exerciseTitle,
                "dominantAxis": matchedExercise?.dominantAxis ?? 1,
                "minRatio": matchedExercise?.minRatio ?? 0.35,
                "thresholdG": matchedExercise?.thresholdG ?? "+0.50g",
                "motionProfile": matchedExercise?.motionProfile ?? "upperBodyPull",
                "appThemeMode": self.effectiveThemeModeForWatch,
                "timestamp": Date().timeIntervalSince1970
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(payload)
                session.transferUserInfo(payload)
            }
        }
    }
    
    /// 发送结束 Apple Watch 体能训练指令
    public func endWatchWorkoutSession() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self, let session = self.wcSession, session.activationState == .activated else { return }
            let payload: [String: Any] = [
                "command": "END_WORKOUT_SESSION",
                "timestamp": Date().timeIntervalSince1970
            ]
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            } else {
                try? session.updateApplicationContext(payload)
            }
        }
    }
    
    @Published public var syncedExerciseIndex: Int = 1
    @Published public var syncedCurrentSet: Int = 1
    @Published public var syncedTotalSets: Int = 4
    @Published public var syncedIsResting: Bool = false
    @Published public var syncedRestSeconds: Int = 60
    @Published public var syncedIsWorkoutStarted: Bool = false
    @Published public var syncedIsWorkoutEnded: Bool = false

    /// 解析表端遥测字典
    private func applyIncomingTelemetry(_ userInfo: [String: Any]) {
        DispatchQueue.main.async {
            let actionOrCommand = (userInfo["action"] as? String) ?? (userInfo["command"] as? String)
            if let action = actionOrCommand {
                switch action {
                case "START_WORKOUT", "START_WORKOUT_SESSION":
                    self.syncedIsWorkoutStarted = true
                    self.syncedIsWorkoutEnded = false
                case "CHANGE_EXERCISE":
                    if let index = userInfo["exerciseIndex"] as? Int {
                        self.syncedExerciseIndex = index
                    }
                    if let set = userInfo["currentSet"] as? Int {
                        self.syncedCurrentSet = set
                    }
                case "CHANGE_SET":
                    if let set = userInfo["currentSet"] as? Int {
                        self.syncedCurrentSet = set
                    }
                    if let index = userInfo["exerciseIndex"] as? Int {
                        self.syncedExerciseIndex = index
                    }
                case "START_REST":
                    self.syncedIsResting = true
                    if let sec = userInfo["seconds"] as? Int {
                        self.syncedRestSeconds = sec
                    }
                    if let set = userInfo["currentSet"] as? Int {
                        self.syncedCurrentSet = set
                    }
                    if let index = userInfo["exerciseIndex"] as? Int {
                        self.syncedExerciseIndex = index
                    }
                case "FINISH_REST":
                    self.syncedIsResting = false
                case "REP_DETECTED":
                    if let rep = userInfo["detectedRepCount"] as? Int {
                        self.isUpdatingFromWatch = true
                        self.detectedRepCount = rep
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            self.isUpdatingFromWatch = false
                        }
                    }
                case "END_WORKOUT", "END_WORKOUT_SESSION":
                    self.syncedIsWorkoutEnded = true
                    self.syncedIsWorkoutStarted = false
                default:
                    break
                }
            }
            if let heartRate = userInfo["heartRate"] as? Int {
                self.currentHeartRate = heartRate
            }
            if let calories = userInfo["calories"] as? Int {
                self.activeEnergyBurnedKcal = calories
            }
            if let repCount = userInfo["detectedRepCount"] as? Int {
                self.isUpdatingFromWatch = true
                self.detectedRepCount = repCount
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.isUpdatingFromWatch = false
                }
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
            if activationState == .activated {
                self.syncThemeModeToWatch(self.effectiveThemeModeForWatch)
            }
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
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        applyIncomingTelemetry(userInfo)
    }
    
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let metadata = file.metadata ?? [:]
        let originalName = (metadata["originalFileName"] as? String) ?? file.fileURL.lastPathComponent
        MotionSensorLogManager.shared.importExternalLogFile(at: file.fileURL, originalFileName: originalName)
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
