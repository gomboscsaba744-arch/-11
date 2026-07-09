import SwiftUI

public struct ExerciseLibraryView: View {
    @State private var selectedCategory: String = "全部部位"
    private let items: [ExerciseItemMock] = ExerciseMockData.sampleItems
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("训练动作库")
                                .font(.largeTitle)
                                .fontWeight(.black)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(AppColors.accentBlue)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 8)
                        
                        CategoryFilterBarView(selectedCategory: $selectedCategory)
                        
                        VStack(spacing: 14) {
                            ForEach(items, id: \.id) { item in
                                ExerciseCardView(item: item)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ExerciseLibraryView()
}
