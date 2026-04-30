import OrderBotCore
import SwiftUI

public struct OrderKioskScreen: View {
    @State private var viewModel = OrderKioskViewModel()
    @State private var debugInput = ""

    private let sampleUtterances = [
        "我要一份雞腿飯不要辣",
        "再加一碗貢丸湯",
        "雞腿飯改成兩份",
        "貢丸湯不要了",
        "好了",
        "確認"
    ]

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let promptHeight = max(proxy.size.height * 0.2, 132)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    CurrentInteractionPanel(viewModel: viewModel)
                        .frame(width: proxy.size.width * 0.45)

                    OrderSummaryPanel(order: viewModel.order, state: viewModel.state)
                        .frame(width: proxy.size.width * 0.55)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                PromptBar(
                    prompt: viewModel.promptText,
                    debugInput: $debugInput,
                    mascotKind: viewModel.mascotKind,
                    sampleUtterances: sampleUtterances,
                    onStartListening: viewModel.startListening,
                    onSubmit: submitDebugInput,
                    onSample: { viewModel.handleDebugUtterance($0) },
                    onReset: viewModel.reset,
                    onMascotChange: viewModel.setMascotKind
                )
                .frame(height: promptHeight)
            }
            .background(AppTheme.background)
        }
    }

    private func submitDebugInput() {
        viewModel.handleDebugUtterance(debugInput)
        debugInput = ""
    }
}

private struct CurrentInteractionPanel: View {
    let viewModel: OrderKioskViewModel

    var body: some View {
        VStack(spacing: 28) {
            MascotFaceView(kind: viewModel.mascotKind, mood: viewModel.mascotMood)
                .frame(maxWidth: .infinity)

            VStack(spacing: 16) {
                Text(viewModel.currentTitle)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.center)

                Text(viewModel.currentMessage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.72)

                if !viewModel.candidateItems.isEmpty {
                    CandidateList(items: viewModel.candidateItems)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(32)
        .background(AppTheme.leftPanel)
    }
}

private struct MascotFaceView: View {
    let kind: MascotKind
    let mood: MascotMood

    private var caption: String {
        switch mood {
        case .happy:
            return "歡迎光臨"
        case .listening:
            return "我在聽"
        case .thinking:
            return "確認中"
        case .confused:
            return "再說一次"
        case .confirming:
            return "請確認"
        case .completed:
            return "謝謝你"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Group {
                switch kind {
                case .cat:
                    CatDrawing(mood: mood)
                        .frame(width: 200, height: 164)
                case .corgi:
                    CorgiDrawing(mood: mood)
                        .frame(width: 210, height: 172)
                }
            }

            Text(caption)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
    }
}

private struct CatDrawing: View {
    let mood: MascotMood

    private var eyeScale: CGFloat {
        switch mood {
        case .completed:
            return 1.08
        case .listening:
            return 1.14
        default:
            return 1
        }
    }

    private var leftBrowRotation: Double {
        mood == .confused ? -16 : 0
    }

    private var rightBrowRotation: Double {
        mood == .confused ? 16 : 0
    }

    var body: some View {
        ZStack {
            RoundedTriangle(cornerRadius: 12)
                .fill(AppTheme.catFill)
                .overlay(
                    RoundedTriangle(cornerRadius: 12)
                        .stroke(AppTheme.catStroke, lineWidth: 7)
                )
                .frame(width: 62, height: 70)
                .rotationEffect(.degrees(-22))
                .offset(x: -64, y: -48)

            RoundedTriangle(cornerRadius: 12)
                .fill(AppTheme.catFill)
                .overlay(
                    RoundedTriangle(cornerRadius: 12)
                        .stroke(AppTheme.catStroke, lineWidth: 7)
                )
                .frame(width: 62, height: 70)
                .rotationEffect(.degrees(22))
                .offset(x: 64, y: -48)

            RoundedTriangle(cornerRadius: 8)
                .fill(AppTheme.catInnerEar)
                .frame(width: 26, height: 35)
                .rotationEffect(.degrees(-22))
                .offset(x: -64, y: -43)

            RoundedTriangle(cornerRadius: 8)
                .fill(AppTheme.catInnerEar)
                .frame(width: 26, height: 35)
                .rotationEffect(.degrees(22))
                .offset(x: 64, y: -43)

            Circle()
                .fill(AppTheme.catFill)
                .overlay(
                    Circle()
                        .stroke(AppTheme.catStroke, lineWidth: 7)
                )
                .frame(width: 148, height: 148)

            HStack(spacing: 46) {
                CatEye(scale: eyeScale)
                CatEye(scale: eyeScale)
            }
            .offset(y: -20)

            HStack(spacing: 42) {
                Brow()
                    .stroke(AppTheme.catStroke.opacity(0.68), lineWidth: 4)
                    .frame(width: 24, height: 12)
                    .rotationEffect(.degrees(leftBrowRotation))

                Brow()
                    .stroke(AppTheme.catStroke.opacity(0.68), lineWidth: 4)
                    .frame(width: 24, height: 12)
                    .rotationEffect(.degrees(rightBrowRotation))
            }
            .offset(y: -48)

            Circle()
                .fill(AppTheme.catMuzzle)
                .frame(width: 76, height: 58)
                .offset(y: 30)

            CatNose()
                .fill(AppTheme.catNose)
                .frame(width: 30, height: 20)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.76))
                        .frame(width: 7, height: 5)
                        .offset(x: -6, y: -4)
                )
                .offset(y: 16)

            CatMouth(mood: mood)
                .stroke(AppTheme.catStroke, style: StrokeStyle(lineWidth: 4.2, lineCap: .round, lineJoin: .round))
                .frame(width: 54, height: 28)
                .offset(y: 43)

            HStack(spacing: 112) {
                Whiskers()
                    .stroke(AppTheme.catStroke, lineWidth: 4)
                    .frame(width: 44, height: 42)

                Whiskers()
                    .stroke(AppTheme.catStroke, lineWidth: 4)
                    .frame(width: 44, height: 42)
                    .scaleEffect(x: -1, y: 1)
            }
            .offset(y: 21)
        }
    }
}

