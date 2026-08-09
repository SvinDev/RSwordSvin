//
//  Logger.swift
//  mowiwewgewawt
//  bacon why would you do that
//  teehee :3
//  yeah yeah teehee all you want 
//
//  I love that you just straight skidded this from jessi lmfao
//  skidding is my specialty.
//
//  Created by roooot on 15.11.25.
//

import Foundation
import Darwin
import Combine
import SwiftUI

let globallogger = Logger()

class Logger: ObservableObject {
    @Published var logs: [String] = []
    @Published private(set) var savedFailureLogs: [URL] = []

    struct OperationToken {
        fileprivate let id: String
        fileprivate let name: String
    }

    private struct PendingOperation: Codable {
        let id: String
        let name: String
        let startedAt: Date
    }

    private var lastmessage: String?
    private var repeatCount = 0
    private var lastwasdivider = false
    private var pendingdivider = false
    private var stdoutpipe: Pipe?
    private var panding = ""
    private var ogstdout: Int32 = -1
    private var ogstderr: Int32 = -1
    private var logfileurl: URL?
    private var logfilehandle: FileHandle?
    private var logsdirurl: URL?
    private var pendingoperationsurl: URL?
    private var pendingoperations: [String: PendingOperation] = [:]
    private var automaticfailureurl: URL?
    private let filelock = NSLock()
    private let nobullshitkey = "loggernobullshit"
    private let ignoredlogsubstrings = [
        "Faulty glyph",
        "outline detected - replacing with a space/null glyph",
        "Gesture:",
        "tcp_output [",
        "com.apple.UIKit.dragInitiation",
        "OSLOG",
        "_UISystemGestureGateGestureRecognizer",
        "UITouch",
        "com.apple",
        "gestureRecognizers",
        "graph: {(",
        "UILongPressGestureRecognizer",
        "UIScrollViewPanGestureRecognizer",
        "UIScrollViewDelayedTouchesBeganGestureRecognizer",
        "_UISwipeActionPanGestureRecognizer",
        "_UISecondaryClickDriverGestureRecognizer",
        "SwiftUI.UIHostingViewDebugLayer",
        "ValueType:",
        "EventType:",
        "AttributeDataLength:",
        "AttributeData:",
        "SenderID:",
        "Timestamp:",
        "TransducerType:",
        "TransducerIndex:",
        "GenerationCount:",
        "WillUpdateMask:",
        "DidUpdateMask:",
        "Pressure:",
        "AuxiliaryPressure:",
        "TiltX:",
        "TiltY:",
        "MajorRadius:",
        "MinorRadius:",
        "Accuracy:",
        "Quality:",
        "Density:",
        "Irregularity:",
        "Range:",
        "Touch:",
        "Events:",
        "ChildEvents:",
        "DisplayIntegrated:",
        "BuiltIn:",
        "EventMask:",
        "ButtonMask:",
        "Flags:",
        "Identity:",
        "Twist:",
        "X:",
        "Y:",
        "Z:",
        "Total Latency:",
        "Timestamp type:",
        "lara[",
        "};",
        "NSLayoutConstraint",
        "   \"",
    ]

    init() {
        setuplogfile()
    }

    /// Starts a crash-safe operation. The marker is written before this method
    /// returns, so a SpringBoard crash/respring during the operation can be
    /// diagnosed on the next app launch.
    @discardableResult
    func beginOperation(_ name: String) -> OperationToken {
        let operation = PendingOperation(
            id: UUID().uuidString,
            name: name,
            startedAt: Date()
        )
        let token = OperationToken(id: operation.id, name: operation.name)

        log("> \(name)")
        filelock.lock()
        pendingoperations[operation.id] = operation
        persistpendingoperationslocked()
        filelock.unlock()
        return token
    }

    /// Completes an operation and snapshots the current log on failure.
    /// `log()` synchronizes the file before the snapshot is made.
    func finishOperation(_ token: OperationToken, success: Bool, detail: String) {
        let marker = success ? "+" : "!"
        log("\(marker) \(token.name): \(detail)")

        let failureArchived = success || archivefailure(operation: token.name, reason: detail)

        filelock.lock()
        if failureArchived {
            pendingoperations.removeValue(forKey: token.id)
        }
        persistpendingoperationslocked()
        filelock.unlock()
    }

