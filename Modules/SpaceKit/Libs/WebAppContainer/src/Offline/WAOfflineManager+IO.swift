//
//  WAOfflineManager+IO.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/21.
//

import SKFoundation

extension WAOfflineManager {
    
    @discardableResult
    func removeFiles(at path: SKFilePath?, logTag: String) -> Bool {
        guard let folderPath = path, !folderPath.pathString.isEmpty else {
            Self.logger.info("\'\(logTag)\' path is empty, no need delete", tag: LogTag.offline.rawValue)
            return true
        }
        guard folderPath.exists else {
            Self.logger.info("\'\(logTag)\' path isnot exist，path:\(folderPath)", tag: LogTag.offline.rawValue)
            return true
        }
        do {
            try folderPath.removeItem()
        } catch let error {
            Self.logger.error("del \'\(logTag)\' path faield, path:\(folderPath)", tag: LogTag.offline.rawValue, error: error)
            return false
        }
        Self.logger.info("del \'\(logTag)\' path ok, path: \(folderPath)", tag: LogTag.offline.rawValue)
        return true
    }
    
    class func bundle(from bundleName: String) -> Bundle? {
        if let url = Bundle.main.url(forResource: bundleName, withExtension: nil) {
            return Bundle(url: url)
        } else {
            spaceAssertionFailure("find no bundle :\(bundleName)")
            return nil
        }
    }
    
    class func revision(in folder: SKFilePath) -> String? {
        guard let revision = getCurRevisionFileContent(in: folder) else {
            return nil
        }
        return DocsStringUtil.getValue(from: revision, of: "version")
    }

    class func getCurRevisionFileContent(in folder: SKFilePath) -> String? {
        guard folder.exists else {
            WAOfflineManager.logger.error("\(folder.pathString) unexists", tag: LogTag.offline.rawValue)
            return nil
        }
        var revision: String?
        let filePath = folder.appendingRelativePath("\(Self.revisionFile)")
        do {
            revision = try String.read(from: filePath)
        } catch {
            WAOfflineManager.logger.error("can't read content from: \(filePath.pathString)", tag: LogTag.offline.rawValue)
        }
       return revision
    }
}