private struct CatEye: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(AppTheme.catStroke)
                .frame(width: 26 * scale, height: 34 * scale)

            Ellipse()
                .fill(.white)
                .frame(width: 8 * scale, height: 11 * scale)
                .offset(x: -5, y: -8)
        }
    }
}

private struct CatMouth: Shape {
    let mood: MascotMood

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY - 1))

        switch mood {
        case .confused:
            path.move(to: CGPoint(x: rect.midX - 16, y: rect.midY + 8))
            path.addCurve(
                to: CGPoint(x: rect.midX + 16, y: rect.midY + 8),
                control1: CGPoint(x: rect.midX - 7, y: rect.midY - 3),
                control2: CGPoint(x: rect.midX + 7, y: rect.midY + 19)
            )
        case .thinking:
            path.move(to: CGPoint(x: rect.midX - 12, y: rect.midY + 8))
            path.addLine(to: CGPoint(x: rect.midX + 12, y: rect.midY + 8))
        case .listening:
            path.addEllipse(in: CGRect(x: rect.midX - 8, y: rect.midY + 1, width: 16, height: 17))
        default:
            path.addCurve(
                to: CGPoint(x: rect.midX - 18, y: rect.midY + 4),
                control1: CGPoint(x: rect.midX - 8, y: rect.midY + 16),
                control2: CGPoint(x: rect.midX - 18, y: rect.midY + 14)
            )
            path.move(to: CGPoint(x: rect.midX, y: rect.midY - 1))
            path.addCurve(
                to: CGPoint(x: rect.midX + 18, y: rect.midY + 4),
                control1: CGPoint(x: rect.midX + 8, y: rect.midY + 16),
                control2: CGPoint(x: rect.midX + 18, y: rect.midY + 14)
            )
        }

        return path
    }
}

