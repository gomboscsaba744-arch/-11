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
    public let name: String
    public var currentSet: Int
    public let totalSets: Int
    public let targetReps: Int
    public let weightKg: Double
    
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
    @Published public var activeEnergyKcal: Int = 45
    @Published public var gyroAmplitude: Double = 0.0
    
    @Published public var isResting: Bool = false
    @Published public var restTimeRemaining: Int = 60
    @Published public var totalRestTime: Int = 60
    private var restTimer: Timer?
    private var workoutDurationSeconds: Int = 0
    private var workoutTimer: Timer?
    
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
    
    public func startWorkoutSession() {
        guard !isWorkoutRunning else { return }
        isWorkoutRunning = true
        showWorkoutSummary = false
        isResting = false
        exerciseIndex = 1
        detectedRepCount = 0
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
            self.sendTelemetryToPhone()
        }
        
        WKInterfaceDevice.current().play(.start)
    }
    
    public func endWorkoutSession() {
        isWorkoutRunning = false
        isResting = false
        showTargetReachedModal = false
        restTimer?.invalidate()
        restTimer = nil
        workoutTimer?.invalidate()
        workoutTimer = nil
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
        sendSyncEvent("END_WORKOUT", extra: [
            "duration": summaryDurationString,
            "totalKcal": summaryTotalKcal,
            "completedSets": summaryCompletedSets
        ])
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
        motionManager.deviceMotionUpdateInterval = 0.2
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let rotation = motion.rotationRate
            let mag = sqrt(rotation.x*rotation.x + rotation.y*rotation.y + rotation.z*rotation.z)
            self.gyroAmplitude = mag
            if mag > 3.8 && self.isWorkoutRunning && !self.isResting {
                self.adjustRepCount(by: 1)
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
        DispatchQueue.main.async {
            if let action = message["action"] as? String {
                switch action {
                case "CHANGE_EXERCISE":
                    if let index = message["exerciseIndex"] as? Int, index >= 1 && index <= self.exercises.count {
                        self.exerciseIndex = index
                    }
                case "START_REST":
                    let seconds = message["seconds"] as? Int ?? 60
                    self.startRestPeriod(seconds: seconds)
                case "FINISH_REST":
                    self.skipRestPeriod()
                case "END_WORKOUT":
                    self.endWorkoutSession()
                default:
                    break
                }
            }
            if let plan = message["planTitle"] as? String { self.planTitle = plan }
            if let ex = message["exerciseName"] as? String { self.exerciseName = ex }
            if let reps = message["targetReps"] as? Int { self.targetReps = reps }
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
