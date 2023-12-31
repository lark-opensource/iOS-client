//
//  OPPathTransformHelper.swift
//  EEMicroAppSDK
//
//  Created by zhujingcheng on 5/17/23.
//

import Foundation
import OPFoundation

public final class OPPathTransformHelper: NSObject {
    @objc public static func buildURL(path: String?, uniqueID: OPAppUniqueID, tag: String) -> URL? {
        guard let path = path, !path.isEmpty else {
            return nil
        }
        
        do {
            let fileObj = try FileObject(rawValue: path)
            let fsContext = FileSystem.Context(uniqueId: uniqueID, trace: nil, tag: tag, isAuxiliary: true)
            let filePath = try FileSystemCompatible.getSystemFile(from: fileObj, context: fsContext)
            return URL(fileURLWithPath: filePath)
        } catch {
            return URL(string: path)
        }
    }
}
