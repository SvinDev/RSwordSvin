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

public struct SquareToggleStyle: ToggleStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 12)
            Button {
                configuration.isOn.toggle()
            } label: {
                ZStack {
                    Rectangle()
                        .stroke(configuration.isOn ? Color.accentColor : Color.secondary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if configuration.isOn {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
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
