//
//  OpenThirdShareModel.swift
//  OPPlugin
//
//  Created by yi on 2021/4/14.
//

import Foundation
import LarkOpenAPIModel
import OPPluginBiz

final class OpenAPIThirdShareParams: OpenAPIBaseParams {
    // channelType enum
    public enum ShareChannelTypeEnum: String, OpenAPIEnum {
        case wx = "wx"
        case wx_timeline = "wx_timeline"
        case system = "system"
        public static var allowArrayParamEmpty: Bool {
            return false
        }
    }
    
    // contentType enum
    public enum ShareContentTypeEnum: String, OpenAPIEnum {
        case text = "text"
        case image = "image"
        case url = "url"
    }
    
    // 分享渠道在「海外Lark」和「国内飞书」因合规原因默认值不同
    // wx 禁用了lark sdk，故在海外分享时有已知问题
    // Lark：system
    // 飞书：wx, wx_timeline
    private static let defaultChannelType: [ShareChannelTypeEnum] = {
        if OPThirdShareHelper.isLark(){
            return [.system]
        }
        return [.wx, .wx_timeline]
    }()

    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "channelType",
        defaultValue: defaultChannelType
    )
    public var channelType: [ShareChannelTypeEnum]
    
    @OpenAPIRequiredParam(
        userRequiredWithJsonKey: "contentType"
    )
    public var contentType: ShareContentTypeEnum

    @OpenAPIRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    public var title: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "content", defaultValue: "")
    public var content: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "url", defaultValue: "")
    public var url: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "image", defaultValue: "")
    public var image: String
    
    public convenience init(contentType: String, title: String, content: String, url: String, image: String, channelType: [String]) throws {
        let dict: [String: Any] = ["contentType": contentType, "title": title, "content": content, "url": url, "image": image, "channelType": channelType]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_contentType, _title, _content, _url, _image, _channelType]
    }
}

final class OpenAPIShareLinkParams: OpenAPIBaseParams {

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "link")
    public var link: String
    
    @OpenAPIOptionalParam(jsonKey: "title")
    public var title: String?
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_link, _title]
    }
}
