//
//  DocsIconInfo.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/20.
//

import Foundation
import LarkIcon

//图标形状
public enum IconShpe {
    case CIRCLE
    case SQUARE
    case OUTLINE
}

// 容器信息。（目前space、wiki、云盘有这个概念）
public struct ContainerInfo {
    // 是否快捷方式
    public var isShortCut: Bool
    // 是否共享文件夹
    public var isShareFolder: Bool
    // 是否是wiki根节点
    public var isWikiRoot: Bool
    // 用户自定义展示兜底icon
    public var defaultCustomIcon: UIImage?
    // 是否打开wiki知识库自定义icon配置
    public var wikiCustomIconEnable: Bool
    
    public init(isShortCut: Bool = false,
                isShareFolder: Bool = false,
                isWikiRoot: Bool = false,
                defaultCustomIcon: UIImage? = nil,
                wikiCustomIconEnable: Bool = false) {
        self.isShortCut = isShortCut
        self.isShareFolder = isShareFolder
        self.isWikiRoot = isWikiRoot
        self.defaultCustomIcon = defaultCustomIcon
        self.wikiCustomIconEnable = wikiCustomIconEnable
    }
}



public class DocsIconInfo: NSCoding {

    public var type: IconType = .none
    public var key: String?
    public var objType: CCMDocsType
    public var fileType: DriveFileType?
    public var token: String?
    public var version: Int?
    
    public init(type: IconType, key: String? = nil, objType: CCMDocsType, fileType: DriveFileType? = nil, token: String? = nil, version: Int? = nil) {
        self.type = type
        self.key = key
        self.objType = objType
        self.fileType = fileType
        self.token = token
        self.version = version
    }
    
    public static func createDocsIconInfo(json: String) -> DocsIconInfo? {
        
        guard !json.isEmpty, let jsonData = json.data(using: .utf8) else {
            DocsIconLogger.logger.error("IconInfo json error: \(json)")
            return nil
        }
        
        do {
            if let dic = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
                
                let type = dic["type"] as? Int ?? 0
                let key = dic["key"] as? String
                let objType = dic["obj_type"] as? Int ?? 0
                let fileType = dic["file_type"] as? String
                let token = dic["token"] as? String
                let version = dic["version"] as? Int
                
                let iconInfo = DocsIconInfo(type: IconType(rawValue: type),
                                             key: key,
                                         objType: CCMDocsType(rawValue: objType) ,
                                        fileType: DriveFileType(fileExtension: fileType),
                                           token: token,
                                         version: version)
                
                return iconInfo
                
            }
            DocsIconLogger.logger.warn("IconInfo json change to dic nil : \(json)")
        } catch {
            DocsIconLogger.logger.error("IconInfo json change to dic error : \(json), error: \(error)")
        }
        return nil
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(key, forKey: "key")
        coder.encode(objType.rawValue, forKey: "objType")
        coder.encode(fileType?.rawValue, forKey: "fileType")
        coder.encode(token, forKey: "token")
        coder.encode(version, forKey: "version")
    }
    
    required public init?(coder: NSCoder) {
        type = IconType(rawValue: Int(coder.decodeInt32(forKey: "type")))
        key = coder.decodeObject(forKey: "key") as? String
        objType = CCMDocsType(rawValue: Int(coder.decodeInt32(forKey: "objType")))
        fileType = DriveFileType(fileExtension: coder.decodeObject(forKey: "fileType") as? String)
        token = coder.decodeObject(forKey: "token") as? String
        version = coder.decodeObject(forKey: "version") as? Int
    }
    
    //从SKFilePath+Ext.swift下沉下来的方法
    public static func getFileExtension(from path: String, needCheckAdditionExtension: Bool = true, needTrim: Bool = true) -> String? {
        var name = path
        if needTrim {
            name = name.trimmingCharacters(in: .whitespaces)
        }
        if name.isEmpty { return nil }
        // swift 的 bug,当"."是最后一位时，在 iOS 13 以下会 crash https://forums.developer.apple.com/thread/123545
        if name.last == "." {
            return ""
        }
        guard let lastRange = name.range(of: ".", options: .backwards) else {
            return ""
        }
        let firstExtension = String(name[lastRange.upperBound...])
        guard let firstFileType = DriveFileType(rawValue: firstExtension),
            needCheckAdditionExtension,
            firstFileType.needCheckAdditionExtension else {
            return firstExtension
        }

        let fileName = String(name[..<lastRange.lowerBound])
        guard let secondExtension = getFileExtension(from: fileName, needCheckAdditionExtension: false, needTrim: false),
            let finalFileType = DriveFileType(rawValue: "\(secondExtension).\(firstExtension)") else {
            return firstExtension
        }
        return finalFileType.rawValue
    }
}
