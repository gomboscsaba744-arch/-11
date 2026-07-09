import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            TrainingView()
                .tabItem {
                    Label("训练", systemImage: "figure.run")
                }
                .tag(0)
            
            PlanCustomizationView()
                .tabItem {
                    Label("课表定制", systemImage: "list.clipboard")
                }
                .tag(1)
            
            ExerciseLibraryView()
                .tabItem {
                    Label("动作库", systemImage: "dumbbell.fill")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("历史成果", systemImage: "clock.arrow.circlepath")
                }
                .tag(3)
        }
        .tint(AppColors.accentBlue)
    }
}

#Preview {
    MainTabView()
}
