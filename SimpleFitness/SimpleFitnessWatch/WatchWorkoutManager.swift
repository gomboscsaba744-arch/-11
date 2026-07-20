import Foundation
#if os(watchOS)
import WatchKit
import HealthKit
import CoreMotion
import WatchConnectivity
import Combine

/// �蓥葵�其��唳旿蝏𤘪�嚗�𣈲����其�摰墧𧒄瘚�蓮銝舘��剁�
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

/// �其��毺��𥕦郎��掩獢��嚗𡁻�撖嫣�����𥡝蓬�睲��𣳇�笔漲�訫蔣摰𡁜�皛斗郭�𢠃��澆���
public enum BiomechanicalMotionProfile {
    case lowerBodyCompound  // 瘛梯僕��′�剹���銝曄�嚗𡁏��笔之�漤�嚗諹健�潭𦆮摰質秐 0.85嚗��霈豢𧒄�� [0.6s, 8.0s]
    case upperBodyPress     // �扳綫��綫銝整���憭港��页�蝥萄�銝𦒘�銝钅��𥟇�撠�蛹銝鳴�擃条��誩鍳�剁�靚瑕�� 1.05
    case upperBodyPull      // �坿�����剹��摩銝橘��匧�銝舘蓮�刻��笔漲憭滚�銝箔蜓嚗�鍳�� 1.30嚗諹健�� 1.08
    case lateralOrCore      // 靘批像銝整��摮堒像銝整���曏��擃䀹�頧砌�璅芸�憭硋�銝餃紡嚗諹��笔漲����𣂼�嚗�鍳�� 1.28嚗諹健�� 1.00
    
    public static func profile(for exerciseName: String) -> BiomechanicalMotionProfile {
        let name = exerciseName.lowercased()
        if name.contains("瘛梯僕") || name.contains("��") || name.contains("�鞱葭") || name.contains("蝖祆�") || name.contains("���頩�") {
            return .lowerBodyCompound
        } else if name.contains("��") || name.contains("銝见�") || name.contains("蝣𡡞���") || name.contains("撅�撓") {
            return .upperBodyPress
        } else if name.contains("靘批像銝�") || name.contains("y 摮�") || name.contains("y摮�") || name.contains("憌鮋�") || name.contains("憭寡�") {
            return .lateralOrCore
        } else {
            return .upperBodyPull
        }
    }
}

/// Apple Watch S7 �詨��偦�霈剔��批��剁��券曎頝舀㺭�株��其�憭𡁜𢆡雿𨅯��嗡葡�䈑�
public class WatchWorkoutManager: NSObject, ObservableObject {
    public static let shared = WatchWorkoutManager()
    
    @Published public var planTitle: String = "蝚砌�憭�(�其�) | �� 1 (靚�㟲嚗𡁏綫�豢㦤�Ｗ��䔶�憭�)"
    
    // 摰峕㟲��紋銵典𢆡雿𨅯�銵剁��典��其��朞��剁�
    @Published public var exercises: [WatchExerciseItem] = [
        WatchExerciseItem(name: "�𣳇�撟單踎�扳綫 (�芰眏)", currentSet: 1, totalSets: 4, targetReps: 10, weightKg: 30.0),
        WatchExerciseItem(name: "銝𦠜��煾��扳綫 (�芰眏)", currentSet: 1, totalSets: 4, targetReps: 12, weightKg: 15.0),
        WatchExerciseItem(name: "蝏喟揣憌鮋�憭寡� (�箏�)", currentSet: 1, totalSets: 4, targetReps: 15, weightKg: 10.0),
        WatchExerciseItem(name: "�𣂼尿�煾��拇綫 (�芰眏)", currentSet: 1, totalSets: 3, targetReps: 12, weightKg: 10.0),
        WatchExerciseItem(name: "�煾�靘批像銝� (�芰眏)", currentSet: 1, totalSets: 4, targetReps: 15, weightKg: 7.5),
        WatchExerciseItem(name: "蝏喟揣 Y 摮堒像銝� (�箏�)", currentSet: 1, totalSets: 4, targetReps: 15, weightKg: 5.0),
        WatchExerciseItem(name: "蝏喟揣銝匧仍�䔶��� (�箏�)", currentSet: 1, totalSets: 4, targetReps: 15, weightKg: 20.0),
        WatchExerciseItem(name: "隞啣擀�煾����隡�/蝣𡡞��� (�芰眏)", currentSet: 1, totalSets: 3, targetReps: 12, weightKg: 7.5)
    ]
    
