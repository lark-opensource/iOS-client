//
//  TemplateTab.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/7/12.
//  

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SKUIKit
import SpaceInterface
import SKInfra

/*
public class TemplateTab {
    struct Category {
        let name: String
        let items: [Template]
    }
    var name: String?
    lazy var templateList: [Template] = []
    lazy var categoryNames: [String] = []
    lazy var categories: [Category] = []

    public class func parseTemplatesJsonArray(templateDics: [JSON]?) -> [Template] {
        var templateList = [Template]()
        guard let templateDics = templateDics else {
            return templateList
        }

        templateDics.forEach({ (dict) in
            let template: Template = {
                // source == 2 为自定义/共享模版
                // source == 1 为产品定义模版
                if let source = dict["source"].int, source == 2 {
                    return Template.custom(with: dict)
                } else {
                    return Template.category(with: dict)
                }
            }()

            let enableCache = DocsContainer.shared.resolve(SKCreateEnableTypesCache.self)
            if enableCache?.createEnableTypes.contains(template.objType) ?? false {
                templateList.append(template)
            }
        })

        return templateList
    }
}
 */

public final class Template {

    public var objType: DocsType
    public var objToken: String?
    public var name: String?
    public var coverUrl: String?
    var coverToken: String?
    var coverWidth: Int = 0
    var coverHeight: Int = 0
    var isInAllList: Bool = false
    public var barColor: String?
    public var isCustom = false
    public var isBlank = false

    public var secretKey: String?
    public var secretCoverUrl: String?

    /// 请使用 `static func category(with dict: JSON) -> Template`
    private init(with dict: JSON) {
        if let value = dict["obj_type"].int {
            objType = DocsType(rawValue: value)
        } else {
            objType = .unknownDefaultType
        }
        objToken = dict["obj_token"].string
        name = dict["name"].string
        coverToken = dict["cover_token"].string
        coverWidth = dict["cover_width"].intValue
        coverHeight = dict["cover_height"].intValue
        let renderConfig = dict["render_config"]
        if renderConfig["show_top_border"].boolValue {
            barColor = renderConfig["top_border_color"].string
        }
        if let coverToken = coverToken {
            let context = NetConfig.shared.sessionFor(.default, trafficType: .default)
            let host = context.host
            coverUrl = host + OpenAPI.APIPath.driveOriginalFileDownload + coverToken
        }
    }

    private init(with type: DocsType) {
        self.objType = type
    }

//    static func newTemplate(with type: DocsType) -> Template {
//        let temp = Template(with: type)
//        temp.name = BundleI18n.SKResource.Doc_List_Blank
//        temp.isBlank = true
//        return temp
//    }

    /// 产品设置的模版
    public static func category(with dict: JSON) -> Template {
        let template = Template(with: dict)
        return template
    }
    /// 自定义模版
    static func custom(with dict: JSON) -> Template {
        let template = Template(with: dict)
        template.isCustom = true
        template._getCoverConfig()
        return template
    }

    private func _getCoverConfig() {
        if !_getCoverConfigFromUserDefault() {
            _getCoverConfigFromNetwork()
        }
    }

    private func _saveCoverConfig() {
        let key = "com.bytedance.docs.template-\(objType.rawValue)-\(objToken ?? "")"
        CCMKeyValue.globalUserDefault.setDictionary(["secretKey": secretKey, "secretCoverUrl": secretCoverUrl], forKey: key)
    }

    private func _getCoverConfigFromUserDefault() -> Bool {
        let key = "com.bytedance.docs.template-\(objType.rawValue)-\(objToken ?? "")"
        if let dict = CCMKeyValue.globalUserDefault.dictionary(forKey: key),
            let secretKey = dict["secretKey"] as? String,
            let secretCoverUrl = dict["secretCoverUrl"] as? String {
            self.secretKey = secretKey
            self.secretCoverUrl = secretCoverUrl
            return true
        } else {
            return false
        }
    }

    private func _getCoverConfigFromNetwork() {
        guard let token = objToken else {
            return
        }
        let req = DocsRequest<JSON>(path: OpenAPI.APIPath.getThumbnailURL, params: ["obj_type": objType.rawValue,
                                                                                    "obj_token": token]).set(method: .GET)
        req.start { [weak self] (res, err) in
            guard err == nil else {
                return
            }
            guard let decryptKey = res?["data"]["decrypt_key"].string,
                let url = res?["data"]["url"].string else {
                    return
            }
            self?.secretKey = decryptKey
            self?.secretCoverUrl = url
            self?._saveCoverConfig()
        }
        req.makeSelfReferenced()
    }

    public var isVertical: Bool {
        return !(objType == .sheet || objType == .bitable || objType == .slides)
    }
}

public struct TemplateCreateFileRecord {
    private static var curCreatedObjtoken: String?

    /// 判断是否刚刚创建完模板文档，默认调用一次这个方法就清除值了
    /// 用来给web传入render参数用
    /// - Parameter clear: 调用此方法时，是否要清除记录，默认是true
    /// - Returns: 是否刚刚创建完模板文档
    public static func isJustCreateFileByTemplate(clear: Bool = true) -> Bool {
        let createdJustNow = curCreatedObjtoken != nil
        if clear {
            curCreatedObjtoken = nil
        }
        return createdJustNow
    }

    public static func saveCurCreatedFileObjtoken(objToken: String) {
        curCreatedObjtoken = objToken
    }
}

public final class TemplateRemoteConfig {
    public static var templateEnable: Bool {
        //iPad支持模版中心FG，本期只适配模版中心v4，v4.1版本的搜索页面需要适配
        return true
    }
}
