import SwiftUI

public struct HistoryView: View {
    private let records: [HistoryRecordMock] = HistoryMockData.sampleRecords
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("训练历史与成果")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .padding(.top, 8)
                        
                        Text("本周概览")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        WeeklySummaryView()
                        
                        Text("近期记录 (支持 CloudKit iCloud 云同步)")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                HistoryRecordRowView(record: record)
                                    .padding(.horizontal, 16)
                                
                                if index < records.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .standardCardStyle()
                        
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
    HistoryView()
}