private struct CatNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX - 7, y: rect.minY),
            control2: CGPoint(x: rect.midX + 7, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

private struct Whiskers: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - 11))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - 4))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + 9))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 2))
        return path
    }
}

private struct CorgiDrawing: View {
    let mood: MascotMood

    private var eyeScale: CGFloat {
        switch mood {
        case .completed:
            return 1.1
        case .listening:
            return 1.16
        default:
            return 1
        }
    }

    private var leftBrowRotation: Double {
        switch mood {
        case .confused:
            return -18
        default:
            return 0
        }
    }

    private var rightBrowRotation: Double {
        switch mood {
        case .confused:
            return 18
        default:
            return 0
        }
    }

    var body: some View {
        ZStack {
            RoundedTriangle(cornerRadius: 12)
                .fill(AppTheme.corgiOuterFur)
                .overlay(
                    RoundedTriangle(cornerRadius: 12)
                        .stroke(AppTheme.corgiStroke, lineWidth: 7)
                )
                .frame(width: 62, height: 76)
                .rotationEffect(.degrees(-26))
                .offset(x: -70, y: -50)

            RoundedTriangle(cornerRadius: 12)
                .fill(AppTheme.corgiOuterFur)
                .overlay(
                    RoundedTriangle(cornerRadius: 12)
                        .stroke(AppTheme.corgiStroke, lineWidth: 7)
                )
                .frame(width: 62, height: 76)
                .rotationEffect(.degrees(26))
                .offset(x: 70, y: -50)

            RoundedTriangle(cornerRadius: 8)
                .fill(AppTheme.corgiInnerEar)
                .frame(width: 28, height: 40)
                .rotationEffect(.degrees(-26))
                .offset(x: -70, y: -45)

            RoundedTriangle(cornerRadius: 8)
                .fill(AppTheme.corgiInnerEar)
                .frame(width: 28, height: 40)
                .rotationEffect(.degrees(26))
                .offset(x: 70, y: -45)

            Circle()
                .fill(AppTheme.corgiOuterFur)
                .overlay(
                    Circle()
                        .stroke(AppTheme.corgiStroke, lineWidth: 7)
                )
                .frame(width: 154, height: 154)

            CorgiBlaze()
                .fill(AppTheme.corgiWhiteFur)
                .frame(width: 92, height: 142)
                .offset(y: 11)

            HStack(spacing: 48) {
                CorgiEye(scale: eyeScale)
                CorgiEye(scale: eyeScale)
            }
            .offset(y: -20)

            HStack(spacing: 40) {
                Brow()
                    .stroke(AppTheme.corgiStroke.opacity(0.72), lineWidth: 4)
                    .frame(width: 26, height: 12)
                    .rotationEffect(.degrees(leftBrowRotation))

                Brow()
                    .stroke(AppTheme.corgiStroke.opacity(0.72), lineWidth: 4)
                    .frame(width: 26, height: 12)
                    .rotationEffect(.degrees(rightBrowRotation))
            }
            .offset(y: -48)

            RoundedRectangle(cornerRadius: 28)
                .fill(AppTheme.corgiMuzzle)
                .frame(width: 74, height: 54)
                .offset(y: 30)

            CorgiNose()
                .fill(AppTheme.corgiNose)
                .frame(width: 42, height: 30)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.72))
                        .frame(width: 9, height: 6)
                        .offset(x: -8, y: -6)
                )
                .offset(y: 17)

            CorgiMouth(mood: mood)
                .stroke(AppTheme.corgiStroke, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                .frame(width: 54, height: 26)
                .offset(y: 44)
        }
    }
}

private struct CorgiEye: View {
    let scale: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.corgiStroke)
                .frame(width: 31 * scale, height: 35 * scale)

            Circle()
                .fill(.white)
                .frame(width: 10 * scale, height: 10 * scale)
                .offset(x: -6, y: -7)
        }
    }
}

