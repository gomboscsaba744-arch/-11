import Foundation

public struct ExerciseItemMock: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var stringId: String
    public var nameZh: String
    public var nameEn: String
    public var categoryZh: String
    public var categoryEn: String
    public var descriptionZh: String
    public var descriptionEn: String
    public var stepsZh: [String]
    public var stepsEn: [String]
    public var equipmentZh: String
    public var equipmentEn: String
    public var targetZh: String
    public var targetEn: String
    public var restSeconds: Int
    public var thresholdG: String
    public var badgeLetter: String
    public var dominantAxis: Int
    public var minRatio: Double
    public var motionProfile: String
    public var gifUrl: String
    public var imageUrl: String
    
    private var isEnglish: Bool {
        return (UserDefaults.standard.string(forKey: "exerciseLanguage") ?? "zh") == "en"
    }

    public var name: String {
        get { isEnglish ? nameEn : nameZh }
        set { if isEnglish { nameEn = newValue } else { nameZh = newValue } }
    }

    public var category: String {
        get { isEnglish ? categoryEn : categoryZh }
        set { if isEnglish { categoryEn = newValue } else { categoryZh = newValue } }
    }

    public var description: String {
        get { isEnglish ? descriptionEn : descriptionZh }
        set { if isEnglish { descriptionEn = newValue } else { descriptionZh = newValue } }
    }

    public var steps: [String] {
        get { isEnglish ? stepsEn : stepsZh }
        set { if isEnglish { stepsEn = newValue } else { stepsZh = newValue } }
    }

    public var equipment: String {
        get { isEnglish ? equipmentEn : equipmentZh }
        set { if isEnglish { equipmentEn = newValue } else { equipmentZh = newValue } }
    }

    public var target: String {
        get { isEnglish ? targetEn : targetZh }
        set { if isEnglish { targetEn = newValue } else { targetZh = newValue } }
    }

    public init(name: String, category: String, description: String, restSeconds: Int, thresholdG: String, badgeLetter: String) {
        self.id = UUID()
        self.stringId = UUID().uuidString
        self.nameZh = name
        self.nameEn = name
        self.categoryZh = category
        self.categoryEn = category
        self.descriptionZh = description
        self.descriptionEn = description
        self.stepsZh = [description]
        self.stepsEn = [description]
        self.equipmentZh = "其他器械"
        self.equipmentEn = "Other"
        self.targetZh = "综合肌群"
        self.targetEn = "General"
        self.restSeconds = restSeconds
        self.thresholdG = thresholdG
        self.badgeLetter = badgeLetter
        self.dominantAxis = 1
        self.minRatio = 0.35
        self.motionProfile = "upperBodyPull"
        self.gifUrl = ""
        self.imageUrl = ""
    }

    enum CodingKeys: String, CodingKey {
        case id, stringId, nameZh, nameEn, categoryZh, categoryEn
        case descriptionZh, descriptionEn, stepsZh, stepsEn
        case equipmentZh, equipmentEn, targetZh, targetEn
        case restSeconds, thresholdG, badgeLetter, dominantAxis, minRatio, motionProfile
        case gifUrl, imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        let decodedId = try? container.decodeIfPresent(String.self, forKey: .id)
        let decodedStringId = try? container.decodeIfPresent(String.self, forKey: .stringId)
        self.stringId = decodedId ?? decodedStringId ?? UUID().uuidString
        self.nameZh = (try? container.decodeIfPresent(String.self, forKey: .nameZh)) ?? ""
        self.nameEn = (try? container.decodeIfPresent(String.self, forKey: .nameEn)) ?? ""
        self.categoryZh = (try? container.decodeIfPresent(String.self, forKey: .categoryZh)) ?? ""
        self.categoryEn = (try? container.decodeIfPresent(String.self, forKey: .categoryEn)) ?? ""
        self.descriptionZh = (try? container.decodeIfPresent(String.self, forKey: .descriptionZh)) ?? ""
        self.descriptionEn = (try? container.decodeIfPresent(String.self, forKey: .descriptionEn)) ?? ""
        self.stepsZh = (try? container.decodeIfPresent([String].self, forKey: .stepsZh)) ?? [self.descriptionZh]
        self.stepsEn = (try? container.decodeIfPresent([String].self, forKey: .stepsEn)) ?? [self.descriptionEn]
        self.equipmentZh = (try? container.decodeIfPresent(String.self, forKey: .equipmentZh)) ?? "自重"
        self.equipmentEn = (try? container.decodeIfPresent(String.self, forKey: .equipmentEn)) ?? "Body Weight"
        self.targetZh = (try? container.decodeIfPresent(String.self, forKey: .targetZh)) ?? ""
        self.targetEn = (try? container.decodeIfPresent(String.self, forKey: .targetEn)) ?? ""
        self.restSeconds = (try? container.decodeIfPresent(Int.self, forKey: .restSeconds)) ?? 60
        self.thresholdG = (try? container.decodeIfPresent(String.self, forKey: .thresholdG)) ?? "+0.50g"
        self.badgeLetter = (try? container.decodeIfPresent(String.self, forKey: .badgeLetter)) ?? "O"
        self.dominantAxis = (try? container.decodeIfPresent(Int.self, forKey: .dominantAxis)) ?? 1
        self.minRatio = (try? container.decodeIfPresent(Double.self, forKey: .minRatio)) ?? 0.35
        self.motionProfile = (try? container.decodeIfPresent(String.self, forKey: .motionProfile)) ?? "upperBodyPull"
        self.gifUrl = (try? container.decodeIfPresent(String.self, forKey: .gifUrl)) ?? ""
        self.imageUrl = (try? container.decodeIfPresent(String.self, forKey: .imageUrl)) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stringId, forKey: .id)
        try container.encode(stringId, forKey: .stringId)
        try container.encode(nameZh, forKey: .nameZh)
        try container.encode(nameEn, forKey: .nameEn)
        try container.encode(categoryZh, forKey: .categoryZh)
        try container.encode(categoryEn, forKey: .categoryEn)
        try container.encode(descriptionZh, forKey: .descriptionZh)
        try container.encode(descriptionEn, forKey: .descriptionEn)
        try container.encode(stepsZh, forKey: .stepsZh)
        try container.encode(stepsEn, forKey: .stepsEn)
        try container.encode(equipmentZh, forKey: .equipmentZh)
        try container.encode(equipmentEn, forKey: .equipmentEn)
        try container.encode(targetZh, forKey: .targetZh)
        try container.encode(targetEn, forKey: .targetEn)
        try container.encode(restSeconds, forKey: .restSeconds)
        try container.encode(thresholdG, forKey: .thresholdG)
        try container.encode(badgeLetter, forKey: .badgeLetter)
        try container.encode(dominantAxis, forKey: .dominantAxis)
        try container.encode(minRatio, forKey: .minRatio)
        try container.encode(motionProfile, forKey: .motionProfile)
        try container.encode(gifUrl, forKey: .gifUrl)
        try container.encode(imageUrl, forKey: .imageUrl)
    }
}

