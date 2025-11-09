// UIBlocks.swift — 화면에 쓰이는 재사용 뷰 모듈
import SwiftUI

// 상단 상태 HUD (예: "운동" / "라운드 1/6")
struct StatusHUD: View {
    let stage: String
    let roundText: String

    var body: some View {
        VStack(spacing: 8) {
            Text(stage)
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .shadow(radius: 2, y: 1)
                .padding(.top, 16)
                .foregroundStyle(.white)

            Text(roundText)
                .font(.system(size: 64, weight: .black, design: .rounded)) // 폰트 크기 ↑
                .monospacedDigit()
                .shadow(radius: 2, y: 1)
                .foregroundStyle(.white)

        }
    }
}

// 초대형 카운트다운 숫자
struct BigTimerText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 120, weight: .black, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.45)
            .shadow(radius: 2, y: 1)
            .foregroundStyle(.white)
    }
}

// 라운드 프리셋 버튼 (3R / 5R / 10R)
struct RoundPresetButton: View {
    let rounds: Int
    let set: (Int) -> Void

    var body: some View {
        Button { set(rounds) } label: {
            Text("\(rounds)R")
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.white.opacity(0.85)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(rounds) 라운드 프리셋")
    }
}

// + / – 스텝퍼 버튼
enum StepperKind { case plus, minus }

struct LargeStepperButton: View {
    let kind: StepperKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: kind == .plus ? "plus" : "minus")
                .font(.system(size: 28, weight: .bold))
                .frame(width: 80, height: 80)               // 더 크게
                .background(
                    Circle()
                        .fill(Color.white)                 // 보조 원 제거, 단순 아이콘+원
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                )
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(kind == .plus ? "값 증가" : "값 감소")
    }
}

