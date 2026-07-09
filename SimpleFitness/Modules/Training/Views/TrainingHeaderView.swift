import SwiftUI

public struct TrainingHeaderView: View {
    public var session: TrainingSessionMock
    
    public init(session: TrainingSessionMock) {
        self.session = session
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶层状态与心率消耗
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.modeTitle)
                        .font(.footnote)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(session.exerciseName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(session.currentHeartRate)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(session.currentCalories) kcal")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
            
            // 组数与目标负重
            HStack {
                Text("第 \(session.currentSet) / \(session.totalSets) 组")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.accentBlue)
                
                Spacer()
                
                Text(String(format: "目标负重: %.1f kg", session.targetWeightKg))
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}
