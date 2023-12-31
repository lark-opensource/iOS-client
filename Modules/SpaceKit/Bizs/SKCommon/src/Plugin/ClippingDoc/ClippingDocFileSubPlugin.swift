//
//  ClippingDocFileService.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/30.
//  


import UIKit
import SKFoundation
import SwiftyJSON

protocol ClippingFileProtocol {
    func createDirectoryIfNeed(_ directoryPath: SKFilePath) -> Bool
}

extension ClippingFileProtocol {
    func createDirectoryIfNeed(_ directoryPath: SKFilePath) -> Bool {
        guard directoryPath.exists else {
            do {
                try directoryPath.createDirectory(withIntermediateDirectories: true)
                DocsLogger.info("create directory:\(directoryPath) success", component: LogComponents.clippingDoc)
                return true
            } catch {
                DocsLogger.error("create directory error:\(error)", component: LogComponents.clippingDoc)
                return false
            }
        }
        return true
    }
}

class ClippingDocFileSubPlugin: ClippingFileProtocol {

    class FileRecord {

        weak var tracker: ClippingDocReport?
        
        private let totalPart: Int
        
        init(totalPart: Int) {
            self.totalPart = totalPart
        }
        
        private var timeRecord: [Int: Double] = [:]
        
        func record(partId: Int, time: Double, filePath: SKFilePath) {
            timeRecord[partId] = time
            let fileSize = filePath.fileSize ?? 0
            if partId == totalPart - 1,
            let totalTime = getTotalTime() {
                tracker?.record(stage: .writeFile(fileSize: Int(fileSize)), cost: totalTime)
            }
        }
        
        func getTotalTime() -> Double? {
            var time: TimeInterval = 0
            for i in 0..<totalPart {
                if let t = timeRecord[i] {
                    time += t
                } else {
                    return nil
                }
            }
            return time
        }
    }
    
    enum InternalError: Error {
        case pathNotFound
    }

    var fileRecord: FileRecord?
    
    private lazy var clippingQueue = DispatchQueue(label: "sk.clipping.doc.queue")
    
    weak var tracker: ClippingDocReport?
    
    private func createClippingFileIfNeeded(_ filePath: SKFilePath) {
        guard createDirectoryIfNeed(basePath) else {
            return
        }

        if !filePath.exists {
            do {
                let isSuccess = filePath.createFile(with: nil)
                DocsLogger.debug("create file:\(filePath) success:\(isSuccess)", component: LogComponents.clippingDoc)
            } catch {
                DocsLogger.error("create file error:\(error)", component: LogComponents.clippingDoc)
            }
        } else {
            DocsLogger.debug("file:\(filePath) Exists", component: LogComponents.clippingDoc)
        }
    }

    private(set) var filePath: SKFilePath
    
    let secretKey: String
    
    private let basePath: SKFilePath
    
    init(secretKey: String) throws {
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/clipping/html")
        self.secretKey = secretKey
        self.basePath = path
        self.filePath = path.appendingRelativePath(secretKey)
    }
    
    func saveFile(params: [String: Any], result: @escaping ((Bool) -> Void)) {
        let json = JSON(params)
        let fileName = json["fileName"].stringValue
        let content = json["content"].stringValue
        let partId = json["partId"].intValue
        let totalPart = json["totalPart"].intValue
        DocsLogger.info("handle save file partId:\(partId) totalPart:\(totalPart)", component: LogComponents.clippingDoc)
        // 首次保存前清空，防止重复append
        if partId == 0 {
            fileRecord = FileRecord(totalPart: totalPart)
            fileRecord?.tracker = tracker
            self.clearCurrentFile()
        }
        self.createClippingFileIfNeeded(filePath)
        clippingQueue.async(flags: .barrier) {
            let measure = ClipTimeMeasure()
            guard let data = content.data(using: .utf8) else {
                DocsLogger.error("convert data error", component: LogComponents.clippingDoc)
                result(false)
                return
            }
            guard let fileHandle = try? FileHandle.getHandle(forWritingAtPath: self.filePath) else {
                result(false)
                DocsLogger.error("create fileHandle fail", component: LogComponents.clippingDoc)
                return
            }
            if #available(iOS 13.4, *) {
                do {
                    try fileHandle.seekToEnd()
                    fileHandle.write(data)
                } catch {
                    DocsLogger.error("seekToEnd error:\(error)", component: LogComponents.clippingDoc)
                    result(false)
                    return
                }
            } else {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
            }
            let t = measure.end()
            self.fileRecord?.record(partId: partId, time: t, filePath: self.filePath)
            result(true)
            DocsLogger.debug("saveFile to \(self.filePath)", component: LogComponents.clippingDoc)
        }
        
    }
    
    static func clearAllFile() {

        let basePath = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/clipping/html")
        guard let subPaths = try? basePath.contentsOfDirectory() else {
            DocsLogger.info("subPaths is empty", component: LogComponents.clippingDoc)
            return
        }
        for sub in subPaths {
            let fullPath = basePath.appendingRelativePath(sub)
            do {
                try fullPath.removeItem()
                DocsLogger.info("remove file at path:\(fullPath)", component: LogComponents.clippingDoc)
            } catch {
                DocsLogger.error("remove file at error:\(error)", component: LogComponents.clippingDoc)
            }
        }
    }
    
    func clearCurrentFile() {
        clear(path: filePath)
    }
    
    private func clear(path: SKFilePath) {
        guard path.exists else {
            return
        }
        do {
           try path.removeItem()
           DocsLogger.info("remove file at path:\(path)", component: LogComponents.clippingDoc)
        } catch {
            DocsLogger.error("remove file at error:\(error)", component: LogComponents.clippingDoc)
        }
    }
    
    func getFileData(result: @escaping ((Data) -> Void)) {
        clippingQueue.async {
            do {
                let measure = ClipTimeMeasure()
                let data = try Data.read(from: self.filePath)
                let fileSize = data.count / 1024
                self.tracker?.record(stage: .readFile(fileSize: fileSize), cost: measure.end())
                result(data)
            } catch {
                DocsLogger.error("get file data error:\(error)", component: LogComponents.clippingDoc)
            }
        }
    }
    
    deinit {
        clearCurrentFile()
    }
}
