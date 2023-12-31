//
//  ClippingResourceTool.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/5.
//  


import Foundation
import SKFoundation
import SKResource
import LibArchiveKit


class ClippingResourceTool: ClippingFileProtocol {

    enum InternalError: Error {
        case createDirectoryFail
        case pathNotFound
        case extractFail
        case unexpected
        case loadData
    }
    
    private let resource = ClippingDocResource()
    
    let basePath: SKFilePath
    
    private let destZipPath: SKFilePath
    
    typealias Result = Swift.Result<String, ClippingResourceTool.InternalError>

    private lazy var clippingQueue = DispatchQueue(label: "sk.clipping.doc.queue")
    
    var traceId: String?
    
    init(traceId: String? = nil) throws {
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/clipping/zip")
        self.traceId = traceId
        self.basePath = path
        self.destZipPath = path.appendingRelativePath(resource.version)
    }

    private func extract(zipFilePath: String, to targetPath: SKFilePath, result: @escaping ((Result) -> Void) ) {
        clippingQueue.async {
            let res = self.extractFile(zipFilePath: zipFilePath, to: targetPath)
            DispatchQueue.main.async {
                result(res)
            }
        }
    }
    
    private func extractFile(zipFilePath: String, to targetPath: SKFilePath) -> Result {
        guard createDirectoryIfNeed(targetPath) else {
            return .failure(.createDirectoryFail)
        }
        do {
            let file = try LibArchiveFile(path: zipFilePath)
            try file.extract7z(toDir: URL(fileURLWithPath: targetPath.pathString))
            let list = targetPath.fileListInDirectory() ?? []
            if let path = list.last {
                DocsLogger.info("extract success!", component: LogComponents.clippingDoc, traceId: traceId)
                return .success(path)
            } else {
                DocsLogger.error("extract fail ❌", component: LogComponents.clippingDoc, traceId: traceId)
                return .failure(.extractFail)
            }
        } catch {
            DocsLogger.error("extract error:\(error)", component: LogComponents.clippingDoc, traceId: traceId)
            return .failure(.unexpected)
        }
    }
    
    private func loadData(file: String, callback: @escaping ((String?, InternalError?) -> Void)) {
        do {
            var path = SKFilePath(absPath: file)
            if !file.hasPrefix(destZipPath.pathString) {
                path = destZipPath.appendingRelativePath(file)
            }
            let data = try Data.read(from: path)
            guard let str = String(data: data, encoding: .utf8) else {
                DocsLogger.error("convert data to str error", component: LogComponents.clippingDoc, traceId: traceId)
                callback(nil, .loadData)
                return
            }
            callback(str, nil)
        } catch {
            DocsLogger.error("fetch resource error:\(error)", component: LogComponents.clippingDoc, traceId: traceId)
            callback(nil, .loadData)
        }
    }
    
}

extension ClippingResourceTool {
    
    /// 删除本机存在的旧js资源
    func clearOldResource() {
        guard let subPaths = try? basePath.contentsOfDirectory() else {
            DocsLogger.info("subPaths is empty", component: LogComponents.clippingDoc, traceId: traceId)
            return
        }
        for sub in subPaths where sub != resource.version {
            let fullPath = basePath.appendingRelativePath(sub)
            do {
               try fullPath.removeItem()
               DocsLogger.info("remove oldFile at path:\(fullPath)", component: LogComponents.clippingDoc, traceId: traceId)
            } catch {
                DocsLogger.error("remove oldFile error:\(fullPath)", component: LogComponents.clippingDoc, traceId: traceId)
            }
        }
    }
    
    var jsExtractedFile: String? {
        let list = destZipPath.fileListInDirectory() ?? []
        var jsFilePath: String?
        for path in list where path.hasSuffix(".js") {
            jsFilePath = path
            break
        }
        return jsFilePath
    }
    
    /// 加压7z文件并提取js内容
    func fetchJSResource(_ callback: @escaping ((String?, InternalError?) -> Void)) {
        if let jsFilePath = jsExtractedFile { // 已经解压缩
            DocsLogger.info("file had extracted:\(jsFilePath)", component: LogComponents.clippingDoc, traceId: traceId)
            loadData(file: jsFilePath, callback: callback)
        } else { // 未解压缩
            guard !resource.zipPath.isEmpty else {
                DocsLogger.error("zipPath is empty", component: LogComponents.clippingDoc, traceId: traceId)
                callback(nil, .pathNotFound)
                return
            }
            DocsLogger.info("extract file from:\(resource.zipPath) to:\(destZipPath)", component: LogComponents.clippingDoc, traceId: traceId)
            extract(zipFilePath: resource.zipPath, to: destZipPath) { [weak self] result in
                switch result {
                case .success(let path):
                    self?.loadData(file: path, callback: callback)
                case . failure(let error):
                    callback(nil, error)
                }
            }
        }
    }
}