public struct ExerciseMockData {
    private static var _cachedItems: [ExerciseItemMock]? = nil
    
    public static var sampleItems: [ExerciseItemMock] {
        if let cached = _cachedItems {
            return cached
        }
        let items = loadExercisesFromDatabase()
        _cachedItems = items
        return items
    }
    
    public static func reloadDatabase() {
        _cachedItems = nil
    }
    
    private static func loadExercisesFromDatabase() -> [ExerciseItemMock] {
        // First check bundle for exercises_database.json
        if let url = Bundle.main.url(forResource: "exercises_database", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let items = try JSONDecoder().decode([ExerciseItemMock].self, from: data)
                return items
            } catch {
                print("Failed to decode exercises_database.json from bundle: \(error)")
            }
        }
        
        // Check local file path fallback
        let fallbackPath = "/Users/a171325./Documents/新构建版软件/SimpleFitness/Modules/PlanCustomization/Models/Models/exercises_database.json"
        if let data = try? Data(contentsOf: URL(fileURLWithPath: fallbackPath)),
           let items = try? JSONDecoder().decode([ExerciseItemMock].self, from: data) {
            return items
        }
        
        // Return fallback basic item if not loaded
        return [
            ExerciseItemMock(name: "杠铃平板卧推", category: "胸部", description: "经典三大项之一，全方位构建胸大肌中束与核心推力基础。", restSeconds: 90, thresholdG: "+0.65g", badgeLetter: "X")
        ]
    }
}
