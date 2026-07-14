import Foundation
#if os(watchOS)
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine

/// 单个动作数据结构（支持多动作实时流转与联动）
public struct WatchExerciseItem: Identifiable, Equatable {
    public let id = UUID()
    public var name: String
    public var currentSet: Int
    public var totalSets: Int
    public var targetReps: Int
    public var weightKg: Double
    
    public init(name: String, currentSet: Int = 1, totalSets: Int, targetReps: Int, weightKg: Double) {
        self.name = name
        self.currentSet = currentSet
        self.totalSets = totalSets
        self.targetReps = targetReps
        self.weightKg = weightKg
    }
}

/// Apple Watch S7 核心力量训练控制器（全链路数据联动与多动作实时串联）
public class WatchWorkoutManager: NSObject, ObservableObject {
    public static let shared = WatchWorkoutManager()
    
    @Published public var planTitle: String = "胸肌 & 三头肌训练"
    
    // 完整的课表动作列表（全应用互通联动）
    @Published public var exercises: [WatchExerciseItem] = [
        WatchExerciseItem(name: "哑铃平卧推举", currentSet: 1, totalSets: 4, targetReps: 12, weightKg: 24),
        WatchExerciseItem(name: "上斜杠铃卧推", currentSet: 1, totalSets: 4, targetReps: 10, weightKg: 60),
        WatchExerciseItem(name: "绳索夹胸", currentSet: 1, totalSets: 4, targetReps: 15, weightKg: 15),
        WatchExerciseItem(name: "蝴蝶机夹胸", currentSet: 1, totalSets: 4, targetReps: 12, weightKg: 35),
        WatchExerciseItem(name: "双杠臂屈伸", currentSet: 1, totalSets: 3, targetReps: 15, weightKg: 0)
    ]
    
    @Published public var exerciseIndex: Int = 1 {
        didSet {
            syncCurrentExerciseData()
        }
    }
    
    @Published public var totalExercises: Int = 5
    @Published public var exerciseName: String = "哑铃平卧推举"
    @Published public var currentSet: Int = 1
    @Published public var totalSets: Int = 4
    @Published public var targetReps: Int = 12
    @Published public var currentWeightKg: Double = 24
    
    @Published public var detectedRepCount: Int = 0
    @Published public var showTargetReachedModal: Bool = false
    
    // 训练总结统计数据
    @Published public var showWorkoutSummary: Bool = false
    @Published public var summaryDurationString: String = "42:18"
    @Published public var summaryMaxHeartRate: Int = 168
    @Published public var summaryAvgHeartRate: Int = 135
    @Published public var summaryTotalKcal: Int = 328
    @Published public var summaryCompletedSets: Int = 16
    @Published public var summaryTotalVolumeKg: Int = 1420

    @Published public var isWorkoutRunning: Bool = false
    @Published public var currentHeartRate: Int = 138
    @Published public var activeEnergyKcal: Int = 0
    @Published public var gyroAmplitude: Double = 0.0
    
    @Published public var isResting: Bool = false
    @Published public var restTimeRemaining: Int = 60
    @Published public var totalRestTime: Int = 60
    private var restTimer: Timer?
    private var workoutDurationSeconds: Int = 0
    private var workoutTimer: Timer?
    private var telemetryTimer: Timer?
    private var lastRepDetectTime: Date = Date.distantPast
    private var isRepCycleActive: Bool = false
    private var currentRepStartTime: Date = Date.distantPast
    private var smoothedEnergy: Double = 0.0
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let motionManager = CMMotionManager()
    private var wcSession: WCSession?
    
    private override init() {
        super.init()
        totalExercises = exercises.count
        syncCurrentExerciseData()
        setupWatchConnectivity()
        requestHealthKitPermissions()
    }
    
    /// 同步当前动作数据至主界面属性
    private func syncCurrentExerciseData() {
        guard exerciseIndex >= 1 && exerciseIndex <= exercises.count else { return }
        let current = exercises[exerciseIndex - 1]
        self.exerciseName = current.name
        self.currentSet = current.currentSet
        self.totalSets = current.totalSets
        self.targetReps = current.targetReps
        self.currentWeightKg = current.weightKg
        self.detectedRepCount = 0
    }
    
    /// 切换上一动作
    public func previousExercise() {
        guard exerciseIndex > 1 else { return }
        exerciseIndex -= 1
        WKInterfaceDevice.current().play(.click)
        sendSyncEvent("CHANGE_EXERCISE", extra: ["exerciseIndex": exerciseIndex])
    }
    
    /// 切换下一动作
    public func nextExercise() {
        guard exerciseIndex < exercises.count else { return }
        exerciseIndex += 1
        WKInterfaceDevice.current().play(.click)
        sendSyncEvent("CHANGE_EXERCISE", extra: ["exerciseIndex": exerciseIndex])
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
    }
    