private struct CorgiMouth: Shape {
    let mood: MascotMood

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = CGPoint(x: rect.midX, y: rect.minY + 2)
        let leftEnd = CGPoint(x: rect.midX - rect.width * 0.28, y: rect.midY + 5)
        let rightEnd = CGPoint(x: rect.midX + rect.width * 0.28, y: rect.midY + 5)
        path.move(to: top)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY - 1))

        switch mood {
        case .confused:
            path.move(to: CGPoint(x: rect.midX - 16, y: rect.midY + 8))
            path.addCurve(
                to: CGPoint(x: rect.midX + 16, y: rect.midY + 8),
                control1: CGPoint(x: rect.midX - 8, y: rect.midY - 2),
                control2: CGPoint(x: rect.midX + 8, y: rect.midY + 18)
            )
        case .thinking:
            path.move(to: CGPoint(x: rect.midX - 14, y: rect.midY + 8))
            path.addLine(to: CGPoint(x: rect.midX + 14, y: rect.midY + 8))
        case .listening:
            path.addEllipse(in: CGRect(x: rect.midX - 8, y: rect.midY + 1, width: 16, height: 17))
        default:
            path.addCurve(
                to: leftEnd,
                control1: CGPoint(x: rect.midX - 8, y: rect.midY + 14),
                control2: CGPoint(x: rect.midX - 20, y: rect.midY + 14)
            )
            path.move(to: CGPoint(x: rect.midX, y: rect.midY - 1))
            path.addCurve(
                to: rightEnd,
                control1: CGPoint(x: rect.midX + 8, y: rect.midY + 14),
                control2: CGPoint(x: rect.midX + 20, y: rect.midY + 14)
            )
        }

        return path
    }
}

private struct RoundedTriangle: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CorgiBlaze: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + 12, y: rect.maxY - 8),
            control1: CGPoint(x: rect.midX - 20, y: rect.minY + 34),
            control2: CGPoint(x: rect.minX + 8, y: rect.midY + 44)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - 12, y: rect.maxY - 8),
            control1: CGPoint(x: rect.midX - 2, y: rect.maxY + 10),
            control2: CGPoint(x: rect.midX + 2, y: rect.maxY + 10)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.maxX - 8, y: rect.midY + 44),
            control2: CGPoint(x: rect.midX + 20, y: rect.minY + 34)
        )
        path.closeSubpath()
        return path
    }
}

private struct CorgiNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control1: CGPoint(x: rect.minX + 8, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - 8)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + 3),
            control2: CGPoint(x: rect.midX - 10, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX + 10, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + 3)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - 8),
            control2: CGPoint(x: rect.maxX - 8, y: rect.maxY)
        )
        path.closeSubpath()
        return path
    }
}

private struct Brow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.midX - 8, y: rect.minY),
            control2: CGPoint(x: rect.midX + 8, y: rect.minY)
        )
        return path
    }
}

