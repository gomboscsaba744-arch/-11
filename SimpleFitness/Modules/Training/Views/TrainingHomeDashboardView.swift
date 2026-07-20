import SwiftUI

public struct TrainingHomeDashboardView: View {
    var session: TrainingSessionMock
    var currentRoutineExercises: [PlanExerciseItemMock]
    var onStartWorkout: () -> Void
    var onSelectRoutine: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
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
            // 背景渐变自适应渲染 (深色模式下深邃 OLED 质感，浅色模式下通透清爽)
            Group {
                if colorScheme == .dark {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.08, green: 0.18, blue: 0.32).opacity(0.45),
                            Color(red: 0.06, green: 0.06, blue: 0.08)
                        ]),
                        center: .top,
                        startRadius: 20,
                        endRadius: 500
                    )
                } else {
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.90, green: 0.95, blue: 1.0),
                            AppColors.background
                        ]),
                        center: .top,
                        startRadius: 20,
                        endRadius: 500
                    )
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 顶栏导航与设备状态
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("今日训练概览")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2.0)
                            .foregroundColor(AppColors.secondaryText)
                        Text("运动主页")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(AppColors.primaryText)
                    }
                    Spacer()
                    
                    // 手表实时连接状态胶囊 (精细发光与边框质感)
                    HStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(session.watchTelemetry.isWatchConnected ? .green : .orange)
                        
                        Circle()
                            .fill(session.watchTelemetry.isWatchConnected ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                            .shadow(color: (session.watchTelemetry.isWatchConnected ? Color.green : Color.orange).opacity(0.6), radius: 4)
                        
                        Text(session.watchTelemetry.isWatchConnected ? "Watch 已同步" : "Watch 待命")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.adaptiveCardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(session.watchTelemetry.isWatchConnected ? Color.green.opacity(0.35) : AppColors.adaptiveGlassBorder, lineWidth: 1)
                    )
                    .shadow(color: AppColors.adaptiveCardShadow, radius: 10, y: 3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 2. 英雄计划精选卡片 (Doppelrand Double-Bezel Blueprint Card)
                        heroBlueprintCard()
                        
                        // 3. 今日训练清单元件列表
                        exercisesListShowcase()
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // 4. 底部吸顶流光悬浮开启训练按键
            VStack {
                Spacer()
                
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                    impact.impactOccurred()
                    onStartWorkout()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .black))
                        Text("开启今日训练")
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.55, blue: 0.98),
                                Color(red: 0.0, green: 0.38, blue: 0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.28), lineWidth: 1.2)
                    )
                    .shadow(color: Color(red: 0.0, green: 0.45, blue: 0.95).opacity(0.42), radius: 18, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Hero Blueprint Card (双层表框流光视效)
    @ViewBuilder
    private func heroBlueprintCard() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.orange)
                    Text("今日训练计划")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.16))
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppColors.adaptivePillBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(session.workoutTitle)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                
                Text("双端数据实时同步 · 精准记录每次训练")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Divider()
                .background(AppColors.secondaryText.opacity(0.18))
            
            // 核心训练数据网格
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("训练动作")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(currentRoutineExercises.count) 个")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().frame(height: 24).padding(.horizontal, 8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("建议时长")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                    Text("约 45 min")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(AppColors.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().frame(height: 24).padding(.horizontal, 8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("手表状态")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.secondaryText)
                    Text("实时同步")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(AppColors.accentBlue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(22)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.adaptiveCardBackground)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 1.2)
            }
            .shadow(color: AppColors.adaptiveCardShadow, radius: 18, x: 0, y: 8)
        )
    }
    
    // MARK: - Exercises List Showcase (精美高阶训练动作清单)
    @ViewBuilder
    private func exercisesListShowcase() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("训练动作清单")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryText)
                Spacer()
                Text("共 \(currentRoutineExercises.count) 个动作")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(Array(currentRoutineExercises.enumerated()), id: \.offset) { index, item in
                    exerciseRowView(for: item, at: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRowView(for item: PlanExerciseItemMock, at index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.adaptivePillBackground)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.accentBlue.opacity(0.35), lineWidth: 1.5)
                    )
                Text("\(index + 1)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.accentBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "repeat")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(item.sets) 组")
                    }
                    Text("·")
                    HStack(spacing: 3) {
                        Image(systemName: "flame")
                            .font(.system(size: 10, weight: .bold))
                        Text("每组约 \(item.reps) 次")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                if item.targetWeightKg <= 0 {
                    Image(systemName: "figure.core.training")
                        .font(.system(size: 11, weight: .bold))
                    Text("自重")
                        .font(.system(size: 14, weight: .heavy))
                } else {
                    let weightStr = item.targetWeightKg.truncatingRemainder(dividingBy: 1) == 0
                        ? "\(Int(item.targetWeightKg))"
                        : String(format: "%.1f", item.targetWeightKg)
                    Text("\(weightStr)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                    Text("kg")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .foregroundColor(AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.adaptivePillBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 1)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.adaptiveCardBackground)
                .shadow(color: AppColors.adaptiveCardShadow.opacity(0.6), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColors.adaptiveGlassBorder, lineWidth: 1)
        )
    }
}
