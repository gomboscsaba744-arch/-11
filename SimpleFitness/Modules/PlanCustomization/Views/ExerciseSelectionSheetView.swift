import SwiftUI

/// 真实动作库选择弹窗：供用户在定制训练计划时从完整的动作库中选择动作并添加到当前课表中
public struct ExerciseSelectionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String = "全部部位"
    @State private var searchText: String = ""
    
    private let categories = ["全部部位", "胸部", "背部", "肩部", "腿部", "手臂", "腹部核心"]
    
    public var onSelectExercise: (ExerciseItemMock) -> Void
    
    public init(onSelectExercise: @escaping (ExerciseItemMock) -> Void) {
        self.onSelectExercise = onSelectExercise
    }
    
    private var filteredExercises: [ExerciseItemMock] {
        ExerciseMockData.sampleItems.filter { item in
            let categoryMatch = selectedCategory == "全部部位" || item.category == selectedCategory
            let searchMatch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText) || item.description.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && searchMatch
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. 部位筛选胶囊滑条
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                        selectedCategory = cat
                                    }
                                }) {
                                    Text(cat)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == cat ? .bold : .medium)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? AppColors.accentBlue : AppColors.pillBackground)
                                        .foregroundColor(selectedCategory == cat ? .white : AppColors.primaryText)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    // 2. 动作列表
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredExercises, id: \.id) { item in
                                ExerciseSelectionRowView(item: item) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    onSelectExercise(item)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("从动作库添加动作")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "搜索动作名称或肌群")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
    }
}

/// 动作库选择单行卡片
private struct ExerciseSelectionRowView: View {
    let item: ExerciseItemMock
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // 左侧肌群大写字母缩写圆标
            ZStack {
                Circle()
                    .fill(AppColors.accentBlue.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(item.badgeLetter)
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundColor(AppColors.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(item.category)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.pillBackground)
                        .foregroundColor(AppColors.secondaryText)
                        .clipShape(Capsule())
                }
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                    Text("添加")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.accentBlue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .standardCardStyle()
    }
}