private struct CandidateList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text("\(index + 1). \(item)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OrderSummaryPanel: View {
    let order: Order
    let state: KioskState

    private var title: String {
        switch state {
        case .finalConfirm:
            return "請確認訂單"
        case .completed:
            return "訂單已送出"
        default:
            return "目前訂單"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer()

                Text(statusText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            if order.lines.isEmpty {
                EmptyOrderView()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Array(order.lines.enumerated()), id: \.offset) { index, line in
                            OrderLineRow(index: index + 1, line: line)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(36)
        .background(AppTheme.rightPanel)
    }

    private var statusText: String {
        if order.isCompleted {
            return "已送出"
        }
        if order.isFinalConfirming {
            return "等待確認"
        }
        return "點餐中"
    }

    private var statusColor: Color {
        if order.isCompleted {
            return AppTheme.success
        }
        if order.isFinalConfirming {
            return AppTheme.warning
        }
        return AppTheme.accent
    }
}

private struct EmptyOrderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("還沒有餐點")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("請直接說想點的飯或湯。")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct OrderLineRow: View {
    let index: Int
    let line: OrderLine

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Text("\(index)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppTheme.accent)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(line.itemName)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    Text("x\(line.quantity)")
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundStyle(AppTheme.primaryText)
                }

                if !line.notes.isEmpty {
                    Text(line.notes.joined(separator: " / "))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PromptBar: View {
    let prompt: String
    @Binding var debugInput: String
    let mascotKind: MascotKind
    let sampleUtterances: [String]
    let onStartListening: () -> Void
    let onSubmit: () -> Void
    let onSample: (String) -> Void
    let onReset: () -> Void
    let onMascotChange: (MascotKind) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                Text(prompt)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)

                Spacer()

                Button(action: onStartListening) {
                    Label("聽", systemImage: "mic.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.promptBackground)
                .background(.white)
                .clipShape(Circle())
                .accessibilityLabel("開始聽")

                Button(action: onReset) {
                    Label("重來", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 24, weight: .bold))
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.promptBackground)
                .background(.white.opacity(0.9))
                .clipShape(Circle())
                .accessibilityLabel("全部重來")

                Menu {
                    ForEach(MascotKind.allCases) { kind in
                        Button {
                            onMascotChange(kind)
                        } label: {
                            Label(
                                kind.menuTitle,
                                systemImage: mascotKind == kind ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                } label: {
                    Label("角色", systemImage: "theatermasks.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.promptBackground)
                .background(.white.opacity(0.9))
                .clipShape(Circle())
                .accessibilityLabel("切換角色")
            }

            HStack(spacing: 12) {
                TextField("Debug 語音文字", text: $debugInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium))
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit(onSubmit)

                Button("送出") {
                    onSubmit()
                }
                .font(.system(size: 20, weight: .bold))
                .buttonStyle(.borderedProminent)

                Menu("測試句") {
                    ForEach(sampleUtterances, id: \.self) { utterance in
                        Button(utterance) {
                            onSample(utterance)
                        }
                    }
                }
                .font(.system(size: 20, weight: .bold))
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(AppTheme.promptBackground)
    }
}

private enum AppTheme {
    static let background = Color(red: 0.94, green: 0.95, blue: 0.93)
    static let leftPanel = Color(red: 0.98, green: 0.93, blue: 0.84)
    static let rightPanel = Color(red: 0.95, green: 0.97, blue: 0.99)
    static let surface = Color.white.opacity(0.86)
    static let promptBackground = Color(red: 0.10, green: 0.24, blue: 0.26)
    static let primaryText = Color(red: 0.12, green: 0.14, blue: 0.16)
    static let secondaryText = Color(red: 0.34, green: 0.39, blue: 0.42)
    static let accent = Color(red: 0.84, green: 0.30, blue: 0.18)
    static let success = Color(red: 0.09, green: 0.48, blue: 0.32)
    static let warning = Color(red: 0.76, green: 0.50, blue: 0.08)
    static let catFill = Color(red: 1.00, green: 0.72, blue: 0.25)
    static let catInnerEar = Color(red: 1.00, green: 0.62, blue: 0.56)
    static let catMuzzle = Color(red: 1.00, green: 0.88, blue: 0.66)
    static let catNose = Color(red: 0.16, green: 0.10, blue: 0.09)
    static let catStroke = Color(red: 0.16, green: 0.12, blue: 0.10)
    static let corgiOuterFur = Color(red: 0.96, green: 0.58, blue: 0.19)
    static let corgiInnerEar = Color(red: 0.97, green: 0.73, blue: 0.55)
    static let corgiWhiteFur = Color(red: 1.00, green: 0.96, blue: 0.87)
    static let corgiMuzzle = Color(red: 1.00, green: 0.91, blue: 0.76)
    static let corgiNose = Color(red: 0.07, green: 0.06, blue: 0.055)
    static let corgiStroke = Color(red: 0.16, green: 0.12, blue: 0.10)
}

#Preview("Order Kiosk", traits: .landscapeLeft) {
    OrderKioskScreen()
}
