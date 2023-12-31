//
//  SwiftTraceLogger.swift
//  SwiftTrace
//
//  Created by CharlieSu on 4/3/20.
//

import Foundation
import MachO

class TraceTask {
    init() {}
    var cancelled: Bool = false
}

enum LoggerType: String {
    case launch, foreground, manual
    var maxLogFileCount: Int { return 40 }
}

@objc(MethodTraceLoggerBridge)
public class MethodTraceLogger: NSObject {

    private var start: Bool = false
    private var log: [String] = []
    private var traceStopStasks: [TraceTask] = []
    private let queue = DispatchQueue(label: "MethodTraceLogger")
    private var type: LoggerType = .launch
    static var enable: Bool = true
    public static var shared: MethodTraceLogger?
    @objc public static var funcCost: Int = 5

    @objc
    public class func initShared() {
        MethodTraceLogger.shared = MethodTraceLogger()
    }

    @objc
    public class func log(name: UnsafePointer<Int8>, start: Double, end: Double) {
        guard Self.enable else { return }
        MethodTraceLogger.shared?.log(name: String(cString: name), start: start, end: end)
    }

    func log(name: String, start: Double, end: Double) {
        guard Self.enable else { return }

        let threadID = Thread.logInfo
        queue.async {
            guard self.start else {
                return
            }
            self.log.append("\(name) ** \(threadID) ** \(start * 1000 * 1000) ** \(end * 1000 * 1000)")
        }
    }

    /// 对外接口，从开始计时到结束
    /// - Parameter deadLine: 单位秒
    public class func startRecordAndStopForLaunch(deadLine: Int) {
        MethodTraceLogger.shared?.startRecordAndStop(type: .launch, deadline: .now() + .seconds(deadLine))
    }

    func startRecordAndStop(type: LoggerType, deadline: DispatchTime, completion: (() -> Void)? = nil) {
        guard Self.enable else { return }
        queue.async {
            if self.start, !self.log.isEmpty {
                self.stopRecordForStart()

            }
            self.start = true
            self.type = type
            self.queue.asyncAfter(deadline: deadline) {
                self.stopRecordForStart()
                completion?()
            }
        }
    }

    public func stopRecordForStart() {
        guard Self.enable else { return }

        self.start = false
        let type = self.type
        let log = self.log
        self.queue.async {
            self.writeToDocument(type: type, log: log)
        }
    }

    /// 对外接口，开始记录
    public class func startRecordFlameGraph() {
        MethodTraceLogger.shared?.startRecord()
    }

    public func startRecord() {
        queue.async {
            self.start = true
            self.type = .launch

        }
    }
    /// 对外接口，停止记录
    public class func stopRecordFlameGraph() {
        MethodTraceLogger.shared?.stopRecord()
    }

    public func stopRecord() {
        guard Self.enable else { return }
        self.start = false
        let type = self.type
        let log = self.log
        self.queue.async {
            self.writeToDocument(type: type, log: log)
        }
    }
}

fileprivate extension Thread {
    static var logInfo: String {

        if let name = current.name, !name.isEmpty {
            return name
        }

        if isMainThread {
            return "Main"
        }

        return "T:\(current.hash)"
    }
}

fileprivate extension MethodTraceLogger {
    func writeToDocument(type: LoggerType, log: [String]) {
        let fileManager = FileManager.default
        if var url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            url.appendPathComponent("sdk_storage/log/swift-trace/\(type.rawValue)")
            do {
                try fileManager.createDirectory(atPath: url.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)

                let contents = try fileManager.contentsOfDirectory(atPath: url.path)

                let sorted = contents
                    .map { (content) -> URL in
                        var tempUrl = url
                        tempUrl.appendPathComponent(content)
                        return tempUrl
                    }
                .sorted(by: { (url1, url2) -> Bool in
                    do {
                        let values1 = try url1.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                        let values2 = try url2.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                        if let date1 = values1.creationDate, let date2 = values2.creationDate {
                            return date1.compare(date2) == ComparisonResult.orderedDescending
                        }
                    } catch {

                    }
                    return true
                })
                if sorted.count >= type.maxLogFileCount {
                    try sorted[(type.maxLogFileCount - 1)..<sorted.count].forEach { try fileManager.removeItem(at: $0) }
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
                let date = formatter.string(from: Date())
                url.appendPathComponent(date)
                try log
                    .joined(separator: "\n")
                    .write(toFile: url.path, atomically: true, encoding: String.Encoding.utf8)
            } catch let error {
                print(error)
            }
        }
    }
}
