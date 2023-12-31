//
//  CardSchema.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/6/28.
//

import Foundation

/// 卡片schema 应用id key
private let cardSchemaAppIDKey = "app_id"
/// 卡片schema 卡片id key
private let cardSchemaCardIDKey = "card_id"
/// 卡片schema token key
private let cardSchemaTokenKey = "token"
/// 卡片schema 应用版本 key
private let cardSchemaVersionTypeKey = "version"

/// 卡片schema对象
struct CardSchema {
    var appID: String = ""
    var cardID: String = ""
    var token: String = ""
    var versionType: OPAppVersionType = .current

    init(with schema: URL) {
        BDPLogInfo(tag: .cardContainer, "card schmea:" + schema.absoluteString)
        if let urlComponents = URLComponents(url: schema, resolvingAgainstBaseURL: true),
            let queryItems = urlComponents.queryItems {
            queryItems.forEach { (item) in
                if item.name == cardSchemaAppIDKey {
                    if let appID = item.value,
                        !appID.isEmpty {
                        self.appID = appID
                    } else {
                        let msg = "Card schema appID \(item.value ?? "") is empty, plsase check func stack and contect team which use card"
                        assertionFailure(msg)
                        BDPLogError(tag: .cardContainer, msg)
                    }
                } else if item.name == cardSchemaCardIDKey {
                    if let cardID = item.value,
                        !cardID.isEmpty {
                        self.cardID = cardID
                    } else {
                        let msg = "Card schema cardID \(item.value ?? "") is empty, plsase check func stack and contect team which use card"
                        assertionFailure(msg)
                        BDPLogError(tag: .cardContainer, msg)
                    }
                } else if item.name == cardSchemaTokenKey {
                    self.token = item.value ?? ""
                } else if item.name == cardSchemaVersionTypeKey {
                    self.versionType = OPAppVersionTypeFromString(item.value)
                }
            }
        } else {
            let msg = "CardSchema obj init error, card schema has no urlComponents or queryItems"
            assertionFailure(msg)
            BDPLogError(tag: .cardContainer, msg)
        }
    }
    
    public func uniqueID() -> BDPUniqueID {
        return BDPUniqueID(appID: appID,
                           identifier: cardID,
                           versionType: versionType,
                           appType: .widget)
    }
}
