//
//  BannerModel.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/26.
//

import Foundation
import ServerPB
import ECOProbe
import LKCommonsLogging

struct BannerContainer: CustomStringConvertible {
    let timestamp: Int64
    let resourceList: [BannerResource]
    
    static func parse(from: ServerPB_Open_banner_OpenBannerResponse.Container) throws -> BannerContainer {
        let resource_list = from.resourceList.compactMap { (resource) -> BannerResource? in
            do {
                return try BannerResource.parse(from: resource)
            } catch {
                // 局部降级，不破坏整个 Bar
                openBannerLogger.error("invalid BannerResource.", tag: "BannerResource", additionalData: nil, error: error)
            }
            return nil
        }
        return BannerContainer(
            timestamp: from.timestamp,
            resourceList: resource_list
        )
    }
    
    var description: String {
        return "{timestamp:\(timestamp), resourceList:\(resourceList)}"
    }
}

// 为什么要转换一遍：PB 对象无 Optional 能力，直接在业务代码中使用不安全，这里做一次格式清洗再给业务使用
struct BannerResponse: CustomStringConvertible {
    let targetID: String
    let targetType: ServerPB_Open_banner_TargetType
    let containerTag: ServerPB_Open_banner_ContainerTag?
    let context: String?
    let container: BannerContainer?
    let code: Int32
    let tipsI18N: [String: String]?
    let contextDic: [String: Any]?
    let resourceVersion: String?
    
    static func parse(from: ServerPB_Open_banner_OpenBannerResponse) throws -> BannerResponse {
        return BannerResponse(
            targetID: from.targetID,
            targetType: from.targetType,
            containerTag: from.hasContainerTag ? from.containerTag : nil,
            context: from.hasContext ? from.context : nil,
            container: from.hasContainer ? try BannerContainer.parse(from: from.container) : nil,
            code: from.code,
            tipsI18N: !from.tipsI18N.isEmpty ? from.tipsI18N : nil,
            contextDic: stringValueDic(from.context),
            resourceVersion: from.hasContainer ? from.container.resourceVersion : nil
        )
    }
    
    var description: String {
        return "{targetID:\(targetID), targetType:\(targetType.rawValue), containerTag:\(containerTag?.rawValue), code:\(code), container:\(container?.description ?? "")}"
    }
    
    static func stringValueDic(_ str: String) -> [String : Any]? {
        let data = str.data(using: String.Encoding.utf8)
        if let dict = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] {
            return dict
        }
        return nil
    }
}

struct BannerResource: CustomStringConvertible {
    
    let resourceID: String
    let resourceType: String
    let resourceView: BannerResourceView
    
    static func parse(from: ServerPB_Open_banner_OpenBannerResponse.Container.Resource) throws -> BannerResource {
        switch from.viewType {
        case .bannerResource:
            let resourceView = try BannerResourceView.parse(from: from.viewData)
            return BannerResource(
                resourceID: from.resourceID,
                resourceType: from.resourceType,
                resourceView: resourceView
            )
        @unknown default:
            throw HelpDeskError(.unsupportedViewType, message: "viewType:\(from.viewType.rawValue)")
        }
    }
    
    var description: String {
        return "{resourceID:\(resourceID), resourceType:\(resourceType), resourceView:\(resourceView)}"
    }
}

struct BannerResourceView: Decodable, CustomStringConvertible {
    let image_key_themed: ThemedImageKey?
    let image_url_themed: ThemedImageKey?
    let text_i18n: [String: String]
    let action: BannerResourceAction?
    let confirm: BannerResourceConfirm?
    
    func isValidView() -> Bool {
        if let confirm = confirm {
            return confirm.confirm_action.isValidAction()
        }
        return action?.isValidAction() == true
    }
    
    static func parse(from jsonString: String) throws -> BannerResourceView {
        guard let data = jsonString.data(using: .utf8) else {
            throw HelpDeskError(.stringToDataError, message: "string:\(safeLogValue(jsonString))")
        }
        return try JSONDecoder().decode(BannerResourceView.self, from: data)
    }
    
    var description: String {
        return "{image_url_themed:\(image_url_themed), image_key_themed:\(image_key_themed), text_i18n:\(text_i18n), action:\(action), confirm:\(confirm)}"
    }
}

struct BannerResourceConfirm: Decodable, CustomStringConvertible {
    let title_i18n: [String: String]?
    let content_i18n: [String: String]?
    let confirm_text_i18n: [String: String]?
    let confirm_action: BannerResourceAction
    let cancel_text_i18n: [String: String]?
    let cancel_action: BannerResourceAction?
    
    var description: String {
        return "{title_i18n:\(title_i18n), content_i18n:\(content_i18n), confirm_text_i18n:\(confirm_text_i18n), confirm_action:\(confirm_action), cancel_text_i18n:\(cancel_text_i18n), cancel_action:\(cancel_action)}"
    }
}

struct BannerResourceAction: Decodable, CustomStringConvertible {
    let value: String?
    let multi_url: [String: String]?
    
    func isValidAction() -> Bool {
        return value != nil || getLinkUrl() != nil
    }
    
    func getLinkUrl() -> URL? {
        guard let multi_url = multi_url,
              let url = multi_url["ios_url"] ?? multi_url["url"]
        else {
            return nil
        }
        return URL(string: url)
    }
    
    var description: String {
        // 脱敏信息
        return "{value:\(safeLogValue(value)), multi_url.count:\(multi_url?.count)}"
    }
}

struct ThemedImageKey: Decodable, CustomStringConvertible {
    let light: String?
    let dark: String?
    
    func isValid() -> Bool {
        guard let light = light, !light.isEmpty else {
            return false
        }
        return true
    }
    
    var description: String {
        return "{light:\(light), dark:\(dark)}"
    }
}
