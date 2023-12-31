//
//  WPDialogModel.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/19.
//

import Foundation
import SwiftyJSON
import LarkSetting
import LKCommonsLogging

struct OperationDialogData: Codable {
    /// 客户端兼容版本
    static let kClientAcceptSchemaVer = "1.0.0"

    let schemaVersion: String
    let notification: OperationNotification
}

struct OperationNotification: Codable {
    let id: String
    let content: OperationNotificationContent

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        // 解析 "id"
        self.id = try values.decode(String.self, forKey: .id)

        // 解析 "content", 服务端数据类型为 JSON String，这里自定义解析为 OperationNotificationContent
        let contentStr = try values.decode(String.self, forKey: .content)
        let jsonData = try JSON(parseJSON: contentStr).rawData()
        self.content = try JSONDecoder().decode(OperationNotificationContent.self, from: jsonData)
    }
}

struct OperationNotificationContent: Codable {
    private static let kDefaultI18nKey = "default"

    struct Config: Codable {
        let width: CGFloat
        let height: CGFloat
    }
    let config: Config

    // 服务器字段为 "i18n_elements"，这里解析出国际化后的 element: i18n_elements[Locale]
    let parseElement: OperationNotificationElement

    enum CodingKeys: String, CodingKey {
        case config
        case parseElement = "i18n_elements"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.config = try values.decode(Config.self, forKey: .config)

        let json = try values.decode(JSON.self, forKey: .parseElement)
        let locale = WorkplaceTool.curLanguage()
        let jsonData: Data
        if json[locale].exists() {
            jsonData = try json[locale].rawData()
        } else if json[OperationNotificationContent.kDefaultI18nKey].exists() {
            jsonData = try json[OperationNotificationContent.kDefaultI18nKey].rawData()
        } else {
            let err = NSError(
                domain: "com.feishu.workplace",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "\(locale) i18n not exists"]
            )
            throw WPDialogError.jsonDecode(error: err)
        }

        let elements = try JSONDecoder().decode([OperationNotificationElement].self, from: jsonData)
        guard let element = elements.first else {
            let err = NSError(
                domain: "com.feishu.workplace",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "\(locale) i18n elements empty"]
            )
            throw WPDialogError.jsonDecode(error: err)
        }
        parseElement = element
    }
}

struct OperationNotificationElement: Codable {
    static let logger = Logger.log(OperationNotificationElement.self)

    enum Tag: String, Codable {
        case img
        case med
    }
    // swiftlint:disable identifier_name
    let tag: Tag
    let img_key: String?
    let file_key: String?
    let url: String?
    // swiftlint:enable identifier_name
    /// 根据 img_key 拼接图片 URL
    var imageUrl: String? {
        guard let key = img_key else {
            return nil
        }
        return fileURLString(for: key)
    }

    /// 根据 file_key 拼接视频 URL
    var videoUrl: String? {
        guard let key = file_key else {
            return nil
        }
        return fileURLString(for: key)
    }

    private func fileURLString(for key: String) -> String {
        let domain = DomainSettingManager.shared.currentSetting[.docsDrive]?.first ?? ""
        Self.logger.info("[dialog] file domain: \(domain), key: \(key)")
        return "https://\(domain)/space/api/box/stream/download/all/\(key)"
    }
}
