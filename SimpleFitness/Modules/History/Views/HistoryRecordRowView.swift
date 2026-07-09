import SwiftUI

public struct HistoryRecordRowView: View {
    public var record: HistoryRecordMock
    
    public init(record: HistoryRecordMock) {
        self.record = record
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(record.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Text(record.dateString)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            HStack(spacing: 24) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(record.durationMinutes) 分钟")
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(record.calories) kcal")
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(record.sets) 组")
                }
            }
            .font(.subheadline)
            .foregroundColor(AppColors.secondaryText)
        }
        .padding(.vertical, 12)
    }
}
