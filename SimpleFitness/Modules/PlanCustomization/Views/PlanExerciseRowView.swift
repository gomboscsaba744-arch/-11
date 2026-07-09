import SwiftUI

public struct PlanExerciseRowView: View {
    public var item: PlanExerciseItemMock
    public var onDelete: () -> Void
    
    public init(item: PlanExerciseItemMock, onDelete: @escaping () -> Void = {}) {
        self.item = item
        self.onDelete = onDelete
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppColors.dangerRed)
                }
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("组数 x 次数")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(item.sets)组 x \(item.reps)次")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("目标负重")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                    Text(String(format: "%.1f kg", item.targetWeightKg))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("组间休息")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(item.restSeconds) 秒")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
    }
}