    public func requestHealthKitPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, _ in }
    }
    
    public func adjustRepCount(by delta: Int) {
        let newCount = max(0, detectedRepCount + delta)
        guard newCount != detectedRepCount else { return }
        detectedRepCount = newCount
        
        if detectedRepCount == targetReps {
            showTargetReachedModal = true
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                WKInterfaceDevice.current().play(.notification)
            }
        } else if detectedRepCount > targetReps {
            WKInterfaceDevice.current().play(.directionUp)
        } else {
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private var workoutStartTime: Date?
    
    public func startWorkoutSession(syncToPhone: Bool = true) {
        guard !isWorkoutRunning else { return }
        isWorkoutRunning = true
        showWorkoutSummary = false
        isResting = false
        exerciseIndex = 1
        detectedRepCount = 0
        activeEnergyKcal = 0
        showTargetReachedModal = false
        workoutDurationSeconds = 0
        workoutStartTime = Date()
        
        startHealthKitWorkoutSession()
        startMotionSensorMonitoring()
        
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isWorkoutRunning else { return }
            self.workoutDurationSeconds += 1
            if self.workoutDurationSeconds % 8 == 0 && self.workoutBuilder == nil {
                self.activeEnergyKcal += 1
            }
        }
        
        telemetryTimer?.invalidate()
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, self.isWorkoutRunning else { return }
            self.sendTelemetryToPhone()
        }
        
        WKInterfaceDevice.current().play(.start)
        if syncToPhone {
            sendSyncEvent("START_WORKOUT", extra: ["exerciseName": exerciseName])
        }
    }
    
    public func endWorkoutSession(syncToPhone: Bool = true) {
        isWorkoutRunning = false
        isResting = false
        showTargetReachedModal = false
        restTimer?.invalidate()
        restTimer = nil
        workoutTimer?.invalidate()
        workoutTimer = nil
        telemetryTimer?.invalidate()
        telemetryTimer = nil
        stopMotionSensorMonitoring()
        endHealthKitWorkoutSession()
        
        let elapsed = workoutStartTime != nil ? Int(Date().timeIntervalSince(workoutStartTime!)) : workoutDurationSeconds
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        summaryDurationString = String(format: "%02d:%02d", minutes, seconds)
        summaryMaxHeartRate = max(currentHeartRate, 142)
        summaryAvgHeartRate = currentHeartRate
        summaryTotalKcal = max(activeEnergyKcal, 1)
        summaryCompletedSets = exercises.reduce(0) { $0 + max(0, $1.currentSet - 1) }
        showWorkoutSummary = true
        
        WKInterfaceDevice.current().play(.success)
        if syncToPhone {
            sendSyncEvent("END_WORKOUT", extra: [
                "duration": summaryDurationString,
                "totalKcal": summaryTotalKcal,
                "completedSets": summaryCompletedSets
            ])
        }
    }
    
    public func dismissSummary() {
        showWorkoutSummary = false
    }
    
    public func completeCurrentSet() {
        showTargetReachedModal = false
        WKInterfaceDevice.current().play(.success)
        
        // 更新当前动作所完成的组数，若全套做完则自动推进到下一动作
        if exerciseIndex >= 1 && exerciseIndex <= exercises.count {
            exercises[exerciseIndex - 1].currentSet += 1
            if exercises[exerciseIndex - 1].currentSet > exercises[exerciseIndex - 1].totalSets {
                if exerciseIndex < exercises.count {
                    exerciseIndex += 1
                }
            } else {
                currentSet = exercises[exerciseIndex - 1].currentSet
            }
        }
        
        startRestPeriod(seconds: 60)
    }
    
    public func startRestPeriod(seconds: Int = 60) {
        restTimer?.invalidate()
        totalRestTime = seconds
        restTimeRemaining = seconds
        isResting = true
        showTargetReachedModal = false
        sendSyncEvent("START_REST", extra: ["seconds": seconds, "currentSet": currentSet])
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.restTimeRemaining > 1 {
                self.restTimeRemaining -= 1
                if self.restTimeRemaining <= 3 {
                    WKInterfaceDevice.current().play(.click)
                }
            } else {
                self.finishRestPeriod()
            }
        }
    }
    
    public func skipRestPeriod() {
        finishRestPeriod()
    }
    
    public func addRestTime(_ seconds: Int) {
        restTimeRemaining = max(0, restTimeRemaining + seconds)
        totalRestTime = max(totalRestTime, restTimeRemaining)
        WKInterfaceDevice.current().play(.click)
    }
    
    private func finishRestPeriod() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        detectedRepCount = 0
        WKInterfaceDevice.current().play(.start)
        sendSyncEvent("FINISH_REST")
    }
    
    private func startMotionSensorMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.033
        isRepCycleActive = false
        smoothedEnergy = 0.0
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let rotation = motion.rotationRate
            let rotMag = sqrt(rotation.x*rotation.x + rotation.y*rotation.y + rotation.z*rotation.z)
            let acc = motion.userAcceleration
            let accMag = sqrt(acc.x*acc.x + acc.y*acc.y + acc.z*acc.z)
            
            // 结合角速度(转动)与线性加速度(推拉位移)构建复合动能信号
            // 指数移动平均(EMA)平滑消除短暂手部抖动与小幅晃动毛刺
            let rawEnergy = rotMag + accMag * 3.6
            self.smoothedEnergy = self.smoothedEnergy * 0.72 + rawEnergy * 0.28
            self.gyroAmplitude = self.smoothedEnergy
            
            guard self.isWorkoutRunning && !self.isResting else { return }
            let now = Date()
            
            // 双向迟滞波峰-波谷状态机判定：
            // 1. 启动动作发力判定 (1.45 能量阈值) 且已过发力冷却期
            if !self.isRepCycleActive {
                if self.smoothedEnergy > 1.45 && now.timeIntervalSince(self.lastRepDetectTime) > 1.05 {
                    self.isRepCycleActive = true
                    self.currentRepStartTime = now
                }
            } else {
                // 2. 动作收尾回归波谷 (能量降至 1.05 以下)
                if self.smoothedEnergy < 1.05 {
                    let repDuration = now.timeIntervalSince(self.currentRepStartTime)
                    self.isRepCycleActive = false
                    // 仅当动作发力持续时间在卧推/推拉有效区间 [0.6s, 5.0s] 计为有效 1 次，过滤短瞬时误触
                    if repDuration >= 0.6 && repDuration <= 5.0 {
                        self.lastRepDetectTime = now
                        self.adjustRepCount(by: 1)
                    }
                } else if now.timeIntervalSince(self.currentRepStartTime) > 6.0 {
                    self.isRepCycleActive = false
                }
            }
        }
    }
    
    public func sendSyncEvent(_ action: String, extra: [String: Any] = [:]) {
        guard let session = wcSession, session.activationState == .activated else { return }
        var payload = extra
        payload["action"] = action
        payload["timestamp"] = Date().timeIntervalSince1970
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            try? session.updateApplicationContext(payload)
        }
    }
    
    private func stopMotionSensorMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func startHealthKitWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            print("HKWorkoutSession setup failed: \(error)")
        }
    }
    
    private func endHealthKitWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.workoutBuilder?.finishWorkout { _, _ in }
        }
    }
    
    private func sendTelemetryToPhone() {
        guard let session = wcSession, session.activationState == .activated else { return }
        let telemetry: [String: Any] = [
            "heartRate": currentHeartRate,
            "calories": activeEnergyKcal,
            "detectedRepCount": detectedRepCount,
            "gyroAmplitude": gyroAmplitude,
            "currentSet": currentSet,
            "totalSets": totalSets,
            "exerciseIndex": exerciseIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
        if session.isReachable {
            session.sendMessage(telemetry, replyHandler: nil, errorHandler: nil)
        }
    }
}

