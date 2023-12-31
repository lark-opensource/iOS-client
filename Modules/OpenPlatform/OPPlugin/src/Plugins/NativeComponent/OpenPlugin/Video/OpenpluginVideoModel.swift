//
//  OpenpluginVideoModel.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/8.
//

import UIKit
import LarkOpenAPIModel

final class OpenPluginVideoOperateParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "videoPlayerId",
                          defaultValue: "")
    var videoPlayerId: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type",
                          defaultValue: "")
    var type: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId",
                          defaultValue: 0)
    var frameId: Int
    var data: Double = 0

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if let dataParam = params["data"] as? Double {
            self.data = dataParam
        } else {
            if self.type == "seek" {
                throw OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setOuterMessage("seek data missed")
            }
        }
    }

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_videoPlayerId, _type, _frameId]
    }
}

final class OpenPluginVideoRemoveParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "videoPlayerId", defaultValue: "")
    var videoPlayerId: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId", defaultValue: 0)
    var frameId: Int
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_videoPlayerId, _frameId]
    }
}

final class OpenPluginVideoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "_videoId", defaultValue: "")
    var videoId: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "frameId", defaultValue: 0)
    var frameId: Int
    @OpenAPIRequiredParam(userOptionWithJsonKey: "type", defaultValue: "")
    var type: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "videoPlayerId", defaultValue: "")
    var videoPlayerId: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "hide", defaultValue: false)
    var hide: Bool

    @OpenAPIRequiredParam(userOptionWithJsonKey: "autoplay", defaultValue: false)
    var autoplay: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "loop", defaultValue: false)
    var loop: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "position", defaultValue: [:])
    var position: [String : Float]
    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: "")
    var data: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "filePath", defaultValue: "")
    var filePath: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "poster", defaultValue: "")
    var poster: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "initialTime", defaultValue: 0)
    var initialTime: Int
    @OpenAPIRequiredParam(userOptionWithJsonKey: "duration", defaultValue: 0)
    var duration: Int
    @OpenAPIRequiredParam(userOptionWithJsonKey: "objectFit", defaultValue: "")
    var objectFit: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "cacheDir", defaultValue: "")
    var cacheDir: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: "encrypt_token", defaultValue: "")
    var encryptToken: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "muted", defaultValue: false)
    var muted: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "controls", defaultValue: false)
    var controls: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "showFullscreenBtn", defaultValue: true)
    var showFullscreenBtn: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "showPlayBtn", defaultValue: true)
    var showPlayBtn: Bool

    @OpenAPIRequiredParam(userOptionWithJsonKey: "playBtnPosition", defaultValue: "")
    var playBtnPosition: String
    @OpenAPIRequiredParam(userOptionWithJsonKey: "autoFullscreen", defaultValue: false)
    var autoFullscreen: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "showMuteBtn", defaultValue: false)
    var showMuteBtn: Bool
    @OpenAPIRequiredParam(userOptionWithJsonKey: "header", defaultValue: [:])
    var header: [String : Any]
    @OpenAPIRequiredParam(userOptionWithJsonKey: "fixed", defaultValue: false)
    var fixed: Bool //!< 没用到
    @OpenAPIRequiredParam(userOptionWithJsonKey: "zIndex", defaultValue: 0)
    var zIndex: Float //!< 没用到

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_videoId, _frameId, _type, _videoPlayerId, _hide,
                _autoplay, _loop, _position, _data, _filePath,
                _poster, _initialTime, _duration, _objectFit, _cacheDir,
                _encryptToken, _muted, _controls, _showFullscreenBtn, _showPlayBtn,
                _playBtnPosition, _autoFullscreen, _showMuteBtn, _header, _fixed, _zIndex]
    }
}

final class OpenPluginVideoInsertResult: OpenAPIBaseResult {
    let videoPlayerId: String

    init(videoPlayerId: String) {
        self.videoPlayerId = videoPlayerId
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable : Any] {
        return ["videoPlayerId": videoPlayerId]
    }
}
