//
//  DesignStyle.swift
//  PartyUI
//
//  Created by lunginspector on 2/12/26.
//

import SwiftUI

public enum cornerRad {
    public static let component: CGFloat = 0
    public static let platter: CGFloat = 0
    public static let sPlatter: CGFloat = 0
    public static let terminal: CGFloat = 0
}

public extension Color {
    static let rsTerminalGreen = Color(red: 0.35, green: 0.95, blue: 0.45)
}

/// Minimal terminal selection: no switch track, fill or rounded container.
/// The full row is tappable and the active state is always green.
public struct TerminalToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
            Haptic.shared.play(.light)
        } label: {
            HStack(spacing: 10) {
                Text(configuration.isOn ? "[x]" : "[ ]")
                    .fontWeight(.semibold)
                configuration.label
                Spacer(minLength: 8)
            }
            .font(.system(.body, design: .monospaced))
            .foregroundColor(configuration.isOn ? .rsTerminalGreen : .primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: configuration.isOn)
    }
}

/// Terminal replacement for segmented pickers.
public struct TerminalOptionPicker<Value: Hashable>: View {
    private let values: [Value]
    @Binding private var selection: Value
    private let title: (Value) -> String

    public init(
        values: [Value],
        selection: Binding<Value>,
        title: @escaping (Value) -> String
    ) {
        self.values = values
        self._selection = selection
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                let selected = selection == value
                Button {
                    selection = value
                    Haptic.shared.play(.light)
                } label: {
                    HStack(spacing: 10) {
                        Text(selected ? "[x]" : "[ ]")
                            .fontWeight(.semibold)
                        Text(title(value))
                        Spacer()
                    }
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(selected ? .rsTerminalGreen : .primary)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

public enum spacing {
    public static var creditCell: CGFloat {
        if #available(iOS 19.0, *) { return 14 } else { return 16 }
    }
}

public enum width {
    public static var headerIcon: CGFloat {
        if #available(iOS 19.0, *) { return 24 } else { return 22 }
    }
}

public extension EdgeInsets {
    static let sectionInsets = EdgeInsets(top: 6, leading: 15, bottom: 6, trailing: 15)
}

public extension Animation {
    static let iconUpdate = Animation.spring(response: 0.3, dampingFraction: 1.5)
}