extension WatchWorkoutManager: WCSessionDelegate {
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        applyIncomingPayload(message)
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applyIncomingPayload(applicationContext)
    }
    
    private func applyIncomingPayload(_ message: [String: Any]) {
        DispatchQueue.main.async {
            let actionOrCommand = (message["action"] as? String) ?? (message["command"] as? String)
            if let cmd = actionOrCommand {
                switch cmd {
                case "START_WORKOUT_SESSION", "START_WORKOUT":
                    self.startWorkoutSession(syncToPhone: false)
                case "CHANGE_EXERCISE":
                    if let index = message["exerciseIndex"] as? Int, index >= 1 && index <= self.exercises.count {
                        self.exerciseIndex = index
                    }
                case "START_REST":
                    let seconds = message["seconds"] as? Int ?? 60
                    self.startRestPeriod(seconds: seconds)
                case "FINISH_REST":
                    self.skipRestPeriod()
                case "END_WORKOUT", "END_WORKOUT_SESSION", "STOP_WORKOUT_SESSION":
                    self.endWorkoutSession(syncToPhone: false)
                default:
                    break
                }
            }
            
            if let plan = message["planTitle"] as? String {
                self.planTitle = plan
            }
            if let ex = message["exerciseName"] as? String {
                self.exerciseName = ex
                if let matchIndex = self.exercises.firstIndex(where: { $0.name == ex }) {
                    self.exerciseIndex = matchIndex + 1
                } else if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].name = ex
                }
            }
            if let reps = message["targetReps"] as? Int {
                self.targetReps = reps
                if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].targetReps = reps
                }
            }
            if let cSet = message["currentSet"] as? Int {
                self.currentSet = cSet
                if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].currentSet = cSet
                }
            }
            if let tSets = message["totalSets"] as? Int {
                self.totalSets = tSets
                if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].totalSets = tSets
                }
            }
            if let weight = message["targetWeightKg"] as? Double {
                self.currentWeightKg = weight
                if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].weightKg = weight
                }
            }
            if let isResting = message["isResting"] as? Bool {
                if isResting && !self.isResting {
                    self.startRestPeriod(seconds: message["restSeconds"] as? Int ?? 60)
                } else if !isResting && self.isResting {
                    self.skipRestPeriod()
                }
            }
        }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            if let statistics = workoutBuilder.statistics(for: quantityType) {
                DispatchQueue.main.async {
                    if quantityType == HKQuantityType(.heartRate),
                       let value = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                        self.currentHeartRate = Int(value)
                    }
                    if quantityType == HKQuantityType(.activeEnergyBurned),
                       let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        self.activeEnergyKcal = Int(value)
                    }
                }
            }
        }
    }
}
#endif
