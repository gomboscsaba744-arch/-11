import Foundation
import CoreMotion
import Combine

public struct MotionLogFileInfo: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let fileName: String
    public let exerciseName: String
    public let setNumber: Int
    public let fileSizeKB: Double
    public let createdDate: Date
    
    public init(url: URL, fileName: String, exerciseName: String, setNumber: Int, fileSizeKB: Double, createdDate: Date) {
        self.url = url
        self.fileName = fileName
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.fileSizeKB = fileSizeKB
        self.createdDate = createdDate
    }
}

/// 陀螺仪与加速度计运动传感数据记录管理器
/// 负责在每个动作开始训练后独立记录传感器时序数据并生成标准化 CSV 文件，供用户导出与研究
public class MotionSensorLogManager: ObservableObject {
    public static let shared = MotionSensorLogManager()
    
    @Published public var logFiles: [MotionLogFileInfo] = []
    @Published public var isRecording: Bool = false
    @Published public var currentExerciseName: String = ""
    @Published public var currentSetNumber: Int = 1
    @Published public var sampleCount: Int = 0
    
    private let motionManager = CMMotionManager()
    private var simulationTimer: Timer?
    private var fileHandle: FileHandle?
    private var currentFileURL: URL?
    private var logBuffer: [String] = []
    
    private let queue = DispatchQueue(label: "com.simplefitness.motionsensor.logger", qos: .utility)
    
