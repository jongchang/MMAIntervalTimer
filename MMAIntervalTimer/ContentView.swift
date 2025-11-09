// ContentView.swift — 메인 화면 & 타이머
import SwiftUI
import Combine
import UIKit
import AVKit

public struct ContentView: View {
    @Environment(\.colorScheme) private var scheme

    // 설정
    @State private var cfg = TimerConfig()       // rounds, work, rest
    @State private var round = 1                 // 현재 라운드

    // 상태
    @State private var phase: TimerPhase = .work // work/rest/done
    @State private var remain = 0
    @State private var running = false
    @State private var sessionStarted = false
    @State private var paused = false

    // 운동 준비(첫 라운드 전만 사용)
    @State private var preRollActive = false
    @State private var preRollRemain = 0
    private let preRollSeconds = 10

    // 영상 서비스 + 오퍼시티
    @StateObject private var video = VideoService()
    @State private var videoOpacity: Double = 0.35

    // 1초 틱
    @State private var ticker =
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                // 배경: 운동 준비면 회색, 완료면 검정, 그 외 기존 단계 그라데이션
                Group {
                    if phase == .done {
                        Color.black
                    } else if sessionStarted && preRollActive {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.9), Color.gray.opacity(0.9)],
                            startPoint: .top, endPoint: .bottom
                        )
                    } else {
                        DesignSystem.background(for: sessionStarted ? phase : .work, in: scheme)
                    }
                }
                .ignoresSafeArea()


                // 일시정지 시 화면 45% 디밍
                Color.black.opacity((paused && sessionStarted) ? 0.45 : 0.0)
                    .ignoresSafeArea()

                VStack(spacing: 12) {

                    // 상단 HUD
                    StatusHUD(
                        stage: sessionStarted
                            ? (preRollActive ? "운동 준비" : phase.rawValue)
                            : "",
                        roundText: "총 \(cfg.rounds) 라운드"
                    )

                    Spacer(minLength: 8)

                    if sessionStarted {
                        // 숫자 위로 영상 오버레이
                        ZStack {
                            VideoOverlay(
                                player: video.player(for: phase, isPrepare: preRollActive),
                                opacity: videoOpacity
                            )
                            .allowsHitTesting(false)
                            .clipped()

                            // 카운트다운 숫자: 화면 가득
                            GeometryReader { geo in
                                let side = min(geo.size.width, geo.size.height)
                                let fontSize = side * 0.80
                                Text(formatMSS(preRollActive ? preRollRemain : remain))
                                    .font(.system(size: fontSize, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .shadow(radius: 2, y: 1)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                            .frame(height: 200)
                            .padding(.top, 6)
                        }
                    } else {
                        // 시작 전 구성 카드
                        VStack(spacing: 24) {

                            // 라운드 프리셋
                            HStack(spacing: 14) {
                                RoundPresetButton(rounds: 3)  { _ in setRounds(3) }
                                RoundPresetButton(rounds: 5)  { _ in setRounds(5) }
                                RoundPresetButton(rounds: 10) { _ in setRounds(10) }
                            }

                            VStack(spacing: 22) {

                                // 라운드 편집(무색)
                                VStack(spacing: 12) {
                                    Text("라운드")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: 18) {
                                        LargeStepperButton(kind: .minus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.rounds = max(1, cfg.rounds - 1)
                                        }
                                        Text("\(cfg.rounds)R")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.black)
                                            .frame(minWidth: 80)
                                        LargeStepperButton(kind: .plus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.rounds = min(20, cfg.rounds + 1)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                // 운동 편집(주황)
                                VStack(spacing: 12) {
                                    Text("운동")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(Color(DesignSystem.work))
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: 18) {
                                        LargeStepperButton(kind: .minus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.work = max(5, cfg.work - 5)
                                        }
                                        Text("\(cfg.work)s")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.black)
                                            .frame(minWidth: 80)
                                        LargeStepperButton(kind: .plus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.work = min(1800, cfg.work + 5)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                // 휴식 편집(초록 팔레트 Top)
                                VStack(spacing: 12) {
                                    Text("휴식")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(Color(DesignSystem.restTop))
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: 18) {
                                        LargeStepperButton(kind: .minus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.rest = max(0, cfg.rest - 5)
                                        }
                                        Text("\(cfg.rest)s")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.black)
                                            .frame(minWidth: 80)
                                        LargeStepperButton(kind: .plus) {
                                            Haptic.tap(); BeepPlayer.shared.tap()
                                            cfg.rest = min(600, cfg.rest + 5)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(DesignSystem.cardBG)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(DesignSystem.cardStroke, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer()

                    // 하단 컨트롤
                    HStack(spacing: 16) {
                        if sessionStarted {
                            Button {
                                Haptic.tap(); BeepPlayer.shared.tap()
                                paused.toggle()
                                if paused {
                                    Haptic.warning()
                                    video.pauseAll()
                                } else {
                                    Haptic.success()
                                    video.resume(for: phase, isPrepare: preRollActive)
                                }
                            } label: {
                                Text(paused ? "재개" : "일시정지")
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 64)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                                    .foregroundStyle(.black)
                            }

                            Button {
                                Haptic.tap(); BeepPlayer.shared.tap()
                                stop()
                            } label: {
                                Text("정지")
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 64)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                                    .foregroundStyle(.black)
                            }
                        } else {
                            Button {
                                Haptic.success(); BeepPlayer.shared.long()
                                startSession()
                            } label: {
                                Label("시작", systemImage: "play.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 72)
                                    .background(RoundedRectangle(cornerRadius: 24).fill(.white))
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .foregroundStyle(.white)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("MMA 인터벌 트레이닝 타이머")
            }
        }
        .onReceive(ticker) { _ in
            guard running, !paused else { return }
            if preRollActive {
                if preRollRemain > 0 {
                    preRollRemain -= 1
                } else {
                    // 운동 준비 종료 → 1라운드 운동 시작
                    preRollActive = false
                    beginWorkForCurrentRound()
                }
            } else {
                tick() // 일반 work/rest 카운트
            }
        }
        .onAppear {
            BeepPlayer.shared.loadAll()
            if !sessionStarted { cfg.rounds = 10 }
            video.stopAll() // 초기 진입 시 재생 안 함
        }
        .onChange(of: sessionStarted) { started in
            if started { video.play(for: phase, isPrepare: preRollActive) }
            else { video.stopAll() }
        }
        .onChange(of: phase) { newPhase in
            video.play(for: newPhase, isPrepare: preRollActive)   // .done이면 finish.mp4
        }
        .onChange(of: paused) { isPaused in
            isPaused ? video.pauseAll() : video.resume(for: phase, isPrepare: preRollActive)
        }
        .onDisappear {
            video.stopAll()
        }
    }

    // MARK: - 로직
    private func setRounds(_ r: Int) {
        cfg.rounds = r
        Haptic.tap(); BeepPlayer.shared.tap()
    }

    private func startSession() {
        round = 1
        sessionStarted = true
        running = true
        paused = false
        UIApplication.shared.isIdleTimerDisabled = true

        // 첫 라운드 전 10초 운동 준비
        preRollActive = true
        preRollRemain = preRollSeconds

        // 배경/상태는 work로 유지하되, 실제 카운트는 프리롤에서 진행
        phase = .work
        remain = 0

        // 준비 동안에는 start.mp4 재생
        video.play(for: .work, isPrepare: true)
    }

    private func stop() {
        running = false
        paused = false
        sessionStarted = false
        UIApplication.shared.isIdleTimerDisabled = false

        preRollActive = false
        preRollRemain = 0

        remain = 0
        round = 1
        phase = .work

        video.stopAll()
    }

    private func tick() {
        if remain > 0 { remain -= 1 } else { nextStep() }
    }

    private func nextStep() {
        switch phase {
        case .work:
            if cfg.rest > 0 {
                begin(.rest, seconds: cfg.rest)
            } else {
                advanceRoundOrFinish()
            }
        case .rest:
            advanceRoundOrFinish()
        case .done:
            running = false
        }
    }

    private func advanceRoundOrFinish() {
        if round < cfg.rounds {
            round += 1
            begin(.work, seconds: cfg.work) // 2라운드부터는 운동 준비 없음
        } else {
            finishWorkout()
        }
    }

    private func finishWorkout() {
        running = false
        paused = false
        phase = .done
        UIApplication.shared.isIdleTimerDisabled = false
        BeepPlayer.shared.bell()

        // 완료 화면: finish.mp4 재생
        video.play(for: .done)
    }

    private func beginWorkForCurrentRound() {
        begin(.work, seconds: cfg.work)
    }

    private func begin(_ p: TimerPhase, seconds: Int) {
        phase = p
        remain = max(0, seconds)
        BeepPlayer.shared.short()

        // 단계 전환할 때 해당 영상 재생
        video.play(for: p, isPrepare: false)
    }
}
