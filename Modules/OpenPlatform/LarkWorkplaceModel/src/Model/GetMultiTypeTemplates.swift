//
//  GetMultiTypeTemplates.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/28.
//

import Foundation

/// ['lark/workplace/api/GetMultiTypeTemplates'] - request parameters
/// request parameters for getting portal list
struct WPGetPortalsRequestParams: Codable {
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let locale: String
}

/// ['lark/workplace/api/GetMultiTypeTemplates'] -  response data
/// portal list
struct WPPortalList: Codable {
    enum CodingKeys: String, CodingKey {
        case portalList = "templates"
    }

    /// portal list
    let portalList: [WPPortal]
}

/// portal
struct WPPortal: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case portalPreviewId = "tplId"
        case name
        case portalType = "tplType"
        case data
        case updateInfo
        case iconKey
    }

    /// portal type
    enum PortalType: String, Codable {
        /// native portal
        case native = "WPNormal"
        /// template portal
        case template = "LowCodeTpl"
        /// h5 portal
        case web = "H5Tpl"
    }

    /// portal identifier
    let id: String
    /// portal preview identifier
    /// if `portalPreviewId` isn't optional, use `portalPreviewId` for monitoring instead of `id`
    let portalPreviewId: String?
    /// portal name
    let name: String?
    /// portal type
    let portalType: PortalType
    /// portal type related data
    let data: JSONString<Bind2<Template, Web>>?
    /// portal update information
    let updateInfo: UpdateInfo?

    // portal icon key (unused)
    let iconKey: String?
}

extension WPPortal {
    /// template portal properties
    struct Template: Codable {
        /// a checksum to verify data integrity
        let md5: String
        /// cdn url (request template portal home data)
        let templateFileURL: String
        /// backup cdn url
        let backupTemplateURLs: [String]
        /// min supported client version
        let minClientVersion: String?

        enum CodingKeys: String, CodingKey {
            case md5
            case templateFileURL = "templateFileUrl"
            case backupTemplateURLs = "backupTemplateUrls"
            case minClientVersion
        }
    }

    /// web portal properties
    struct Web: Codable {
        /// application identifier
        let refAppId: String
        /// (unused)
        let refAppData: String?
    }

    /// portal update information
    struct UpdateInfo: Codable {
        /// portal update type
        enum UpdateType: String, Codable {
            /// pop up a dialog and let the user choose whether to update immediately
            case prompt
            /// silent update without a dialog
            case silent
            /// force update with a dialog
            case force
        }

        /// portal update type
        let updateType: UpdateType
        /// portal update dialog title
        let updateTitle: String
        /// portal update dialog detail text
        let updateRemark: String
    }
}
