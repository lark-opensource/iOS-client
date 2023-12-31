//
//  OpenPluginChooseMediaModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/5/18.
//

import UIKit
import LarkOpenAPIModel

final class OpenPluginChooseMediaParams: OpenAPIBaseParams {
    /// description: 使用相机拍摄的默认摄像头，仅iOS支持且在sourceType为camera时生效
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "cameraDevice",
            defaultValue: "back")
    var cameraDevice: String
    
    /// description: 最多可以选择的文件数量，可支持选择多个图片或多个视频。飞书5.30前，最多可支持9个文件，5.30及以后最多可支持20个文件，使用相机拍照拍视频时该字段失效
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "count",
            defaultValue: 9)
    var count: Int
    
    /// description: 拍摄视频最长拍摄时间，单位秒。时间范围为 3s 至 60s 之间。不限制相册。
    /// PC 端：暂不支持此参数，不限制最大时长
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "maxDuration",
            defaultValue: 60)
    var maxDuration: Double
    
    /// description: 文件类型，图片或/和视频
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "mediaType",
            defaultValue: ["image","video"])
    var mediaType: [String]
    
    /// description: 表示选择原图或原视频，还是选择压缩后的图片或视频。仅iOS支持视频压缩。PC默认为原图，除非传递['compressed']开启强制压缩
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "sizeType",
            defaultValue: ["original","compressed"])
    var sizeType: [String]
    
    /// description: 指定视频来源为相册或/和相机，PC不支持该字段
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "sourceType",
            defaultValue: ["album","camera"])
    var sourceType: [String]
    
    /// description: 拍照/录像时是否将照片/视频存入相册，0表示不保存，1表示自动保存
    /// 注意事项：pc不支持此字段
    /// isSaveToAlbum = 0 不保存
    /// isSaveToAlbum = 1 保存
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "isSaveToAlbum",
            defaultValue: .zero)
    var isSaveToAlbum: IsSaveToAlbumEnum
    
    /// 接口暂无这个字段，实际是可以变化的，所以预留出来，具体参考内部实现
    @OpenAPIRequiredParam(userOptionWithJsonKey: "singleSelect", defaultValue: false)
    var singleSelect: Bool
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_mediaType, _sourceType, _count, _maxDuration, _sizeType, _cameraDevice, _singleSelect, _isSaveToAlbum]
    }

    // MARK: IsSaveToAlbumEnum
    enum IsSaveToAlbumEnum: String, OpenAPIEnum {

        /// description: 不保存
        case zero = "0"

        /// description: 保存
        case one = "1"

    }
    
}

final class OpenPluginChooseImageModel {
    var path:String
    var size:Int
    init(path:String, size:Int) {
        self.path = path
        self.size = size
    }
    init() {
        self.path = ""
        self.size = 0
    }
}
final class OpenPluginChooseVideoModel {
    var path:String
    var duration:Float
    var size:Int
    var width:Float
    var height:Float
    init(path:String, duration:Float, size:Int, width:Float, height:Float) {
        self.path = path
        self.duration = duration
        self.size = size
        self.width = width
        self.height = height
    }
    init() {
        self.path = ""
        self.duration = 0
        self.size = 0
        self.width = 0
        self.height = 0
    }
}

enum ChooseMediaType: String {
    case image = "image"
    case video = "video"
    case error = "error"
}

final class OpenPluginChooseMediaModel {
    var type:ChooseMediaType
    var image:OpenPluginChooseImageModel
    var video:OpenPluginChooseVideoModel
    init(type:ChooseMediaType, video:OpenPluginChooseVideoModel) {
        self.type = type
        self.image = OpenPluginChooseImageModel()
        self.video = video
    }
    init(type:ChooseMediaType, image:OpenPluginChooseImageModel) {
        self.type = type
        self.image = image
        self.video = OpenPluginChooseVideoModel()
    }
    init(type:ChooseMediaType) {
        self.type = type
        self.image = OpenPluginChooseImageModel()
        self.video = OpenPluginChooseVideoModel()
    }
    func toJSONDict() -> [AnyHashable : Any] {
        var result:[AnyHashable : Any] = ["type": type.rawValue]
        switch type {
        case .image:
            result["tempFilePath"] = image.path
            result["size"] = image.size
        case .video:
            result["tempFilePath"] = video.path
            result["duration"] = video.duration
            result["size"] = video.size
            result["width"] = video.width
            result["height"] = video.height
        case .error: break
        }
        return result
    }
}

final class OpenPluginChooseMediaResult: OpenAPIBaseResult {
    var files: [OpenPluginChooseMediaModel]
    init(files: [OpenPluginChooseMediaModel]) {
        self.files = files
        super.init()
    }
    override func toJSONDict() -> [AnyHashable : Any] {
        return ["tempFiles": files.map { $0.toJSONDict() }]
    }
}
