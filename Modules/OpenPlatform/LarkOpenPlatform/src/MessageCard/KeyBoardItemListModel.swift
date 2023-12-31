//
//  KeyBoardItemListModel.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/5.
//

import SwiftyJSON
import Kingfisher
import LKCommonsLogging

public final class AuthorizedApp: Codable & Decodable {
    static let logger = Logger.log(AuthorizedApp.self, category: "Module.AuthorizedApp")
    var appId: String
    var iconKey: String
    var imageUrl: String
    var name: String
    var description: String
    var pcH5Url: String
    var mobileH5Url: String
    var pcMpUrl: String
    var mobileMpUrl: String
    var botId: String
    var iconImg: UIImage?
    var targetUrl: String?
    var mobileAppLink: String
    private enum CodingKeys: String, CodingKey {
        case appId, iconKey, name,
        description, pcH5Url, mobileH5Url, pcMpUrl,
        mobileMpUrl, botId, mobileAppLink, imageUrl
    }

    init(json: [String: Any]) {
        appId = json["appId"] as? String ?? ""
        iconKey = json["iconKey"] as? String ?? ""
        name = json["name"] as? String ?? ""
        description = json["description"] as? String ?? ""
        pcH5Url = json["pcH5Url"] as? String ?? ""
        mobileH5Url = json["mobileH5Url"] as? String ?? ""
        pcMpUrl = json["pcMpUrl"] as? String ?? ""
        mobileMpUrl = json["mobileMpUrl"] as? String ?? ""
        botId = json["botId"] as? String ?? ""
        mobileAppLink = json["mobileAppLink"] as? String ?? ""
        imageUrl = json["imageUrl"] as? String ?? ""
    }
}
