//
//  TerminalTheme.swift
//  relazin
//
//  Shared pieces of the terminal look: colors, watermark background,
//  pixel logo, info rows and menu items.
//

import SwiftUI

enum terminal {
    static let bg = Color.black
    static let accent = Color(red: 1.0, green: 0.12, blue: 0.18)
    static let green = Color.rsTerminalGreen
    static let dim = Color(white: 0.55)
    static let red = accent
    static let mono: Font = .system(.body, design: .monospaced)
}

// MARK: - RSwordSvin watermark background

struct terminalwatermark: View {
    var body: some View {
        Canvas { ctx, size in
            let mark = Text("rswordsvin")
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundColor(terminal.accent.opacity(0.14))
            let resolved = ctx.resolve(mark)
            let stepX: CGFloat = 190
            let stepY: CGFloat = 46
            var row = 0
            var y: CGFloat = -20
            while y < size.height + 40 {
                // stagger every other row, like the photo
                var x: CGFloat = (row % 2 == 0) ? -30 : -105
                while x < size.width + 120 {
                    ctx.draw(resolved, at: CGPoint(x: x, y: y))
                    x += stepX
                }
                y += stepY
                row += 1
            }
        }
        .background(terminal.bg)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - RSwordSvin wordmark

struct terminallogo: View {
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 7) {
            (Text("R")
                .foregroundColor(terminal.accent)
             + Text("SWORDSVIN")
                .foregroundColor(.white))
                .font(.system(size: 45, weight: .heavy, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Rectangle()
                .fill(terminal.red)
                .frame(width: 13, height: 13)
                .offset(y: -4)
        }
        .accessibilityLabel("RSwordSvin")
    }
}

// MARK: - One info row:  "os        iOS 17.0"

struct terminalinforow: View {
    let key: String
    let value: String

    var body: some View {
        HStack(spacing: 0) {
            Text(key)
                .foregroundColor(terminal.accent)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .foregroundColor(.white)
            Spacer()
        }
        .font(.system(size: 17, design: .monospaced))
    }
}

// MARK: - Menu item (tap = action)

struct terminalmenuitem: View {
    let title: String
    var highlighted: Bool = false
    var action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Haptic.shared.play(.light)
            action()
        }) {
            HStack(spacing: 10) {
                Text(highlighted || pressed ? "▸" : " ")
                    .foregroundColor(terminal.green)
                Text(title)
                    .foregroundColor(highlighted || pressed ? terminal.green : .white)
                Spacer()
            }
            .font(.system(size: 22, weight: .medium, design: .monospaced))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
        .padding(.vertical, 6)
    }
}

// MARK: - Thin divider like on the photo

struct terminaldivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(height: 1)
    }
}
