import SwiftUI

public struct PlanExerciseRowView: View {
    public var item: PlanExerciseItemMock
    public var onEdit: (() -> Void)?
    public var onDelete: () -> Void
    
    public init(item: PlanExerciseItemMock, onEdit: (() -> Void)? = nil, onDelete: @escaping () -> Void = {}) {
        self.item = item
        self.onEdit = onEdit
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
                
                HStack(spacing: 14) {
                    if let onEdit = onEdit {
                        Button(action: onEdit) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.pencil")
                                Text("参数编辑")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(AppColors.accentBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.pillBackground)
                            .clipShape(Capsule())
                        }
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.dangerRed)
                    }
                }
            }
            
            HStack(spacing: 16) {
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
                    Text("\(item.restSeconds)秒")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("动作间")
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(item.exerciseRestSeconds)秒")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
    }
}
