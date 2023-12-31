//
//  WikiAssetParser.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/2/10.
//

import Foundation
import UIKit
import LarkAssetsBrowser
import LarkContainer

/// 从 AppLink 中解析有效信息
///
/// 参考文档：[支持 applink 调用图片预览功能](https://bytedance.feishu.cn/wiki/wikcniua6NTFKLTtrwXKiIKlYAd)
public enum WikiAssetParser {

    /// 从 AppLink URL 中解析参数。
    ///
    /// 有效参数：
    ///   - files: 必传，JSON 序列化的 FileItem 数组
    ///   - position: AssetBrowser 起始位置，number
    ///   - save: 是否支持保存图片，'true' | 'false'
    ///   - qrcode: 是否支持二维码识别，'true' | 'false'
    ///   - edit: 是否支持图片编辑，'true' | 'false'
    ///   - translate: 是否支持图片翻译，'true' | 'false'
    public static func getAssetBrowserParams(resolver: LarkContainer.UserResolver, from url: URL) -> WikiAssetBrowserParams? {
        guard let filesJSON = getParam(byName: "files", from: url),
              let assets = getAssets(resolver: resolver, from: filesJSON) else { return nil }
        let params = WikiAssetBrowserParams()
        params.assets = assets
        if let position = getParam(byName: "position", from: url),
           let startIndex = Int(position) {
            params.startIndex = startIndex
        }
        if let save = getParam(byName: "save", from: url),
           let canSave = Bool(save) {
            params.isSavingImageEnabled = canSave
        }
        if let qrcode = getParam(byName: "qrcode", from: url),
           let canDetectQRCode = Bool(qrcode) {
            params.isQRDetectionEnabled = canDetectQRCode
        }
        if let edit = getParam(byName: "edit", from: url),
           let canEdit = Bool(edit) {
            params.isEditingEnabled = canEdit
        }
        if let translate = getParam(byName: "translate", from: url),
           let canTranslate = Bool(translate) {
            params.isTranslatingEnabled = canTranslate
        }
        return params
    }

    /// 从 URL 中解析参数
    private static func getParam(byName name: String, from url: URL) -> String? {
        guard let components = URLComponents(string: url.absoluteString) else { return nil }
        return components.queryItems?.first(where: { $0.name == name })?.value
    }

    /// 解析 FileItem 数组
    private static func getAssets(resolver: LarkContainer.UserResolver, from files: String) -> [LKAsset]? {
        var assets: [LKAsset] = []
        guard let jsonData = files.data(using: .utf8),
              let fileItems = try? JSONDecoder().decode([WikiFileItem].self, from: jsonData)
        else { return nil }
        return fileItems.map { item in
            switch item.type {
            case .url:
                return WikiWebImageAsset(url: item.value)
            case .token:
                return WikiDriveImageAsset(resolver: resolver, token: item.value)
            case .key_id:
                return WikiAvatarImageAsset(key: item.key, entityId: item.entityId)
            }
        }
    }
}

public final class WikiAssetBrowserParams {
    public var assets: [LKAsset] = []
    public var startIndex: Int = 0
    public var isSavingImageEnabled: Bool = false
    public var isQRDetectionEnabled: Bool = false
    public var isTranslatingEnabled: Bool = false
    public var isEditingEnabled: Bool = false
}

struct WikiFileItem: Codable {

    enum FileType: String, Codable {
        case url
        case token
        case key_id
    }

    var type: FileType
    var value: String

    var key: String? {
        guard type == .key_id else { return nil }
        return value.split(separator: "&")
                    .map({ String($0) })
                    .first(where: { $0.hasPrefix("key=") })?
                    .split(separator: "=")
                    .last.map({ String($0) })
    }

    var entityId: String? {
        guard type == .key_id else { return nil }
        return value.split(separator: "&")
                    .map({ String($0) })
                    .first(where: { $0.hasPrefix("id=") })?
                    .split(separator: "=")
                    .last.map({ String($0) })
    }
}
