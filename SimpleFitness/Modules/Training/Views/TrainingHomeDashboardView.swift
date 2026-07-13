import SwiftUI

public struct TrainingHomeDashboardView: View {
    var session: TrainingSessionMock
    var currentRoutineExercises: [PlanExerciseItemMock]
    var onStartWorkout: () -> Void
    var onSelectRoutine: () -> Void
    
    public init(
        session: TrainingSessionMock,
        currentRoutineExercises: [PlanExerciseItemMock],
        onStartWorkout: @escaping () -> Void,
        onSelectRoutine: @escaping () -> Void
    ) {
        self.session = session
        self.currentRoutineExercises = currentRoutineExercises
        self.onStartWorkout = onStartWorkout
        self.onSelectRoutine = onSelectRoutine
    }
    
    public var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 顶栏标识
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S WORKOUT")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(AppColors.secondaryText)
                        Text("运动主页")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(AppColors.primaryText)
                    }
                    Spacer()
                    
                    // 手表连接状态指示胶囊
                    HStack(spacing: 6) {
                        Circle()
                            .fill(session.watchTelemetry.isWatchConnected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(session.watchTelemetry.isWatchConnected ? "Apple Watch 已连接" : "Watch 待命")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 2. 英雄训练计划精选卡 (Hero Routine Card)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("准备就绪")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.orange)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                                
                                Spacer()
                                
                                Button(action: onSelectRoutine) {
                                    HStack(spacing: 4) {
                                        Text("切换计划")
                                            .font(.system(size: 13, weight: .bold))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.workoutTitle)
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("今日核心突破 · 原生级智能监测与手表同步")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Divider()
                                .background(Color.black.opacity(0.08))
                            
                            HStack(spacing: 24) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("动作总数")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("\(currentRoutineExercises.count) 个动作")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(AppColors.primaryText)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("建议时长")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(AppColors.secondaryText)
                                    Text("约 45 分钟")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(AppColors.primaryText)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.75))
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                            }
                            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                        )
                        
                        // 3. 今日训练清单预览 (Exercises Preview Showcase)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("今日训练清单")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.primaryText)
                                Spacer()
                                Text("共 \(currentRoutineExercises.count) 项")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(.horizontal, 4)
                            
                            VStack(spacing: 10) {
                                ForEach(Array(currentRoutineExercises.enumerated()), id: \.offset) { index, item in
                                    exerciseRowView(for: item, at: index)
                                }
                            }
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // 4. 底部吸顶流光英雄按钮：立刻开启训练
            VStack {
                Spacer()
                
                Button(action: onStartWorkout) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .black))
                        Text("开启今日训练")
                            .font(.system(size: 18, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.28), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRowView(for item: PlanExerciseItemMock, at index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 38, height: 38)
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(AppColors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                Text("\(item.sets) 组 · 每组约 \(item.reps) 次")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Text("\(Int(item.targetWeightKg)) kg")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(AppColors.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }
}
