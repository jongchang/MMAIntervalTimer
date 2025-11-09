// DesignSystem.swift — 색/그라데이션/카드
import SwiftUI

struct DesignSystem {
    // 운동 주황
    static let work      = Color(red: 1.00, green: 0.53, blue: 0.16)   // #FF8729
    static let workLight = Color(red: 1.00, green: 0.71, blue: 0.42)   // #FFB56B

    // 휴식 초록 — 3스톱 그라데이션
    static let restTop    = Color(red: 0.06, green: 0.74, blue: 0.34)  // #10BD57
    static let restMid    = Color(red: 0.16, green: 0.66, blue: 0.32)  // #2AA956
    static let restBottom = Color(red: 0.06, green: 0.50, blue: 0.23)  // #0F803B

    // 카드
    static let cardBG     = Color.white.opacity(0.70)
    static let cardStroke = Color.white.opacity(0.35)

    // 배경 그라데이션
    static func background(for phase: TimerPhase, in scheme: ColorScheme) -> LinearGradient {
        switch phase {
        case .work:
            return LinearGradient(colors: [work, workLight], startPoint: .top, endPoint: .bottom)
        case .rest:
            return LinearGradient(
                stops: [
                    .init(color: restTop,    location: 0.00),
                    .init(color: restMid,    location: 0.50),
                    .init(color: restBottom, location: 1.00),
                ],
                startPoint: .top, endPoint: .bottom
            )
        case .done:
            return LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.9)],
                                  startPoint: .top, endPoint: .bottom)
        }
    }
}
