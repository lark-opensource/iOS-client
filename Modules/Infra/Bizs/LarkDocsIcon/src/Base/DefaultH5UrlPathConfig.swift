//
//  DefaultH5UrlPathConfig.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/25.
//  从DocsUrlUtil下沉, 目前是拷贝下来的，存在两份，考虑合成一份

import Foundation
import SwiftyJSON
import LarkContainer

class H5UrlPathConfig: UserResolverWrapper {
    
    var userResolver: LarkContainer.UserResolver
    
    @ScopedProvider private var iconSetting: DocsIconSetting?
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    private let ioLock = NSLock()
    private var curH5UrlPathConfig: JSON?
    private var configJson: JSON {
        ioLock.lock()
        var json: JSON?
        if curH5UrlPathConfig == nil {
            if let domainConfig = iconSetting?.domainConfig {
                json = JSON(domainConfig)
            }
            curH5UrlPathConfig = json
        } else {
            json = curH5UrlPathConfig
        }
        ioLock.unlock()
        
        return json ?? defaultH5UrlPathConfig
        
    }
    
    func tokenPattern() -> String {
        guard let tokenPattern = configJson["tokenReg"].string else {
            return defaultH5UrlPathConfig["tokenReg"].stringValue
        }
        return tokenPattern
    }
    
    var productMap: [String: String] {
        var map = [String: String]()
        if let latestMapLo = configJson["productMap"].dictionaryObject as? [String: String] {
            map = latestMapLo
        } else if let defaultMap = defaultH5UrlPathConfig["productMap"].dictionaryObject as? [String: String] {
            map = defaultMap
        }
        return map
    }
    
    func getTypePattern() -> String {
        guard let typePattern = configJson["tokenPattern"]["typeReg"].string, !typePattern.isEmpty else {
            return "/(doc|docs|docx|sheet|sheets|bitable|base|slide|slides|mindnote|mindnotes|file|folder|wiki)/"
        }
        return typePattern
//        let typePatterns = productMap.keys.joined(separator: "|")
//        if typePatterns.isEmpty {
//            //            spaceAssertionFailure("namePatterns can't be empty, set default latestMap to defaultH5UrlPathConfig ")
//            return "/(doc|docs|docx|sheet|sheets|bitable|base|slide|slides|mindnote|mindnotes|file|folder|wiki)/"
//        }
//        return "/(" + typePatterns + ")/"
    }
    
    var enable: Bool {
        return configJson["newPathEnable"].boolValue
    }
    
    func getRealType(for typeName: String) -> (canOpen: Bool, realType: CCMDocsType) {
        
        guard enable, !typeName.isEmpty else {
            return (false, .unknownDefaultType)
        }
        
        guard
            let latestTypeName = productMap[typeName],
            let uniqueTypeName = matchRealType(for: latestTypeName),
            let type = CCMDocsType(name: uniqueTypeName)
        else {
            return (false, .unknownDefaultType)
        }
        
        return (true, type)
        /*
         productMap的结构如下：
         result["productMap"]["docs"]       = "doc"
         result["productMap"]["doc"]        = "doc"
         result["productMap"]["sheet"]      = "sheet"
         result["productMap"]["sheets"]     = "sheet"
         */
        
    }
    
    private func matchRealType(for latestTypeName: String) -> String? {
        var realTypeName: String?
        // 由于配合安卓临时改配置，这个方法暂时写成这样，兼容各种情况的map
        for (key, value) in latestMap where value == latestTypeName {
            realTypeName = key
        }
        
        if realTypeName == nil {
            for (key, value) in oldDefaultLatestMap where value == latestTypeName {
                realTypeName = key
            }
        }
        
        return realTypeName
    }
    
    var latestMap: [String: String] {
        var map = [String: String]()
        if let latestMapLo = configJson["lateastMap"].dictionaryObject as? [String: String] {
            map = latestMapLo
        } else if let defaultMap = defaultH5UrlPathConfig["lateastMap"].dictionaryObject as? [String: String] {
            map = defaultMap
        }
        return map
    }
}

extension H5UrlPathConfig {
    
    var defaultH5UrlPathConfig: JSON {
        var result = [String: Any]()
        
        result["enable"] = false
        let latestMap: [String: String] = ["doc": "docs",
                                           "docx": "docx",
                                           "sheet": "sheets",
                                           "bitable": "base",
                                           "slides": "slides",
                                           "mindnote": "mindnotes",
                                           "file": "file",
                                           "folder": "folder",
                                           "wiki": "wiki"
        ]
        result["lateastMap"] = latestMap
        
        let productMap: [String: String] = ["docs": "doc",
                                            "doc": "doc",
                                            "docx": "docx",
                                            "sheet": "sheet",
                                            "sheets": "sheet",
                                            "bitable": "bitable",
                                            "base": "bitable",
                                            "slide": "slide",
                                            "slides": "slides",
                                            "mindnote": "mindnote",
                                            "mindnotes": "mindnote",
                                            "file": "file",
                                            "folder": "folder",
                                            "wiki": "wiki"
        ]
        
        result["productMap"] = productMap
        result["tokenReg"]                       = "/([\\w]{14,})"
        result["folderPathPrefix"]               = "drive"
        result["phoenixPathPrefix"]              = "workspace"
        return JSON(result)
    }
    
    var oldDefaultLatestMap: [String: String] {
        let latestMap: [String: String] = ["doc": "doc",
                                           "docx": "docx",
                                           "sheet": "sheet",
                                           "bitable": "bitable",
                                           "slide": "slide",
                                           "mindnote": "mindnote",
                                           "file": "file",
                                           "folder": "folder",
                                           "wiki": "wiki"
        ]
        
        return latestMap
    }
    
}
