//
//  WAOfflineManager+DataSession.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/22.
//

import Foundation
import SKFoundation

extension WAOfflineManager: WADataSessionDelegate {
    
    public func readData(for relativeFilePath: String) -> Data? {
        let fullPath = getTargetFileFullPath(for: relativeFilePath)
        if fullPath.exists {
            if let data = try? Data.read(from: fullPath) {
                Self.logger.info("intercept, read cache ok，\(relativeFilePath)", tag: LogTag.offline.rawValue)
                return data
            } else {
                Self.logger.info("intercept,read cache failed，\(relativeFilePath)", tag: LogTag.offline.rawValue)
            }
        } else {
            Self.logger.info("intercept,cache unexist，\(relativeFilePath)", tag: LogTag.offline.rawValue)
        }
        return nil
    }
}