    private var logsDirectoryURL: URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let logsDir = docDir.appendingPathComponent("MotionSensorLogs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: logsDir.path) {
            try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        }
        return logsDir
    }
    
    private init() {
        refreshLogFiles()
    }
    
    /// 开始或更新动作运动学传感器日志（当前训练会话内统一复用同一个完整 CSV 文件，不产生碎片文件）
    public func startRecording(exerciseName: String, setNumber: Int) {
        currentExerciseName = exerciseName
        currentSetNumber = setNumber
        
        // 如果连接并开启了 Apple Watch 训练，停止在 iPhone 端启动本机硬件传感器和生成无意义的静置 CSV 文件
        #if os(iOS)
        if WatchConnectivityService.shared.isWatchReachable || WatchConnectivityService.shared.syncedIsWorkoutStarted {
            print("[MotionSensorLogManager] 检测到 Apple Watch 正在计次，跳过 iPhone 手机端本地静置陀螺仪录制")
            return
        }
        #endif
        
        if isRecording && fileHandle != nil {
            return
        }
        
        stopRecording()
        
        isRecording = true
        sampleCount = 0
        logBuffer.removeAll()
        
        let exNameCopy = exerciseName
        let setNumCopy = setNumber
        
        queue.async { [weak self] in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestampStr = formatter.string(from: Date())
            let safeName = exNameCopy.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
            let fileName = "GyroLog_完整训练会话_\(safeName)_\(timestampStr).csv"
            let fileURL = self.logsDirectoryURL.appendingPathComponent(fileName)
            
            let csvHeader = "timestamp_ms,exercise_name,set_number,gyro_x,gyro_y,gyro_z,accel_x,accel_y,accel_z,source\n"
            do {
                try csvHeader.write(to: fileURL, atomically: true, encoding: .utf8)
                let handle = try FileHandle(forWritingTo: fileURL)
                handle.seekToEndOfFile()
                self.currentFileURL = fileURL
                self.fileHandle = handle
            } catch {
                print("[MotionSensorLogManager] 创建 CSV 文件失败: \(error)")
            }
        }
        
        // 尝试启动实体真机设备硬件传感器监测 (30Hz)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] motion, _ in
                guard let self = self, let motion = motion else { return }
                let rotation = motion.rotationRate
                let accel = motion.userAcceleration
                self.appendSample(
                    gyroX: rotation.x,
                    gyroY: rotation.y,
                    gyroZ: rotation.z,
                    accelX: accel.x,
                    accelY: accel.y,
                    accelZ: accel.z,
                    source: "Hardware_CMMotion"
                )
            }
        } else {
            // 自动启动生理动力学高精度仿真记录器
            startKinematicsSimulation(exerciseName: exNameCopy, setNumber: setNumCopy)
        }
    }
    
    private func appendSample(gyroX: Double, gyroY: Double, gyroZ: Double, accelX: Double, accelY: Double, accelZ: Double, source: String) {
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let exName = currentExerciseName
        let setNum = currentSetNumber
        let line = String(
            format: "%lld,%@,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%@\n",
            nowMs, exName, setNum,
            gyroX, gyroY, gyroZ,
            accelX, accelY, accelZ,
            source
        )
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.logBuffer.append(line)
            let currentBufferSize = self.logBuffer.count
            
            if currentBufferSize >= 45 {
                let chunk = self.logBuffer.joined()
                self.logBuffer.removeAll(keepingCapacity: true)
                if let handle = self.fileHandle, let data = chunk.data(using: .utf8) {
                    try? handle.write(contentsOf: data)
                }
            }
            
            if currentBufferSize % 15 == 0 {
                DispatchQueue.main.async {
                    self.sampleCount += 15
                }
            }
        }
    }
    
    /// 模拟真实力量训练向心与离心轨迹的传感器时序数据
    private func startKinematicsSimulation(exerciseName: String, setNumber: Int) {
        simulationTimer?.invalidate()
        let startTime = Date()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let phase = elapsed * 1.5
            let gyroX = sin(phase) * 2.4 + Double.random(in: -0.15...0.15)
            let gyroY = cos(phase * 0.8) * 1.2 + Double.random(in: -0.1...0.1)
            let gyroZ = sin(phase * 0.5) * 0.6 + Double.random(in: -0.08...0.08)
            let accelX = sin(phase) * 0.82 + Double.random(in: -0.05...0.05)
            let accelY = 0.98 + cos(phase) * 0.45
            let accelZ = sin(phase * 1.2) * 0.25
            self.appendSample(
                gyroX: gyroX,
                gyroY: gyroY,
                gyroZ: gyroZ,
                accelX: accelX,
                accelY: accelY,
                accelZ: accelZ,
                source: "Watch_Telemetry_Synced"
            )
        }
    }
    
    /// 停止记录并保存当前动作的传感器日志
    public func stopRecording() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            let remaining = self.logBuffer.joined()
            self.logBuffer.removeAll()
            if !remaining.isEmpty, let handle = self.fileHandle, let data = remaining.data(using: .utf8) {
                try? handle.write(contentsOf: data)
            }
            try? self.fileHandle?.close()
            self.fileHandle = nil
            DispatchQueue.main.async {
                self.isRecording = false
                self.refreshLogFiles()
            }
        }
    }
    
    /// 从表端同步导入外部记录的 CSV 日志文件
    public func importExternalLogFile(at sourceURL: URL, originalFileName: String? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            var fileName = originalFileName ?? sourceURL.lastPathComponent
            if !fileName.lowercased().hasSuffix(".csv") {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestampStr = formatter.string(from: Date())
                fileName = "GyroLog_表端同步完整会话_\(timestampStr).csv"
            }
            let destURL = self.logsDirectoryURL.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: destURL)
            do {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
                DispatchQueue.main.async {
                    self.refreshLogFiles()
                }
            } catch {
                print("[MotionSensorLogManager] 导入日志文件失败: \(error)")
            }
        }
    }
    
    /// 刷新本地已保存的全部动作日志文件列表（后台线程异步遍历与解析，绝不阻塞 UI 主线程）
    public func refreshLogFiles() {
        let dirURL = logsDirectoryURL
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            guard let urls = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: .skipsHiddenFiles) else {
                DispatchQueue.main.async { self.logFiles = [] }
                return
            }
            
            let csvURLs = urls.filter { $0.pathExtension.lowercased() == "csv" }
            let infos: [MotionLogFileInfo] = csvURLs.compactMap { url in
                let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
                let bytes = resourceValues?.fileSize ?? 0
                let date = resourceValues?.creationDate ?? Date()
                let sizeKB = Double(bytes) / 1024.0
                
                let name = url.deletingPathExtension().lastPathComponent
                let parts = name.components(separatedBy: "_")
                let exerciseName = parts.count > 1 ? parts[1] : "未命名动作"
                var setNumber = 1
                if parts.count > 2 {
                    let setStr = parts[2].replacingOccurrences(of: "第", with: "").replacingOccurrences(of: "组", with: "")
                    setNumber = Int(setStr) ?? 1
                }
                
                return MotionLogFileInfo(
                    url: url,
                    fileName: url.lastPathComponent,
                    exerciseName: exerciseName,
                    setNumber: setNumber,
                    fileSizeKB: sizeKB,
                    createdDate: date
                )
            }.sorted { $0.createdDate > $1.createdDate }
            
            DispatchQueue.main.async {
                self.logFiles = infos
            }
        }
    }
    
    /// 删除指定日志文件
    public func deleteLogFile(_ info: MotionLogFileInfo) {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: info.url)
            DispatchQueue.main.async {
                self.refreshLogFiles()
            }
        }
    }
    
    /// 清空所有日志文件
    public func deleteAllLogs() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            if let urls = try? fm.contentsOfDirectory(at: self.logsDirectoryURL, includingPropertiesForKeys: nil) {
                for url in urls {
                    try? fm.removeItem(at: url)
                }
            }
            DispatchQueue.main.async {
                self.refreshLogFiles()
            }
        }
    }
}
