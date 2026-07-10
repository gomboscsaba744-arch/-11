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
        // 胸部 (Chest)
        ExerciseItemMock(
            name: "杠铃平板卧推",
            category: "胸部 (Chest)",
            description: "经典三大项之一，全方位构建胸大肌中束与核心推力基础。",
            restSeconds: 90,
            thresholdG: "+0.65g",
            badgeLetter: "X"
        ),
        ExerciseItemMock(
            name: "上斜哑铃卧推",
            category: "胸部 (Chest)",
            description: "30-45度倾斜凳面推举，着重刺激上胸肌纤维与三角肌前束过渡区。",
            restSeconds: 75,
            thresholdG: "+0.55g",
            badgeLetter: "X"
        ),
        ExerciseItemMock(
            name: "双杠臂屈伸 (Dips)",
            category: "胸部 (Chest)",
            description: "自重黄金训练动作，前倾发力高效切割下胸外缘与肱三头肌。",
            restSeconds: 60,
            thresholdG: "+0.50g",
            badgeLetter: "X"
        ),
        ExerciseItemMock(
            name: "龙门架绳索夹胸",
            category: "胸部 (Chest)",
            description: "持续张力拉伸与收缩，极佳地刻画胸中缝与胸肌分离度。",
            restSeconds: 45,
            thresholdG: "+0.35g",
            badgeLetter: "X"
        ),
        // 背部 (Back)
        ExerciseItemMock(
            name: "杠铃传统硬拉",
            category: "背部 (Back)",
            description: "爆发性全身综合发力，强化竖脊肌、臀大肌与整个后侧动力链。",
            restSeconds: 120,
            thresholdG: "+0.80g",
            badgeLetter: "B"
        ),
        ExerciseItemMock(
            name: "反手引体向上",
            category: "背部 (Back)",
            description: "经典的垂直高拉发力，拓宽背阔肌外沿呈倒三角倒 V 轮廓。",
            restSeconds: 90,
            thresholdG: "+0.60g",
            badgeLetter: "B"
        ),
        ExerciseItemMock(
            name: "宽握坐姿高位下拉",
            category: "背部 (Back)",
            description: "锁定固定下肢轨迹拉压，精准孤立背阔肌与大圆肌爆发发力。",
            restSeconds: 60,
            thresholdG: "+0.55g",
            badgeLetter: "B"
        ),
        ExerciseItemMock(
            name: "杠铃俯身划船",
            category: "背部 (Back)",
            description: "水平抗阻拉动大重量，深层增加背阔肌厚度与斜方肌中部张力。",
            restSeconds: 90,
            thresholdG: "+0.65g",
            badgeLetter: "B"
        ),
        // 肩部 (Shoulders)
        ExerciseItemMock(
            name: "坐姿哑铃推举",
            category: "肩部 (Shoulders)",
            description: "双臂推举至头顶，全面激活三角肌前束与中束力量与体积。",
            restSeconds: 75,
            thresholdG: "+0.55g",
            badgeLetter: "Y"
        ),
        ExerciseItemMock(
            name: "哑铃前平举",
            category: "肩部 (Shoulders)",
            description: "手持哑铃向正前方抬起至视线高度，专门加强三角肌前束。",
            restSeconds: 60,
            thresholdG: "+0.45g",
            badgeLetter: "Y"
        ),
        ExerciseItemMock(
            name: "哑铃站姿侧平举",
            category: "肩部 (Shoulders)",
            description: "向两侧平展举起，打造宽阔肩部视觉宽度（立体外翻肩）。",
            restSeconds: 45,
            thresholdG: "+0.40g",
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
            description: "使用双头绳将滑轮拉向脸部面部，强化三角肌后束与肩袖健康。",
            restSeconds: 60,
            thresholdG: "+0.45g",
            badgeLetter: "Z"
        ),
        // 腿部 (Legs)
        ExerciseItemMock(
            name: "杠铃自由深蹲",
            category: "腿部 (Legs)",
            description: "训练之王，深层次刺激股四头肌、腘绳肌及下肢整体爆发力。",
            restSeconds: 120,
            thresholdG: "+0.85g",
            badgeLetter: "L"
        ),
        ExerciseItemMock(
            name: "坐姿腿屈伸",
            category: "腿部 (Legs)",
            description: "器械固定膝关节前伸，彻底对股直肌进行极致挤压与泵血充血。",
            restSeconds: 60,
            thresholdG: "+0.50g",
            badgeLetter: "L"
        ),
        // 手臂 (Arms)
        ExerciseItemMock(
            name: "站姿杠铃/哑铃二头弯举",
            category: "手臂 (Arms)",
            description: "保持大臂夹紧体侧屈肘，雕琢二头肌肌峰与前臂协调控制。",
            restSeconds: 60,
            thresholdG: "+0.45g",
            badgeLetter: "A"
        ),
        ExerciseItemMock(
            name: "绳索下压肱三头肌",
            category: "手臂 (Arms)",
            description: "垂直下压至手臂充分伸直，强力刻画马蹄袖马蹄铁形状线条。",
            restSeconds: 45,
            thresholdG: "+0.40g",
            badgeLetter: "A"
        ),
        // 腹部核心 (Core)
        ExerciseItemMock(
            name: "悬垂举腿 (Hanging Leg Raise)",
            category: "腹部核心 (Core)",
            description: "引体单杠悬挂收腹抬腿，直击下腹深层核心肌群纤维。",
            restSeconds: 45,
            thresholdG: "+0.35g",
            badgeLetter: "C"
        )
    ]
}
