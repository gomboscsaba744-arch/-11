import SwiftUI

public struct PlanCustomizationView: View {
    @State private var planName: String = ""
    @State private var planNotes: String = ""
    @State private var exercises: [PlanExerciseItemMock] = PlanMockData.sampleExercises
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("定制训练课表")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .padding(.top, 8)
                        
                        Text("课表名称")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        // 名称与备注输入卡片
                        VStack(spacing: 0) {
                            TextField("例如：练胸与三头肌日", text: $planName)
                                .padding()
                            
                            Divider()
                                .padding(.horizontal)
                            
                            TextField("简要备注...", text: $planNotes)
                                .padding()
                        }
                        .standardCardStyle()
                        
                        HStack {
                            Text("动作编排列表 (可拖拽排序)")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                            
                            Spacer()
                            
                            Button("添加动作") {}
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.accentBlue)
                        }
                        
                        // 编排列表容器
                        VStack(spacing: 0) {
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, item in
                                PlanExerciseRowView(item: item) {
                                    if index < exercises.count {
                                        exercises.remove(at: index)
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                if index < exercises.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .standardCardStyle()
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                }
                
                // 底部悬浮按钮
                VStack {
                    Spacer()
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("立即开始本计划训练")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.accentBlue)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    PlanCustomizationView()
}
