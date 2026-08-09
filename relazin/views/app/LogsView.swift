//
//  LogsView.swift
//  lara
//
//  Created by lunginspector on 5/3/26.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var logger: Logger
    
    private let nobullshitkey = "loggernobullshit"
    let logsURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("lara.log")
    }()

    var body: some View {
        NavigationStack {
            List {
                if UserDefaults.standard.bool(forKey: nobullshitkey) {
                    let combined = logger.logs.joined(separator: "\n")
                    Text(combined)
                        .font(.system(size: 13, design: .monospaced))
                        .lineSpacing(1)
                        .onTapGesture {
                            UIPasteboard.general.string = combined
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                } else {
                    ForEach(Array(logger.logs.enumerated()), id: \.offset) { _, log in
                        Text(log)
                            .font(.system(size: 13, design: .monospaced))
                            .lineSpacing(1)
                            .onTapGesture {
                                UIPasteboard.general.string = log
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }

                if !logger.savedFailureLogs.isEmpty {
                    Section {
                        ForEach(logger.savedFailureLogs, id: \.path) { url in
                            ShareLink(item: url) {
                                HStack(spacing: 10) {
                                    Text("!")
                                        .foregroundColor(.red)
                                    Text(url.deletingPathExtension().lastPathComponent)
                                        .font(.system(size: 12, design: .monospaced))
                                        .lineLimit(2)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Saved failure logs")
                    } footer: {
                        Text("Also available in Files → On My iPhone → RSwordSvin → RSwordSvin Logs. Interrupted operations are recovered after the next launch.")
                    }
                }
            }
            .navigationTitle("Logs")
            .onAppear {
                logger.refreshSavedFailureLogs()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ShareLink(item: logsURL) {
                        Image(systemName: "square.and.arrow.up")
                    }

                    Button {
                        let allLogs = logger.logs.joined(separator: "\n\n")
                        UIPasteboard.general.string = allLogs
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    
                    Button {
                        globallogger.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}
