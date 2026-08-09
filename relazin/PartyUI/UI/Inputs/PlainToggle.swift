//
//  PlainToggle.swift
//  PartyUI
//
//  Created by lunginspector on 3/8/26.
//

import SwiftUI

public struct PlainToggle: View {
    var text: String
    var icon: String
    var infoType: ToggleInfoType
    var infoTitle: String
    var infoMessage: String
    var minSupportedVersion: Double
    var maxSupportedVersion: Double
    @Binding var isOn: Bool
    
    public init(text: String, icon: String = "", infoType: ToggleInfoType = .none, infoTitle: String = "Information", infoMessage: String = "", minSupportedVersion: Double = 0.0, maxSupportedVersion: Double = 100.0, isOn: Binding<Bool>) {
        self.text = text
        self.icon = icon
        self.infoType = infoType
        self.infoTitle = infoTitle
        self.infoMessage = infoMessage
        self._isOn = isOn
        self.minSupportedVersion = minSupportedVersion
        self.maxSupportedVersion = maxSupportedVersion
    }
    
    public var body: some View {
        if doubleSystemVersion() >= minSupportedVersion && doubleSystemVersion() <= maxSupportedVersion {
            HStack(spacing: 8) {
                Toggle(isOn: $isOn) {
                    Text(text)
                }

                if infoType == .info || infoType == .warning {
                    Button(action: {
                        Alertinator.shared.alert(title: infoTitle, body: infoMessage)
                    }) {
                        Text(infoType == .info ? "[i]" : "[!]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(infoType == .warning ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