    /// Saves an immediate failure snapshot for code paths that do not have a
    /// begin/end lifecycle of their own.
    func saveFailureLog(context: String, detail: String) {
        log("! \(context): \(detail)")
        _ = archivefailure(operation: context, reason: detail)
    }

    func refreshSavedFailureLogs() {
        guard let logsdirurl else { return }
        let urls = ((try? FileManager.default.contentsOfDirectory(
            at: logsdirurl,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("failure-") && $0.pathExtension == "log" }
            .sorted { lhs, rhs in
                let ld = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rd = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return ld > rd
            }

        DispatchQueue.main.async {
            self.savedFailureLogs = urls
        }
    }

    func log(_ message: String) {
        DispatchQueue.main.async {
            let dividersEnabled = !UserDefaults.standard.bool(forKey: self.nobullshitkey)
            if dividersEnabled && self.pendingdivider {
                self.divider()
                self.pendingdivider = false
            } else if !dividersEnabled {
                self.pendingdivider = false
                self.lastwasdivider = false
            }

            if message == self.lastmessage {
                self.repeatCount += 1
                if let lastIndex = self.logs.indices.last {
                    self.logs[lastIndex] = "\(message) (\(self.repeatCount + 1)x)"
                }
            } else {
                self.repeatCount = 0
                if dividersEnabled {
                    if self.lastwasdivider || self.logs.isEmpty {
                        self.logs.append(message)
                    } else {
                        self.logs[self.logs.count - 1] += "\n" + message
                    }
                } else {
                    self.logs.append(message)
                }
                self.lastmessage = message
            }

            self.lastwasdivider = false
        }

        appendtofile([message])
        archiveuntrackedfailureifneeded([message])
        emit(message)
    }

    func divider() {
        if UserDefaults.standard.bool(forKey: nobullshitkey) { return }
        DispatchQueue.main.async {
            self.lastwasdivider = true
            self.lastmessage = nil
            self.repeatCount = 0
        }
    }
    
    func enclosedlog(_ message: String) {
        if UserDefaults.standard.bool(forKey: nobullshitkey) {
            log(message)
            return
        }
        DispatchQueue.main.async {
            if !self.lastwasdivider && !self.logs.isEmpty {
                self.divider()
            }
            
            if self.lastwasdivider || self.logs.isEmpty {
                self.logs.append(message)
            } else {
                self.logs[self.logs.count - 1] += "\n" + message
            }
            
            self.lastwasdivider = false
            self.pendingdivider = true
        }
    }
    
    func flushdivider() {
        if UserDefaults.standard.bool(forKey: nobullshitkey) { return }
        DispatchQueue.main.async {
            if self.pendingdivider {
                self.divider()
                self.pendingdivider = false
            }
        }
    }

    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.lastwasdivider = false
            self.pendingdivider = false
            self.lastmessage = nil
            self.repeatCount = 0
        }
        filelock.lock()
        if let url = logfileurl {
            try? logfilehandle?.close()
            try? "".write(to: url, atomically: true, encoding: .utf8)
            logfilehandle = try? FileHandle(forWritingTo: url)
        }
        filelock.unlock()
    }

