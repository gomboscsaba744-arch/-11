import Foundation

public struct ExerciseItemMock: Identifiable {
    public let id = UUID()
    public var name: String
    public var category: String
    public var description: String
    public var restSeconds: Int
    public var thresholdG: String
    public var badgeLetter: String
    
    public init(name: String, category: String, description: String, restSeconds: Int, thresholdG: String, badgeLetter: String) {
        self.name = name
        self.category = category
        self.description = description
        self.restSeconds = restSeconds
        self.thresholdG = thresholdG
        self.badgeLetter = badgeLetter
    }
}

public struct ExerciseMockData {
    public static let sampleItems: [ExerciseItemMock] = [
        ExerciseItemMock(
            name: "哑铃前平举",
            category: "肩部 (Shoulders)",
            description: "手持哑铃向正前方抬起至视线高度，专门加强三角肌前束。",
            restSeconds: 60,
            thresholdG: "+0.45g",
            badgeLetter: "Y"
        ),
        ExerciseItemMock(
            name: "俯身哑铃飞鸟 / 蝴蝶机反向飞鸟",
            category: "肩部 (Shoulders)",
            description: "俯身或正对蝴蝶机向两侧后方展开手臂，精准填补三角肌后束短板。",
            restSeconds: 60,
            thresholdG: "+0.40g",
            badgeLetter: "Z"
        ),
        ExerciseItemMock(
            name: "绳索面拉 (Face Pull)",
            category: "肩部 (Shoulders)",
            description: "使用双头绳将滑轮拉向脸部面部，极好地强化三角肌后束与外旋肌群，保护肩关节康复。",
            restSeconds: 60,
            thresholdG: "+0.45g",
            badgeLetter: "Z"
        )
    ]
}
