import SwiftUI

public struct ExerciseLibraryView: View {
    @State private var selectedCategory: String = "全部部位"
    @State private var searchText: String = ""
    @State private var selectedItemForDetail: ExerciseItemMock? = nil
    
    public init() {}
    
    private var filteredItems: [ExerciseItemMock] {
        let allItems = ExerciseMockData.sampleItems
        return allItems.filter { item in
            let categoryMatch: Bool
            if selectedCategory == "全部部位" {
                categoryMatch = true
            } else {
                let prefix = selectedCategory.components(separatedBy: " ").first ?? selectedCategory
                categoryMatch = item.category.contains(prefix) || item.categoryZh.contains(prefix) || item.categoryEn.localizedCaseInsensitiveContains(prefix)
            }
            
            let searchMatch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.nameZh.localizedCaseInsensitiveContains(searchText) ||
                item.nameEn.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText) ||
                item.target.localizedCaseInsensitiveContains(searchText) ||
                item.equipment.localizedCaseInsensitiveContains(searchText)
            
            return categoryMatch && searchMatch
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("训练动作库")
                                        .font(.largeTitle)
                                        .fontWeight(.black)
                                        .foregroundColor(AppColors.primaryText)
                                    Text("收录并已完成陀螺仪标定的 \(ExerciseMockData.sampleItems.count) 个标准训练动作")
                                        .font(.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Text("\(filteredItems.count) 个动作")
                                    .font(.caption.weight(.heavy))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppColors.pillBackground)
                                    .foregroundColor(AppColors.accentBlue)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 8)
                            
                            CategoryFilterBarView(selectedCategory: $selectedCategory)
                            
                            if filteredItems.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 36))
                                        .foregroundColor(AppColors.secondaryText.opacity(0.6))
                                    Text("未找到对应条件的训练动作")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    Text("请尝试更换分类或清除搜索关键词")
                                        .font(.caption)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                LazyVStack(spacing: 14) {
                                    ForEach(filteredItems, id: \.id) { item in
                                        ExerciseCardView(item: item) {
                                            selectedItemForDetail = item
                                        }
                                    }
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .searchable(text: $searchText, prompt: "搜索动作中文/英文名称、器械或目标肌群...")
            .sheet(item: $selectedItemForDetail) { item in
                ExercisePanoramaModalSheetView(item: item)
            }
        }
    }
}

#Preview {
    ExerciseLibraryView()
}
