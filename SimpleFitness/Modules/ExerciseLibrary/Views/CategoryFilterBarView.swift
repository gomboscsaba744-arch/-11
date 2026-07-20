import SwiftUI

public struct CategoryFilterBarView: View {
    @Binding public var selectedCategory: String
    private let categories = [
        "全部部位", "胸部", "背部", "肩部",
        "手臂", "大腿", "小腿",
        "腹部核心", "有氧心肺", "全身综合", "其他器械"
    ]
    
    public init(selectedCategory: Binding<String>) {
        self._selectedCategory = selectedCategory
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(selectedCategory == category ? .bold : .medium)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? AppColors.accentBlue : AppColors.cardBackground)
                            .foregroundColor(selectedCategory == category ? .white : AppColors.primaryText)
                            .clipShape(Capsule())
                            .shadow(color: selectedCategory == category ? AppColors.accentBlue.opacity(0.3) : Color.clear, radius: 6, y: 2)
                    }
                }
            }
        }
    }
}
