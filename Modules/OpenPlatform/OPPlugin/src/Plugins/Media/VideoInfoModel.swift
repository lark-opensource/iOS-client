//
//  ChooseVideoModel.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK

final class OpenAPIChooseVideoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "compressed", defaultValue: true)
    public var compressed: Bool
    
    @OpenAPIRequiredParam(userOptionWithJsonKey: "sourceType", defaultValue: ["album", "camera"])
    public var sourceType: [String]
    
    ///默认选择的视频长度是 60s，最长是180s
    @OpenAPIRequiredParam(userOptionWithJsonKey: "maxDuration", defaultValue: 60)
    public var maxDuration: Int
    /// 初始化方法
    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if self.maxDuration == 0 { // 对齐wx，0的时候也是当做非法值对待，变成默认时长
            self.maxDuration = 60
        }
        if self.compressed {
            //  当 compressd 为 true 时，maxDuration 默认值为 60s，最大支持选取 180s 视频；当 compressd 为 false 时，maxDuration 默认值为 60s，不限制最大时长
            self.maxDuration = min(self.maxDuration, 180)
        }
    }
    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_compressed, _sourceType, _maxDuration]
    }
}

final class OpenAPIChooseVideoResult: OpenAPIBaseResult {
    /// 导出视频的完整文件路径
    public let tempFilePath: String
    /// 导出视频的时长(单位：s)
    public let duration: Double
    /// 导出视频的文件大小（单位：Bytes）
    public let size: CGFloat
    /// 导出视频的分辨率高度
    public let height: CGFloat
    /// 导出视频的分辨率宽度
    public let width: CGFloat
    /// 初始化方法
    public init(tempFilePath: String,
                duration: Double,
                size: CGFloat,
                height: CGFloat,
                width: CGFloat) {
        self.tempFilePath = tempFilePath
        self.duration = duration
        self.size = size
        self.height = height
        self.width = width
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        return [
            "tempFilePath": tempFilePath,
            "duration": duration,
            "size": size,
            "height": height,
            "width": width
        ]
    }
}

final class OpenAPISaveVideoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "filePath")
    public var filePath: String

    /// 属性自定义检查器
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_filePath]
    }
}
