//
//  ImportToOnlineFile.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/7/26.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SKResource
import SKFoundation
import SpaceInterface
import SKInfra
import LarkDocsIcon

// MARK: - 判断是否显示转在线文档的按钮
class ImportToOnlineFile {

    /// 暂时留着用
    class func getImportInfo(fileType: DocsType, fileSubtype: String?) -> (canImport: Bool, tip: String) {
        if !DocsNetStateMonitor.shared.isReachable { return (false, "") }
        let driveFileType = DriveFileType(fileExtension: fileSubtype)
        //        let driveFileType = DriveFileType(fileExtension: file.fileType)
        if fileType != .file || driveFileType == .unknown {
            return (false, "")
        }
        var canImport = true
        var tip = ""
        if driveFileType.canImportAsDocs {
            tip = BundleI18n.SKResource.Doc_Facade_ImportAsDoc
        } else if driveFileType.canImportAsSheet {
            tip = BundleI18n.SKResource.Doc_Facade_ImportAsSheet
        } else if driveFileType.canImportAsMindnote {
            tip = BundleI18n.SKResource.Doc_Facade_ImportAsMindnote
        } else {
            canImport = false
        }

        return (canImport, tip)
    }

//    class func insertImportToOnlineFileAction(actions: [SlideAction], action: SlideAction) -> [SlideAction] {
//        var newActions = actions
//        let beforeActions: [SlideAction] = [.addToPin, .removeFromPin, .star, .unstar]
//        var targetIndex = 0
//        for (index, action) in actions.enumerated() {
//            if !beforeActions.contains(action) {
//                targetIndex = index
//                break
//            }
//        }
//        newActions.insert(action, at: targetIndex)
//        return newActions
//    }
    
//    class func requestFileImportPermission(_ file: SpaceEntry, completion: @escaping (Bool, String?) -> Void) {
//        DocsContainer.shared.resolve(DriveConvertFileConfigBase.self)?.type().parseFileEnabled(fileToken: file.objToken) { (result) in
//            switch result {
//            case .success:
//                completion(true, nil)
//            case .failure(let error):
//                guard let error = error as? ConvertFileError else { return }
//                return completion(false, error.errorMessage)
//            }
//        }
//    }

    static var featureEnabled: Bool {
        DocsContainer.shared.resolve(DriveConvertFileConfigBase.self)?.type().featureEnabled ?? false
    }

    static var importSizeLimit: Int64 {
        DocsContainer.shared.resolve(DriveConvertFileConfigBase.self)?.type().importSizeLimit ?? 0
    }
}
