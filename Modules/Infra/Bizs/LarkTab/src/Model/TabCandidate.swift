//
//  TabCandidate.swift
//  LarkTab
//
//  Created by Hayden on 2023/5/12.
//

import Foundation
import LarkSensitivityControl

/// 记录 “最近打开” 页面的数据结构
public struct TabCandidate: Codable {

    /// 用于页面去重的唯一标识
    public var id: String
    /// 用于显示的图标
    public var icon: TabIcon
    /// 用于显示的名称
    public var title: String
    /// 路由系统中使用的页面 URL
    public var url: String
    /// BizType, 对应TabContainable中的tabBizType，pin到「最长使用」接口需要
    public var bizType: CustomBizType
    /// AppType, 固定到「最长使用」转换成Tab需要
    public var appType: AppType
    /// BizId, 对应TabContainable中的tabBizID，pin到「最长使用」接口需要
    public var bizId: String
    /// UniqueId，sdk生成，用于删除最近使用记录
    public var uniqueId: String

    public init(id: String, icon: TabIcon, title: String, url: String, bizType: CustomBizType, appType: AppType, bizId: String, uniqueId: String = "") {
        self.id = id
        self.icon = icon
        self.title = title
        self.url = url
        self.bizType = bizType
        self.appType = appType
        self.bizId = bizId
        self.uniqueId = uniqueId
    }
}

extension TabCandidate {

    public enum IconType: String, Codable {
        case udToken
        case byteKey
        case webURL
        case iconInfo
    }

    public struct TabIcon: Codable {

        /// 图片类型
        public var type: IconType

        /// 由 type 决定 content 内容
        /// - `udToken`: UDIcon 的 typeName
        /// - `byteKey`: 转为 JsonString 的 ByteWebImage key 和 eneityID
        /// - `webURL`: 网络图片的链接
        /// - `imageData`: 经过 base64 编码的图片
        public var content: String

        /// 创建一个 `udToken` 类型的 `TabIcon`
        public static func udToken(_ name: String) -> TabIcon {
            TabIcon(type: .udToken, content: name)
        }

        /// 创建一个 `webURL` 类型的 `TabIcon`
        public static func webURL(_ urlString: String) -> TabIcon {
            TabIcon(type: .webURL, content: urlString)
        }

        /// 创建一个 `byteKey` 类型的 `TabIcon`
        public static func byteKey(_ key: String, entityID: String? = nil) -> TabIcon {
            var keyDic: [String: String] = ["key": key]
            keyDic["entityID"] = entityID
            return TabIcon(type: .byteKey, content: keyDic.toJSONString() ?? "")
        }
        
        /// 创建一个 `ccmIconInfo` 类型的 `TabIcon`
        public static func iconInfo(_ iconInfo: String) -> TabIcon {
            TabIcon(type: .iconInfo, content: iconInfo)
        }

        /// 如果是 `byteKey` 类型，从 `content` 字段中解析出 `key` 和 `eneityID`
        /// - Returns: 包含 `key` 和 `eneityID` 的元组
        public func parseKeyAndEntityID() -> (key: String?, entityID: String?) {
            guard type == .byteKey else { return (nil, nil) }
            guard let dic = content.toJSONDictionary() as? [String: String] else { return (nil, nil) }
            return (key: dic["key"], entityID: dic["entityID"])
        }
    }
}

// MARK: Image Encoding

public extension UIImage {

    /// 将 UIImage 实例进行 base64 编码字符串
    func toBase64String() -> String {
        return self.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }

    /// 从 base64 编码字符串创建 UIImage 实例
    static func fromBase64String(_ base64: String) -> UIImage {
        if let imageData = Data(base64Encoded: base64),
           let image = UIImage(data: imageData) {
            return image
        }
        return UIImage()
    }
    
    static func transformToGrayImage(_ image: UIImage) -> UIImage? {
        let ciImage = CIImage(image: image)
        // 创建一个CIFilter实例，用于调整饱和度
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            // 将饱和度设置为0
            filter.setValue(0, forKey: kCIInputSaturationKey)
            if let outputImage = filter.outputImage {
                // 将处理后的CIImage转换为UIImage
                let context = CIContext(options: nil)
                if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                    let resultImage = UIImage(cgImage: cgImage)
                    // 将处理后的UIImage返回
                    return resultImage
                }
            }
        }
        return nil
    }
}

public extension UIView {
    func getScreenShotImage() -> UIImage? {
        guard self.bounds.size.width != CGSize.zero.width, self.bounds.size.height != CGSize.zero.height else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        // 敏感api管控 https://bytedance.feishu.cn/wiki/wikcn0fkA8nvpAIjjz4VXE6GC4f
        let tokenString = "LARK-PSDA-super_app_navigation_bar_uiview_snapshot"
        let token = Token(tokenString, type: .deviceInfo)
        do {
            // 截取 UIView 的快照
            try DeviceInfoEntry.drawHierarchy(forToken: token,
                                              view: self,
                                              rect: self.bounds,
                                              afterScreenUpdates: true)
            // 将快照转换为 UIImage
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        } catch {
            UIGraphicsEndImageContext()
            return nil
        }
    }
}

// MARK: JSON Encoding

fileprivate extension Dictionary {

    /// 将 Dictionary 编码为 JSON 字符串
    func toJSONString() -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) {
            return String(data: jsonData, encoding: .utf8)?.urlEncoded()
        }
        return nil
    }
}

fileprivate extension String {

    /// 将 JSON 字符串恢复为字典（返回是 Any 类型，需要自己转换）
    func toJSONDictionary() -> Any? {
        if let jsonData = self.urlDecoded().data(using: .utf8),
           let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) {
            return dictionary
        }
        return nil
    }

    /// 将原始的url编码为合法的 url
    ///
    /// Swift3 新增的 `addingPercentEncoding` 方法实现了编码功能，将指定的字符集使用 "%" 代替。
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }

    /// 将编码后的url转换回原始的 url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}