    func capture() {
        if stdoutpipe != nil { return }
        reopenlogfileondemand()

        let pipe = Pipe()
        stdoutpipe = pipe

        ogstdout = dup(STDOUT_FILENO)
        ogstderr = dup(STDERR_FILENO)

        setvbuf(stdout, nil, _IOLBF, 0)
        setvbuf(stderr, nil, _IOLBF, 0)

        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            guard let chunk = String(data: data, encoding: .utf8), !chunk.isEmpty else { return }
            self?.appendraw(chunk)
        }
    }

    func stopcapture() {
        guard let pipe = stdoutpipe else { return }
        pipe.fileHandleForReading.readabilityHandler = nil

        if ogstdout != -1 {
            dup2(ogstdout, STDOUT_FILENO)
            close(ogstdout)
            ogstdout = -1
        }
        if ogstderr != -1 {
            dup2(ogstderr, STDERR_FILENO)
            close(ogstderr)
            ogstderr = -1
        }

        try? pipe.fileHandleForWriting.close()
        try? pipe.fileHandleForReading.close()
        stdoutpipe = nil

        filelock.lock()
        if let handle = logfilehandle {
            try? handle.synchronize()
            try? handle.close()
            logfilehandle = nil
        }
        filelock.unlock()
    }

    private func appendraw(_ chunk: String) {
        var text = panding + chunk
        var lines = text.components(separatedBy: "\n")
        panding = lines.removeLast()
        if !lines.isEmpty {
            let filelines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let filtered = filelines.filter { !shouldignore($0) }
            DispatchQueue.main.async {
                self.logs.append(contentsOf: filtered)
            }
            appendtofile(filelines)
            archiveuntrackedfailureifneeded(filelines)
            for line in filtered {
                emit(line)
            }
        }
    }

    private func emit(_ message: String) {
        if shouldignore(message) { return }
        guard ogstdout != -1 else { return }
        let line = message + "\n"
        line.withCString { ptr in
            _ = Darwin.write(ogstdout, ptr, strlen(ptr))
        }
    }

    private func shouldignore(_ message: String) -> Bool {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return true
        }
        if isgarbageline(trimmed) {
            return true
        }
        for fragment in ignoredlogsubstrings {
            if message.contains(fragment) {
                return true
            }
        }
        return false
    }

    private func isgarbageline(_ line: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "0123456789-+|*.:(){}[]/\\_ \t")
        if line.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
            return true
        }
        if line == ")}" || line == ")}," || line == ")}))" {
            return true
        }
        return false
    }

    private func setuplogfile() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("lara.log")
        let logsdir = docs.appendingPathComponent("RSwordSvin Logs", isDirectory: true)
        let pendingurl = logsdir.appendingPathComponent("pending-operations.json")
        logfileurl = url
        logsdirurl = logsdir
        pendingoperationsurl = pendingurl

        try? FileManager.default.createDirectory(at: logsdir, withIntermediateDirectories: true)

        let interrupted = loadpendingoperations(from: pendingurl)
        pendingoperations = Dictionary(uniqueKeysWithValues: interrupted.map { ($0.id, $0) })

        if FileManager.default.fileExists(atPath: url.path) {
            let prefix = interrupted.isEmpty ? "session" : "failure-interrupted"
            let archived = uniquearchiveurl(prefix: prefix, operation: interrupted.map(\.name).joined(separator: ", "))
            do {
                try FileManager.default.moveItem(at: url, to: archived)
            } catch {
                try? FileManager.default.copyItem(at: url, to: archived)
                try? FileManager.default.removeItem(at: url)
            }
        }

        pendingoperations.removeAll()
        try? FileManager.default.removeItem(at: pendingurl)
        
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [
            FileAttributeKey.protectionKey: FileProtectionType.none
        ])
        
        logfilehandle = try? FileHandle(forWritingTo: url)
        try? logfilehandle?.seekToEnd()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let separator = "RSwordSvin started: \(formatter.string(from: Date()))"
        self.logs = [separator]
        self.lastwasdivider = true
        
        if let data = (separator + "\n").data(using: .utf8) {
            try? logfilehandle?.write(contentsOf: data)
            try? logfilehandle?.synchronize()
        }

        if !interrupted.isEmpty {
            let names = interrupted.map(\.name).joined(separator: ", ")
            let recovered = "! recovered interrupted operation(s): \(names); previous log saved in Files/RSwordSvin Logs"
            self.logs.append(recovered)
            appendtofile([recovered])
        }

        refreshSavedFailureLogs()
    }

    private func reopenlogfileondemand() {
        filelock.lock()
        defer { filelock.unlock() }
        reopenlogfileondemandlocked()
    }

    private func appendtofile(_ lines: [String]) {
        let filelines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !filelines.isEmpty else { return }
        let text = filelines.joined(separator: "\n") + "\n"
        guard let data = text.data(using: .utf8) else { return }

        filelock.lock()
        reopenlogfileondemandlocked()
        if let handle = logfilehandle {
            try? handle.write(contentsOf: data)
            // Important for exploit/tweak operations: make the last messages
            // durable before SpringBoard can terminate our process.
            try? handle.synchronize()
        }
        filelock.unlock()
    }

    private func reopenlogfileondemandlocked() {
        if logfilehandle != nil { return }
        guard let url = logfileurl else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [
                FileAttributeKey.protectionKey: FileProtectionType.none
            ])
        }
        logfilehandle = try? FileHandle(forWritingTo: url)
        try? logfilehandle?.seekToEnd()
    }

    private func persistpendingoperationslocked() {
        guard let pendingoperationsurl else { return }
        if pendingoperations.isEmpty {
            try? FileManager.default.removeItem(at: pendingoperationsurl)
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Array(pendingoperations.values)) else { return }
        try? data.write(to: pendingoperationsurl, options: .atomic)
    }

    private func loadpendingoperations(from url: URL) -> [PendingOperation] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingOperation].self, from: data)) ?? []
    }

    @discardableResult
    private func archivefailure(operation: String, reason: String) -> Bool {
        guard let logfileurl else { return false }
        let destination = uniquearchiveurl(prefix: "failure", operation: operation)

        filelock.lock()
        reopenlogfileondemandlocked()
        try? logfilehandle?.synchronize()
        var archived = false
        do {
            try FileManager.default.copyItem(at: logfileurl, to: destination)
            archived = true
            if let trailer = "\nFAILURE: \(operation)\nDETAIL: \(reason)\n".data(using: .utf8),
               let handle = try? FileHandle(forWritingTo: destination) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: trailer)
                try? handle.synchronize()
                try? handle.close()
            }
        } catch {
            // Keep the pending marker. If the app is killed, setup will retry
            // recovery from the still-present current log on the next launch.
        }
        filelock.unlock()
        if archived {
            refreshSavedFailureLogs()
        }
        return archived
    }

    private func archiveuntrackedfailureifneeded(_ messages: [String]) {
        guard let failure = messages.first(where: { isfailuremessage($0) }) else { return }
        // Explicit operation failures create a named snapshot in
        // finishOperation(). Avoid duplicate files while one is active.
        if failure.trimmingCharacters(in: .whitespaces).hasPrefix("!") { return }
        guard let logfileurl else { return }

        filelock.lock()
        guard pendingoperations.isEmpty else {
            filelock.unlock()
            return
        }

        let destination: URL
        if let automaticfailureurl {
            destination = automaticfailureurl
            try? FileManager.default.removeItem(at: destination)
        } else {
            destination = uniquearchiveurl(prefix: "failure-auto", operation: "untracked")
            automaticfailureurl = destination
        }

        reopenlogfileondemandlocked()
        try? logfilehandle?.synchronize()
        try? FileManager.default.copyItem(at: logfileurl, to: destination)
        if let trailer = "\nAUTO-DETECTED FAILURE: \(failure)\n".data(using: .utf8),
           let handle = try? FileHandle(forWritingTo: destination) {
            try? handle.seekToEnd()
            try? handle.write(contentsOf: trailer)
            try? handle.synchronize()
            try? handle.close()
        }
        filelock.unlock()
        refreshSavedFailureLogs()
    }

    private func isfailuremessage(_ message: String) -> Bool {
        let lower = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower.hasPrefix("[!]") ||
            lower.hasPrefix("failed") ||
            lower.hasPrefix("error:") ||
            lower.contains(" failed") ||
            lower.contains("failure") ||
            lower.contains("fatal error")
    }

    private func uniquearchiveurl(prefix: String, operation: String) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let timestamp = formatter.string(from: Date())
        let cleaned = operation
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let suffix = cleaned.isEmpty ? "operation" : String(cleaned.prefix(48))
        return (logsdirurl ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("\(prefix)-\(timestamp)-\(suffix).log")
    }
}
