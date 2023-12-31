//
//  FileToken.swift
//  LarkFile
//
//  Created by Yaoguoguo on 2023/10/25.
//

import Foundation
import LarkSensitivityControl

enum FileToken: String {
    case savePhoto
    case saveVideo
    case requestImage
    case requestPlayerItem
    case fetchAssets
    case requestAuthorization
    case requestExportSession

    var token: Token {
        switch self {
        case .savePhoto:
            return Token("LARK-PSDA-File_savephoto")
        case .saveVideo:
            return Token("LARK-PSDA-File_saveVideo")
        case .requestImage:
            return Token("LARK-PSDA-File_requestImage")
        case .requestPlayerItem:
            return Token("LARK-PSDA-File_requestPlayerItem")
        case .fetchAssets:
            return Token("LARK-PSDA-File_fetchAssets")
        case .requestAuthorization:
            return Token("LARK-PSDA-File_requestAuthorization")
        case .requestExportSession:
            return Token("LARK-PSDA-File_requestExportSession")
        }
    }
}
