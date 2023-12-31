//
//  OpenPluginCommentModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/14.
//

import Foundation
import LarkOpenAPIModel

class OpenPluginShowMenuPopoverParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "items")
    public var items: [[AnyHashable : Any]]

    @OpenAPIRequiredParam(userRequiredWithJsonKey: "position")
    public var position: [AnyHashable : Any]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "tag", defaultValue: "unknownTag")
    public var tag: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "offsetTop", defaultValue: 0)
    public var offsetTop: CGFloat

    @OpenAPIRequiredParam(userOptionWithJsonKey: "offsetBottom", defaultValue: 0)
    public var offsetBottom: CGFloat

    public var frame: CGRect = .zero


    public required init(with params: [AnyHashable : Any]) throws {
        try super.init(with: params)
        let top = (position["top"] as? CGFloat ?? 0).rounded(.up)
        let left = (position["left"] as? CGFloat ?? 0).rounded(.up)
        let width = (position["width"] as? CGFloat ?? 0).rounded(.up)
        let height = (position["height"] as? CGFloat ?? 0).rounded(.up)
        self.frame = CGRect(x: left, y: top, width: width, height: height)

    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_items, _position, _tag, _offsetTop, _offsetBottom]
    }
}


