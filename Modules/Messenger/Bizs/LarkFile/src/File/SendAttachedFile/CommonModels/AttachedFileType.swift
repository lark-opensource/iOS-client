//
//  AttachedFileType.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import Foundation
import LarkMessengerInterface

extension AttachedFileType {

    var displayName: String {
        switch self {
        case .albumVideo:
            return BundleI18n.LarkFile.Lark_Legacy_SendAttachedFileTypeAlbumVideo
        case .localVideo:
            return BundleI18n.LarkFile.Lark_Legacy_SendAttachedFileTypeLocalVideo
        case .PDF:
            return "PDF"
        case .EXCEL:
            return "EXCEL"
        case .WORD:
            return "WORD"
        case .PPT:
            return "PPT"
        case .TXT:
            return "TXT"
        case .MD:
            return "MD"
        case .JSON:
            return "JSON"
        case .HTML:
            return "HTML"
        case .unkown:
            return BundleI18n.LarkFile.Lark_Legacy_FileTypeReceive
        }
    }
}
