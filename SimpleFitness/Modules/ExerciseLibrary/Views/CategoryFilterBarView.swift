import SwiftUI

public struct CategoryFilterBarView: View {
    @Binding public var selectedCategory: String
    private let categories = ["全部部位", "胸部", "背部", "腿部", "肩部"]
    
    public init(selectedCategory: Binding<String>) {
        self._selectedCategory = selectedCategory
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? AppColors.accentBlue : AppColors.cardBackground)
                            .foregroundColor(selectedCategory == category ? .white : AppColors.primaryText)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
