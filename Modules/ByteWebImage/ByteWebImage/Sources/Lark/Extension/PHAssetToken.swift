//
//  PHAssetToken.swift
//  ByteWebImage
//
//  Created by Saafo on 2023/10/31.
//

import LarkSensitivityControl

enum PHAssetToken {
    // 目前因为调用相关方法都和 AssetBrowser 选择后的时机强相关，有统一 UI，所以用一个 Token
    // TODO: PHAsset 相关逻辑都应该迁移到 AssetBrowser 当中，图片库不应该 import Photos
    static let getPHAssetImage = Token("LARK-PSDA-asset_browser_get_phasset_image")
}