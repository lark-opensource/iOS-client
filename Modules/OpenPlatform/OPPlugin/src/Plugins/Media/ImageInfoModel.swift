//
//  ImageInfoModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/25.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK


final class OpenAPIGetImageInfoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "src", validChecker: { !$0.isEmpty })
    public var src: String

    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_src]
    }
}

final class OpenAPIGetImageInfoResult: OpenAPIBaseResult {
    /// 图片的路径
    public let path: String
    /// 图片的宽度
    public let width: Int
    /// 图片的高度
    public let height: Int
    /// 图片类型
    public let type: String
    /// 初始化方法
    public init(path: String, width: Int, height: Int, type: String) {
        self.path = path
        self.type = type
        self.width = width
        self.height = height
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "path": path,
            "type": type,
            "width": width,
            "height": height
        ]
    }
}

final class OpenAPISaveImageParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath")
    public var filePath: String

    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath]
    }
}

final class OpenAPIPreviewImageParams: OpenAPIBaseParams {
    /// 原始参数
    public var _params: [AnyHashable : Any]
    /// 初始化方法
    public required init(with params: [AnyHashable : Any]) throws {
        _params = params
        try super.init(with: params)
    }
    /// 返回原始参数
    public func toJSONDict() -> [AnyHashable : Any] {
        return _params
    }
}
