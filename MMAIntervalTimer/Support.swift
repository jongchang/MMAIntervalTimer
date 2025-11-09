// Support.swift — 공용 타입 + 유틸
import SwiftUI
import AVFoundation

// MARK: 공용 타입(단일 출처)
enum TimerPhase: String {
    case work = "운동"
    case rest = "휴식"
    case done = "완료"
}

struct TimerConfig {
    var rounds: Int = 6
    var work:   Int = 60
    var rest:   Int = 30
}

// MARK: 시간 포맷
@MainActor
func formatMSS(_ total: Int) -> String {
    let m = total / 60
    let s = total % 60
    return String(format: "%d:%02d", m, s)
}

// MARK: Haptic
enum Haptic {
    static func tap()     { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// MARK: 효과음
final class BeepPlayer: NSObject {
    static let shared = BeepPlayer()

    private var shortP: AVAudioPlayer?
    private var longP:  AVAudioPlayer?
    private var bellP:  AVAudioPlayer?
    private var tapP:   AVAudioPlayer?

    func loadAll() {
        configureSession()
        shortP = load(name: "beep_short",  ext: "wav")
        longP  = load(name: "beep_long",   ext: "wav")
        bellP  = load(name: "boxing_bell", ext: "wav")
        tapP   = load(name: "tap_click",   ext: "wav")
    }

    func short() { shortP?.currentTime = 0; shortP?.play() }
    func long()  { longP?.currentTime  = 0; longP?.play()  }
    func bell()  { bellP?.currentTime  = 0; bellP?.play()  }
    func tap()   { tapP?.currentTime   = 0; tapP?.play()   }

    private func load(name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return nil }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            return p
        } catch { return nil }
    }
    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
}
