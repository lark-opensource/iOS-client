//
//  DriveConvertFileUtils.swift
//  SpaceKit
//
//  Created by liweiye on 2019/7/29.
//

import Foundation
import SKResource
import LarkDocsIcon

public final class DriveConvertFileUtils {

    public static func convertFileTitle(fileType: String?) -> String {
        let type = DriveFileType(fileExtension: fileType)
        if type.canImportAsDocs {
            return BundleI18n.SKResource.Doc_Facade_ImportAsDoc
        } else if type.canImportAsSheet {
            return BundleI18n.SKResource.Doc_Facade_ImportAsSheet
        } else if type.canImportAsMindnote {
            return BundleI18n.SKResource.Doc_Facade_ImportAsMindnote
        } else {
            // 未知类型统一返回文档
            return BundleI18n.SKResource.Doc_Facade_ImportAsDoc
        }
    }
}