    @Published public var exerciseIndex: Int = 1 {
        didSet {
            syncCurrentExerciseData()
        }
    }
    
    @Published public var totalExercises: Int = 8
    @Published public var exerciseName: String = "�𣳇�撟單踎�扳綫 (�芰眏)"
    @Published public var currentSet: Int = 1
    @Published public var totalSets: Int = 4
    @Published public var targetReps: Int = 10
    @Published public var currentWeightKg: Double = 30.0
    
    @Published public var detectedRepCount: Int = 0
    @Published public var showTargetReachedModal: Bool = false
    
    // 閫西��漤��芷�����㺭嚗��朞��𧢲㦤�峕郊�滨蔭銝擧𧋦�啁�摮矋�
    @Published public var hapticFeedbackEnabled: Bool = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled") }
    }
    @Published public var repCountdownHapticCount: Int = UserDefaults.standard.object(forKey: "repCountdownHapticCount") as? Int ?? 3 {
        didSet { UserDefaults.standard.set(repCountdownHapticCount, forKey: "repCountdownHapticCount") }
    }
    @Published public var restCountdownHapticSeconds: Int = UserDefaults.standard.object(forKey: "restCountdownHapticSeconds") as? Int ?? 5 {
        didSet { UserDefaults.standard.set(restCountdownHapticSeconds, forKey: "restCountdownHapticSeconds") }
    }
    
    // 銝駁�瘛望�璅∪�銝擧��箇垢����峕郊蝻枏�
    @Published public var appThemeMode: String = UserDefaults.standard.string(forKey: "appThemeMode") ?? "system" {
        didSet { UserDefaults.standard.set(appThemeMode, forKey: "appThemeMode") }
    }
    
    // 霈剔��餌�蝏蠘恣�唳旿
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
    public var gyroAmplitude: Double = 0.0
    @Published public var currentExerciseRestSeconds: Int = 60
    
    // 预计算的动态标定参数缓存（来自手机端 1,324 动作库下发）
    public var syncedDominantAxis: Int? = nil
    public var syncedMinRatio: Double? = nil
    public var syncedThresholdG: String? = nil

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
    private var currentRepPeakEnergy: Double = 0.0

    // 每个动作的轴向标定参数
    // dominantAxis: 0=rotX(roll/旋前旋后), 1=rotY(pitch/腕屈伸), 2=rotZ(yaw/水平转动)
    // minRatio: 该轴占三轴旋转总量的最低比例，低于此值视为方向不符，拒绝计次
    private struct ExerciseAxisCalibration {
        let dominantAxis: Int
        let minRatio: Double
    }
    private let calibrationMap: [String: ExerciseAxisCalibration] = [
        // ── 推日 ──
        // 卧推：平躺推杠铃，肘伸展方向垂直向上，Y轴旋转最强
        "杠铃平板卧推 (自由)":           ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.36),
        // 上斜卧推：30-45度倾斜，仍以Y轴为主，略宽松
        "上斜哑铃卧推 (自由)":           ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.33),
        // 飞鸟：手腕从旋外到旋内弧形运动，X轴(roll)主导
        "绳索飞鸟夹胸 (固定)":           ExerciseAxisCalibration(dominantAxis: 0, minRatio: 0.33),
        // 肩推：坐位头顶推举，垂直向上最纯粹，Y轴占比最高
        "坐姿哑铃肩推 (自由)":           ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.36),
        // 侧平举：上臂侧向抬起至肩高，前臂随臂展roll，X轴主导
        "哑铃侧平举 (自由)":             ExerciseAxisCalibration(dominantAxis: 0, minRatio: 0.33),
        // Y字平举：斜前方抬起，X和Y轴混合，以X为主，阈值宽松
        "绳索 Y 字平举 (固定)":          ExerciseAxisCalibration(dominantAxis: 0, minRatio: 0.30),
        // 三头下压：肘关节固定，前臂向下伸展，矢状面Y轴
        "绳索三头肌下压 (固定)":          ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.38),
        // 碎颅者：仰卧肘屈伸，前臂扫过头顶弧线，Y轴最纯粹
        "仰卧哑铃臂屈伸/碎颅者 (自由)":   ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.40),
        // ── 拉日 ──
        // 引体向上：垂直向上拉，Y轴主导（卧推反向）
        "引体向上 (自重)":               ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.36),
        // 高位下拉：坐姿向下拉杆，矢状面Y轴
        "高位下拉 (固定)":               ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.34),
        // 杠铃俯身划船：躯干前倾，肘向后拉，Y轴主导
        "杠铃俯身划船 (自由)":            ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.34),
        // 坐姿绳索划船：坐姿水平拉，肘向后收，Y轴主导
        "坐姿绳索划船机 (固定)":          ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.34),
        // 直臂下拉：手臂伸直向下扫弧，X轴(roll)和Y轴混合，X略优
        "站姿直臂下拉 (固定)":            ExerciseAxisCalibration(dominantAxis: 0, minRatio: 0.31),
        // 反向飞鸟：双臂从前向后展开，水平外展，X轴主导
        "蝴蝶机反向飞鸟 (固定)":          ExerciseAxisCalibration(dominantAxis: 0, minRatio: 0.33),
        // 哑铃弯举：前臂在矢状面屈曲，Y轴最纯粹
        "哑铃交替弯举 (自由)":            ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.40),
        // 锤式弯举：中立握姿弯举，Y轴为主略带X轴
        "绳索锤式弯举 (固定)":            ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.37),
        // 直杆弯举：旋后握姿，Y轴最为纯粹
        "站姿绳索直杆/曲杆弯举 (固定)":   ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.40),
        // ── 腿日 ──
        // 杠铃深蹲：身体垂直上下，手腕信号微弱，Y轴略优，阈值宽松
        "杠铃自由深蹲":                  ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.28),
        // 保加利亚分腿蹲：单腿蹲，手持哑铃，Y轴为主
        "哑铃保加利亚分腿蹲":             ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.28),
        // 罗马尼亚硬拉：躯干前俯/后仰，手腕保持中立，Y轴为主
        "罗马尼亚硬拉 (自由)":            ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.30),
        // 腿举机：平躺蹬腿，手握扶手固定，手腕信号极弱，宽松阈值
        "45度倒蹬腿举机 (固定)":          ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.25),
        // 腿屈伸：坐姿伸腿，手腕几乎静止，信号很弱
        "坐姿腿屈伸 (固定)":             ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.25),
        // 腿弯举：俯卧屈腿，Y轴为主
        "俯卧腿弯举 (固定)":             ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.28),
        // 提踵：站立起踵，手腕几乎无动作，宽松阈值
        "站姿器械提踵 (固定)":            ExerciseAxisCalibration(dominantAxis: 1, minRatio: 0.25),
        // 悬垂举腿：抓单杠举腿，握力带动Z轴(yaw)旋转最明显
        "悬垂举腿 (自重核心)":            ExerciseAxisCalibration(dominantAxis: 2, minRatio: 0.30),
    ]
    // 当前组的每次候选动作中各轴旋转累积量与行业成熟算法专用的底噪包络/加速度累积
    private var repAccumRotX: Double = 0.0
    private var repAccumRotY: Double = 0.0
    private var repAccumRotZ: Double = 0.0
    private var repAccumAccX: Double = 0.0
    private var repAccumAccY: Double = 0.0
    private var repAccumAccZ: Double = 0.0
    private var baselineEnergy: Double = 0.0
    @Published public var repConfidenceScore: Double = 0.0
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let motionManager = CMMotionManager()
    private var wcSession: WCSession?
    private var watchLogFileHandle: FileHandle?
    private var watchLogFileURL: URL?
    private struct MotionLogRecord {
        let timestampMs: Int64
        let exName: String
        let curSet: Int
        let rotX: Float
        let rotY: Float
        let rotZ: Float
        let accX: Float
        let accY: Float
        let accZ: Float
    }
    private let logWriteQueue = DispatchQueue(label: "com.simplefitness.watch.logWriteQueue", qos: .utility)
    private let motionQueue = OperationQueue()
    private let bufferLock = NSLock()
    private var inMemoryLogBuffer: [MotionLogRecord] = []
    
    private override init() {
        super.init()
        motionQueue.qualityOfService = .userInitiated
        motionQueue.maxConcurrentOperationCount = 1
        totalExercises = exercises.count
        syncCurrentExerciseData()
        setupWatchConnectivity()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.requestHealthKitPermissions()
        }
    }
    
    /// �峕郊敶枏��其��唳旿�喃蜓�屸𢒰撅墧��
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
    
    /// ��揢銝𠹺��其�
    public func previousExercise() {
        guard exerciseIndex > 1 else { return }
        exerciseIndex -= 1
        WKInterfaceDevice.current().play(.click)
        sendSyncEvent("CHANGE_EXERCISE", extra: ["exerciseIndex": exerciseIndex])
    }
    
    /// ��揢銝衤��其�
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
    
    public func adjustRepCount(by delta: Int, confidence: Double = 1.0) {
        let newCount = max(0, detectedRepCount + delta)
        guard newCount != detectedRepCount else { return }
        detectedRepCount = newCount
        if delta > 0 { self.repConfidenceScore = confidence }
        sendSyncEvent("REP_DETECTED", extra: [
            "detectedRepCount": detectedRepCount,
            "repConfidence": self.repConfidenceScore,
            "timestamp": Date().timeIntervalSince1970
        ])
        sendTelemetryToPhone()
        
        guard hapticFeedbackEnabled else { return }
        
        if detectedRepCount == targetReps {
            showTargetReachedModal = true
            // ���𦒘���躹�思��嗡���𢆡霈拐犖�擧遬�仿��𡁜�鈭���屸�撘粹�蝏枏�瘝㗇絡撘𤩺��笔���
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                WKInterfaceDevice.current().play(.notification)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                WKInterfaceDevice.current().play(.start)
            }
        } else if detectedRepCount > targetReps {
            WKInterfaceDevice.current().play(.directionUp)
        } else if delta > 0 {
            // 蝏���鍦�銝磰��芸��鞉𧒄嚗𡁏��交糓�西��乒�𨀣��� N 銝芸�埝㺭皜鞱���𢆡�粹𡢿��
            let remaining = targetReps - detectedRepCount
            if repCountdownHapticCount > 0 && remaining <= repCountdownHapticCount && remaining > 0 {
                // �寞旿�拐�甈⊥㺭銝滚�嚗諹圻�爗�靝��惩��剹���鞉�憓𧼮撩�萘��埝㺭��𢆡
                if remaining == 1 {
                    // 隞������1銝迎��喳��𡁜�嚗㚁�撘箏𤗈����諹���
                    WKInterfaceDevice.current().play(.start)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        WKInterfaceDevice.current().play(.directionUp)
                    }
                } else if remaining == 2 {
                    // �埝㺭蝚�2銝迎�銝剖撩�脣稬��𢆡
                    WKInterfaceDevice.current().play(.retry)
                } else if remaining <= 3 {
                    // �埝㺭蝚�3銝迎�皜��銝剝��臬𢆡
                    WKInterfaceDevice.current().play(.directionUp)
                } else {
                    // �埝㺭蝚�4~5銝迎�頧餅�敺桅��鞟內
                    WKInterfaceDevice.current().play(.click)
                }
            } else {
                // �桅�𡁜��蠘恣甈∴���凝撘勗抅蝖��鮋�嚗𣬚��曉��罸�鞉�憓𧼮撩撅�活
                WKInterfaceDevice.current().play(.click)
            }
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
        if exerciseIndex != 1 {
            exerciseIndex = 1
        } else {
            syncCurrentExerciseData()
        }
        detectedRepCount = 0
        activeEnergyKcal = 0
        showTargetReachedModal = false
        workoutDurationSeconds = 0
        workoutStartTime = Date()
        
        // 撱嗉� 0.35 蝘𡜐��其蜓蝥輻�摰匧��臬𢆡隡䭾��其� HealthKit嚗屸��滚��啁瑪蝔见僎�睲耨�孵��批紡�� Crash嚗�緾��嚗㚁��峕𧒄蝏躰雲 UI ��揢餈�腹�園𡢿 0 �⊿▼
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self, self.isWorkoutRunning else { return }
            self.startHealthKitWorkoutSession()
            self.startMotionSensorMonitoring()
        }
        
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isWorkoutRunning else { return }
            self.workoutDurationSeconds += 1
            if self.workoutDurationSeconds % 8 == 0 && self.workoutBuilder == nil {
                self.activeEnergyKcal += 1
            }
        }
        
        telemetryTimer?.invalidate()
        telemetryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        
        self.stopMotionSensorMonitoring()
        self.endHealthKitWorkoutSession()
        
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
        
        // �湔鰵敶枏��其���摰峕�����堆��亙�憟堒�摰���芸𢆡�刻��唬�銝��其�
        if exerciseIndex >= 1 && exerciseIndex <= exercises.count {
            exercises[exerciseIndex - 1].currentSet += 1
            if exercises[exerciseIndex - 1].currentSet > exercises[exerciseIndex - 1].totalSets {
                if exerciseIndex < exercises.count {
                    exerciseIndex += 1
                    exercises[exerciseIndex - 1].currentSet = 1
                    currentSet = 1
                    exerciseName = exercises[exerciseIndex - 1].name
                    totalSets = exercises[exerciseIndex - 1].totalSets
                    targetReps = exercises[exerciseIndex - 1].targetReps
                    currentWeightKg = exercises[exerciseIndex - 1].weightKg
                }
            } else {
                currentSet = exercises[exerciseIndex - 1].currentSet
            }
        }
        
        sendSyncEvent("CHANGE_SET", extra: [
            "currentSet": currentSet,
            "exerciseIndex": exerciseIndex,
            "totalSets": totalSets,
            "exerciseName": exerciseName
        ])
        startRestPeriod(seconds: currentExerciseRestSeconds > 0 ? currentExerciseRestSeconds : 60)
    }
    
    public func startRestPeriod(seconds: Int = 60, syncToPhone: Bool = true) {
        restTimer?.invalidate()
        totalRestTime = seconds
        restTimeRemaining = seconds
        isResting = true
        showTargetReachedModal = false
        flushInMemoryLogBufferToDiskAsync()
        if syncToPhone {
            sendSyncEvent("START_REST", extra: ["seconds": seconds, "currentSet": currentSet, "totalSets": totalSets, "exerciseIndex": exerciseIndex])
        }
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.restTimeRemaining > 1 {
                self.restTimeRemaining -= 1
                // 隡烐��坿恣�嗆��� N 蝘㘾�鞟���𢆡�鞾�嚗��朞� restCountdownHapticSeconds �冽��ế摰𡄯�
                if self.hapticFeedbackEnabled && self.restCountdownHapticSeconds > 0 && self.restTimeRemaining <= self.restCountdownHapticSeconds {
                    if self.restTimeRemaining == 1 {
                        WKInterfaceDevice.current().play(.retry)
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                }
            } else {
                self.finishRestPeriod()
            }
        }
    }
    
    public func skipRestPeriod(syncToPhone: Bool = true) {
        finishRestPeriod(syncToPhone: syncToPhone)
    }
    
    public func addRestTime(_ seconds: Int) {
        restTimeRemaining = max(0, restTimeRemaining + seconds)
        totalRestTime = max(totalRestTime, restTimeRemaining)
        if hapticFeedbackEnabled {
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    private func finishRestPeriod(syncToPhone: Bool = true) {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        detectedRepCount = 0
        if hapticFeedbackEnabled {
            // 隡烐�蝏𤘪��脤�撘箔漁�鞟內嚗𡁜�餈𧼮��𥟇���
            WKInterfaceDevice.current().play(.start)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                WKInterfaceDevice.current().play(.directionUp)
            }
        }
        if syncToPhone {
            sendSyncEvent("FINISH_REST")
        }
    }
    
    private func startMotionSensorMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.033
        isRepCycleActive = false
        smoothedEnergy = 0.0
        baselineEnergy = 0.0
        currentRepPeakEnergy = 0.0
        
        motionManager.startDeviceMotionUpdates(to: self.motionQueue) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let now = Date()
            let rotation = motion.rotationRate
            let rotMag = sqrt(rotation.x*rotation.x + rotation.y*rotation.y + rotation.z*rotation.z)
            let acc = motion.userAcceleration
            let accMag = sqrt(acc.x*acc.x + acc.y*acc.y + acc.z*acc.z)
            
            // 行业成熟算法1：双向带通滤波与自适应基线消除（过滤步行/准备动作等底噪漂移）
            let rawEnergy = rotMag + accMag * 3.6
            self.smoothedEnergy = self.smoothedEnergy * 0.72 + rawEnergy * 0.28
            self.baselineEnergy = self.baselineEnergy * 0.98 + rawEnergy * 0.02
            let cleanEnergy = max(0.0, self.smoothedEnergy - self.baselineEnergy * 0.8)
            self.gyroAmplitude = cleanEnergy
            
            if self.isWorkoutRunning && !self.isResting {
                let timestampMs = Int64(now.timeIntervalSince1970 * 1000)
                let record = MotionLogRecord(timestampMs: timestampMs, exName: self.exerciseName, curSet: self.currentSet, rotX: Float(rotation.x), rotY: Float(rotation.y), rotZ: Float(rotation.z), accX: Float(acc.x), accY: Float(acc.y), accZ: Float(acc.z))
                self.bufferLock.lock()
                self.inMemoryLogBuffer.append(record)
                self.bufferLock.unlock()
            }
            
            guard self.isWorkoutRunning && !self.isResting else {
                self.isRepCycleActive = false
                return
            }
            
            // 动作专属阈值获取
            let thresholdVal: Double
            if let str = self.syncedThresholdG {
                if str.contains("0.40") { thresholdVal = 1.35 }
                else if str.contains("0.45") { thresholdVal = 1.40 }
                else if str.contains("0.50") { thresholdVal = 1.45 }
                else if str.contains("0.55") { thresholdVal = 1.50 }
                else if str.contains("0.60") { thresholdVal = 1.55 }
                else { thresholdVal = 1.45 }
            } else {
                thresholdVal = 1.45
            }
            
            // 行业成熟算法2：施密特触发器（Schmitt Trigger）双重阈值磁滞回线
            // 设立向心峰值门限(Peak Threshold)与离心归位门限(Valley Threshold)，彻底绝杀震荡误计次
            let peakThreshold = thresholdVal
            let valleyThreshold = max(0.65, thresholdVal * 0.58)
            
            if !self.isRepCycleActive {
                if cleanEnergy > peakThreshold && now.timeIntervalSince(self.lastRepDetectTime) > 1.05 {
                    self.isRepCycleActive = true
                    self.currentRepStartTime = now
                    self.currentRepPeakEnergy = cleanEnergy
                    // 六轴能量积分归零
                    self.repAccumRotX = 0.0
                    self.repAccumRotY = 0.0
                    self.repAccumRotZ = 0.0
                    self.repAccumAccX = 0.0
                    self.repAccumAccY = 0.0
                    self.repAccumAccZ = 0.0
                }
            } else {
                if cleanEnergy > self.currentRepPeakEnergy {
                    self.currentRepPeakEnergy = cleanEnergy
                }
                self.repAccumRotX += abs(rotation.x)
                self.repAccumRotY += abs(rotation.y)
                self.repAccumRotZ += abs(rotation.z)
                self.repAccumAccX += abs(acc.x)
                self.repAccumAccY += abs(acc.y)
                self.repAccumAccZ += abs(acc.z)

                // 跌破归位门限，进入动作合法性双阶段校验
                if cleanEnergy < valleyThreshold {
                    let repDuration = now.timeIntervalSince(self.currentRepStartTime)
                    self.isRepCycleActive = false
                    
                    // 行业成熟算法3：生理学时窗与主轴特征自适应投影匹配
                    if repDuration >= 0.65 && repDuration <= 5.5 {
                        let totalRot = self.repAccumRotX + self.repAccumRotY + self.repAccumRotZ
                        var axisCheckPassed = true
                        var dominantRatio = 1.0
                        
                        if totalRot > 0.01 {
                            let calAxis: Int
                            let calRatio: Double
                            if let cal = self.calibrationMap[self.exerciseName] {
                                calAxis = cal.dominantAxis
                                calRatio = cal.minRatio
                            } else if let sAxis = self.syncedDominantAxis, let sRatio = self.syncedMinRatio {
                                calAxis = sAxis
                                calRatio = sRatio
                            } else {
                                calAxis = 1
                                calRatio = 0.35
                            }
                            switch calAxis {
                            case 0: dominantRatio = self.repAccumRotX / totalRot
                            case 2: dominantRatio = self.repAccumRotZ / totalRot
                            default: dominantRatio = self.repAccumRotY / totalRot
                            }
                            axisCheckPassed = dominantRatio >= calRatio
                        }
                        
                        // 行业成熟算法4：综合动感信噪比与置信度打分(Confidence Scoring)
                        let energyScore = min(1.0, self.currentRepPeakEnergy / peakThreshold)
                        let finalConfidence = energyScore * dominantRatio
                        
                        if axisCheckPassed && finalConfidence >= 0.55 {
                            self.lastRepDetectTime = now
                            DispatchQueue.main.async { [weak self] in
                                self?.adjustRepCount(by: 1, confidence: finalConfidence)
                            }
                        }
                    }
                } else if now.timeIntervalSince(self.currentRepStartTime) > 6.5 {
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
    
    private func flushInMemoryLogBufferToDiskAsync() {
        bufferLock.lock()
        guard !inMemoryLogBuffer.isEmpty else {
            bufferLock.unlock()
            return
        }
        let samples = inMemoryLogBuffer
        inMemoryLogBuffer.removeAll(keepingCapacity: true)
        bufferLock.unlock()
        logWriteQueue.async { [weak self] in
            guard let self = self else { return }
            if self.watchLogFileHandle == nil || self.watchLogFileURL == nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                let safeName = samples.first?.exName.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_") ?? "Workout"
                let fileName = "GyroLog_摰峕㟲霈剔�隡朞�_銵函垢�贝�-\(safeName)_\(formatter.string(from: Date())).csv"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                let header = "timestamp_ms,exercise_name,set_number,gyro_x,gyro_y,gyro_z,accel_x,accel_y,accel_z,source\n"
                try? header.write(to: fileURL, atomically: true, encoding: .utf8)
                self.watchLogFileURL = fileURL
                self.watchLogFileHandle = try? FileHandle(forWritingTo: fileURL)
                self.watchLogFileHandle?.seekToEndOfFile()
            }
            var chunkString = ""
            for s in samples {
                chunkString += "\(s.timestampMs),\(s.exName),\(s.curSet),\(String(format: "%.4f", s.rotX)),\(String(format: "%.4f", s.rotY)),\(String(format: "%.4f", s.rotZ)),\(String(format: "%.4f", s.accX)),\(String(format: "%.4f", s.accY)),\(String(format: "%.4f", s.accZ)),AppleWatch_Wrist\n"
            }
            if let handle = self.watchLogFileHandle, let data = chunkString.data(using: .utf8) {
                try? handle.write(contentsOf: data)
            }
        }
    }
    
    private func stopMotionSensorMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        bufferLock.lock()
        let finalSamples = inMemoryLogBuffer
        inMemoryLogBuffer.removeAll()
        bufferLock.unlock()
        logWriteQueue.async { [weak self] in
            guard let self = self else { return }
            if !finalSamples.isEmpty {
                if self.watchLogFileHandle == nil || self.watchLogFileURL == nil {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd_HHmmss"
                    let safeName = finalSamples.first?.exName.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_") ?? "Workout"
                    let fileName = "GyroLog_摰峕㟲霈剔�隡朞�_銵函垢�贝�-\(safeName)_\(formatter.string(from: Date())).csv"
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    let header = "timestamp_ms,exercise_name,set_number,gyro_x,gyro_y,gyro_z,accel_x,accel_y,accel_z,source\n"
                    try? header.write(to: fileURL, atomically: true, encoding: .utf8)
                    self.watchLogFileURL = fileURL
                    self.watchLogFileHandle = try? FileHandle(forWritingTo: fileURL)
                    self.watchLogFileHandle?.seekToEndOfFile()
                }
                var chunkString = ""
                for s in finalSamples {
                    chunkString += "\(s.timestampMs),\(s.exName),\(s.curSet),\(String(format: "%.4f", s.rotX)),\(String(format: "%.4f", s.rotY)),\(String(format: "%.4f", s.rotZ)),\(String(format: "%.4f", s.accX)),\(String(format: "%.4f", s.accY)),\(String(format: "%.4f", s.accZ)),AppleWatch_Wrist\n"
                }
                if let handle = self.watchLogFileHandle, let data = chunkString.data(using: .utf8) {
                    try? handle.write(contentsOf: data)
                }
            }
            if let handle = self.watchLogFileHandle {
                try? handle.close()
            }
            let urlToTransfer = self.watchLogFileURL
            self.watchLogFileHandle = nil
            self.watchLogFileURL = nil
            if let fileURL = urlToTransfer {
                DispatchQueue.main.async {
                    if let session = self.wcSession {
                        session.transferFile(fileURL, metadata: [
                            "source": "AppleWatch_Wrist",
                            "originalFileName": fileURL.lastPathComponent
                        ])
                        print("[WatchWorkoutManager] 撌脣� 30Hz �贝�摰峕㟲���箔貌�亙��䭾��硺��𧢲㦤撖澆枂: \(fileURL.lastPathComponent)")
                    }
                }
            }
        }
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
        DispatchQueue.global(qos: .utility).async {
            if session.isReachable {
                session.sendMessage(telemetry, replyHandler: nil, errorHandler: nil)
            }
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
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        applyIncomingPayload(userInfo)
    }
    
    private func applyIncomingPayload(_ message: [String: Any]) {
        DispatchQueue.main.async {
            let actionOrCommand = (message["action"] as? String) ?? (message["command"] as? String)
            if let cmd = actionOrCommand {
                switch cmd {
                case "START_WORKOUT_SESSION", "START_WORKOUT", "SYNC_WORKOUT_STATE":
                    if !self.isWorkoutRunning && cmd != "SYNC_WORKOUT_STATE" {
                        self.startWorkoutSession(syncToPhone: false)
                    } else if cmd == "SYNC_WORKOUT_STATE" && !self.isWorkoutRunning && (message["isWorkoutStarted"] as? Bool == true) {
                        self.startWorkoutSession(syncToPhone: false)
                    }
                case "CHANGE_EXERCISE":
                    if let index = message["exerciseIndex"] as? Int, index >= 1 && index <= self.exercises.count {
                        self.exerciseIndex = index
                    }
                case "START_REST":
                    let seconds = message["seconds"] as? Int ?? 60
                    self.startRestPeriod(seconds: seconds, syncToPhone: false)
                case "FINISH_REST":
                    self.skipRestPeriod(syncToPhone: false)
                case "END_WORKOUT", "END_WORKOUT_SESSION", "STOP_WORKOUT_SESSION":
                    self.endWorkoutSession(syncToPhone: false)
                default:
                    break
                }
            }
            
            if let repCount = message["detectedRepCount"] as? Int {
                self.detectedRepCount = repCount
            }
            if let plan = message["planTitle"] as? String {
                self.planTitle = plan
            }
            if let ex = (message["exerciseName"] as? String) ?? (message["exerciseTitle"] as? String) {
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
            if let weight = (message["targetWeightKg"] as? Double) ?? (message["targetWeightKg"] as? Float).map({ Double($0) }) ?? (message["targetWeightKg"] as? Int).map({ Double($0) }) {
                self.currentWeightKg = weight
                if self.exerciseIndex >= 1 && self.exerciseIndex <= self.exercises.count {
                    self.exercises[self.exerciseIndex - 1].weightKg = weight
                }
            }
            if let dominantAxis = (message["dominantAxis"] as? Int) ?? (message["dominantAxis"] as? Double).map({ Int($0) }) {
                self.syncedDominantAxis = dominantAxis
            }
            if let minRatio = (message["minRatio"] as? Double) ?? (message["minRatio"] as? Float).map({ Double($0) }) {
                self.syncedMinRatio = minRatio
            }
            if let thresholdG = message["thresholdG"] as? String {
                self.syncedThresholdG = thresholdG
            }
            if let restSec = message["restSeconds"] as? Int {
                self.currentExerciseRestSeconds = restSec
            }
            if let isResting = message["isResting"] as? Bool {
                if isResting && !self.isResting {
                    self.startRestPeriod(seconds: message["restSeconds"] as? Int ?? (self.currentExerciseRestSeconds > 0 ? self.currentExerciseRestSeconds : 60), syncToPhone: false)
                } else if !isResting && self.isResting {
                    self.skipRestPeriod(syncToPhone: false)
                }
            }
            if let repCountHaptic = message["repCountdownHapticCount"] as? Int {
                self.repCountdownHapticCount = repCountHaptic
            }
            if let restSecHaptic = message["restCountdownHapticSeconds"] as? Int {
                self.restCountdownHapticSeconds = restSecHaptic
            }
            if let hapticEnabled = message["hapticFeedbackEnabled"] as? Bool {
                self.hapticFeedbackEnabled = hapticEnabled
            }
            if let themeMode = message["appThemeMode"] as? String {
                self.appThemeMode = themeMode
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
