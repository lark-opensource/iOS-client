//
//  LKAssetBrowserToken.swift
//  LarkAssetsBrowser
//
//  Created by Yaoguoguo on 2023/10/16.
//

import Foundation
import LarkSensitivityControl

public enum AssetBrowserToken: String {
    case savePhoto
    case saveVideo
    case requestAuthorization
    case fetchAssetCollections
    case requestImage
    case requestPlayerItem
    case requestImageData
    case requestAVAsset
    case requestExportSession
    case requestData
    case checkPhotoReadWritePermission
    case creationRequestForAsset
    case creationRequestForAssetFromImage
    case checkPhotoWritePermission

    public var token: Token {
        switch self {
        case .savePhoto:
            return Token("LARK-PSDA-AssetBrowser_savephoto")
        case .requestAuthorization:
            return Token("LARK-PSDA-AssetBrowser_requestAuthorization")
        case .fetchAssetCollections:
            return Token("LARK-PSDA-AssetBrowser_fetchAssetCollections")
        case .requestImage:
            return Token("LARK-PSDA-AssetBrowser_requestImage")
        case .requestPlayerItem:
            return Token("LARK-PSDA-AssetBrowser_requestPlayerItem")
        case .requestImageData:
            return Token("LARK-PSDA-AssetBrowser_requestImageData")
        case .requestAVAsset:
            return Token("LARK-PSDA-AssetBrowser_requestAVAsset")
        case .requestExportSession:
            return Token("LARK-PSDA-AssetBrowser_requestExportSession")
        case .requestData:
            return Token("LARK-PSDA-AssetBrowser_requestData")
        case .saveVideo:
            return Token("LARK-PSDA-AssetBrowser_saveVideo")
        case .checkPhotoReadWritePermission:
            return Token("LARK-PSDA-AssetBrowser_checkPhotoReadWritePermission")
        case .creationRequestForAsset:
            return Token("LARK-PSDA-AssetBrowser_creationRequestForAsset")
        case .checkPhotoWritePermission:
            return Token("LARK-PSDA-AssetBrowser_checkPhotoWritePermission")
        case .creationRequestForAssetFromImage:
            return Token("LARK-PSDA-AssetBrowser_creationRequestForAssetFromImage")

        }
    }
}
