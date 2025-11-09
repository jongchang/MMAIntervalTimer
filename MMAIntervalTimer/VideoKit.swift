// VideoKit.swift
import SwiftUI
import AVKit
import Combine   // ObservableObject 용

// MARK: - 단일 파일 무한 루프 플레이어
final class VideoLooper: NSObject, ObservableObject {
    let player: AVQueuePlayer
    private let item: AVPlayerItem
    private var token: Any?

    init?(named name: String, ext: String = "mp4") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        self.item  = AVPlayerItem(url: url)
        self.player = AVQueuePlayer(items: [item])
        super.init()

        // 무한 루프
        token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            self.player.seek(to: .zero)
            self.player.play()
        }

        player.actionAtItemEnd = .none
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
    }

    deinit {
        if let token { NotificationCenter.default.removeObserver(token) }
    }

    func play()  { player.play() }
    func pause() { player.pause() }
    func stop()  { player.pause(); player.seek(to: .zero) }
}

// MARK: - 운동/휴식/시작/완료 영상 컨트롤러
final class VideoService: ObservableObject {
    // 파일명: start.mp4, work.mp4, rest.mp4, finish.mp4
    let start:  VideoLooper?
    let work:   VideoLooper?
    let rest:   VideoLooper?
    let finish: VideoLooper?

    init() {
        start  = VideoLooper(named: "start")
        work   = VideoLooper(named: "work")
        rest   = VideoLooper(named: "rest")
        finish = VideoLooper(named: "finish")
    }

    /// 준비 상태인지에 따라 적절한 플레이어 선택
    func player(for phase: TimerPhase, isPrepare: Bool = false) -> AVPlayer? {
        if isPrepare { return start?.player }            // 운동 준비
        switch phase {
        case .work: return work?.player
        case .rest: return rest?.player
        case .done: return finish?.player                // 완료 화면
        }
    }

    /// 해당 상태의 영상 재생(나머지는 정지)
    func play(for phase: TimerPhase, isPrepare: Bool = false) {
        stopAll()
        if isPrepare { start?.play(); return }
        switch phase {
        case .work: work?.play()
        case .rest: rest?.play()
        case .done: finish?.play()
        }
    }

    func pauseAll() { start?.pause(); work?.pause(); rest?.pause(); finish?.pause() }
    func resume(for phase: TimerPhase, isPrepare: Bool = false) { play(for: phase, isPrepare: isPrepare) }
    func stopAll() { start?.stop(); work?.stop(); rest?.stop(); finish?.stop() }
}

// MARK: - 숫자 위에 얹는 영상 레이어
struct VideoOverlay: View {
    let player: AVPlayer?
    let opacity: Double

    init(player: AVPlayer?, opacity: Double = 0.35) {
        self.player = player
        self.opacity = opacity
    }

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .allowsHitTesting(false)
                    .scaledToFill()
                    .blendMode(.screen)
                    .opacity(opacity)
                    .clipped()
            }
        }
    }
}
