//
//  OpenNativeVideoModel.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/4/18.
//

import Foundation
import LarkOpenAPIModel
import LarkWebviewNativeComponent

final class OpenNativeVideoParams: OpenComponentBaseParams {
    // MARK: - Interface variables
    @OpenComponentRequiredParam(userOptionWithJsonKey: "filePath", defaultValue: "")
    var filePath: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "poster", defaultValue: "")
    var poster: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "encrypt_token", defaultValue: "")
    var encryptToken: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "autoplay", defaultValue: false)
    var autoplay: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "controls", defaultValue: true)
    var controls: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "muted", defaultValue: false)
    var muted: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "loop", defaultValue: false)
    var loop: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showFullscreenBtn", defaultValue: true)
    var showFullscreenBtn: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showPlayBtn", defaultValue: true)
    var showPlayBtn: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "autoFullscreen", defaultValue: false)
    var autoFullscreen: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showMuteBtn", defaultValue: true)
    var showMuteBtn: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "initialTime", defaultValue: 0)
    var initialTime: Double
    
    @OpenComponentOptionalParam(jsonKey: "style")
    var style: OpenComponentVideoStyleInfo?
    
    // MARK: video 使用外层objectFit属性, 而不是style内置的objectFit属性
    @OpenComponentRequiredParam(userOptionWithJsonKey: "objectFit", defaultValue: .contain)
    var objectFit: ObjectFitTypeEnum
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "playBtnPosition", defaultValue: .bottom)
    var playBtnPosition: OpenNativeVideoPlayBtnPosition
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "direction", defaultValue: -1)
    var direction: Int
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showProgress", defaultValue: true)
    var showProgress: Bool

    @OpenComponentRequiredParam(userOptionWithJsonKey: "title", defaultValue: "")
    var title: String
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showBottomProgress", defaultValue: true)
    var showBottomProgress: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showScreenLockButton", defaultValue: true)
    var showScreenLockButton: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showSnapshotButton", defaultValue: false)
    var showSnapshotButton: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "showRateBtn", defaultValue: false)
    var showRateButton: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "enableProgressGesture", defaultValue: false)
    var enableProgressGesture: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "enablePlayGesture", defaultValue: true)
    var enablePlayGesture: Bool
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "header", defaultValue: [:])
    var header: [String: Any]
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "autoPauseIfOutsideScreen", defaultValue: true)
    var autoPauseIfOutsideScreen: Bool
    
    // properties between JSSDK and Native
    @OpenComponentRequiredParam(userOptionWithJsonKey: "data", defaultValue: "")
    var data: String
    
    // MARK: Local Variable
    var cacheDir: String;
    
    required init(with params: [AnyHashable : Any]) {
        cacheDir = ""
        super.init(with: params)
    }

    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_filePath, _poster, _encryptToken,
                _autoplay, _controls, _muted, _loop, _showFullscreenBtn, _showPlayBtn,
                _autoFullscreen, _showMuteBtn, _initialTime, _style, _objectFit,
                _playBtnPosition, _direction, _showProgress, _title, _showBottomProgress,
                _showScreenLockButton, _showSnapshotButton, _showRateButton, _enableProgressGesture,
                _enablePlayGesture, _header, _autoPauseIfOutsideScreen]
    }
}

final class OpenComponentVideoStyleInfo: OpenComponentBaseParams {
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "top", defaultValue: 0)
    var top: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "left", defaultValue: 0)
    var left: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "height", defaultValue: 0)
    var height: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "width", defaultValue: 0)
    var width: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "hide", defaultValue: false)
    var hide: Bool
    
    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_top, _left, _height, _width, _hide]
    }
    
    func frame() -> CGRect {
        return CGRect(origin: CGPoint(x: left, y: top), size: CGSize(width: width, height: height))
    }
}

enum OpenNativeVideoPlayBtnPosition: String, OpenAPIEnum {
    case bottom
    case center
}

enum OpenNativeVideoDirection: String, OpenAPIEnum {
    case vertical
    case horizontal
}

enum OpenNativeVideoUserAction: String, OpenAPIEnum {
    case play
    case centerplay
    case mute
    case fullscreen
    case retry
    case back
}

// MARK: - API Params
final class OpenNativeVideoPlaybackRateParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: 1.0)
    var rate: Double
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_rate]
    }
}

final class OpenNativeVideoSeekParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "data", defaultValue: 0.0)
    var data: Double
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_data]
    }
}

// MARK: - Event
final class OpenNativeVideoTimeUpdateResult: OpenComponentBaseResult {
    private let currentTime: Double
    private let duration: Double
    
    init(currentTime: Double, duration: Double) {
        self.currentTime = currentTime
        self.duration = duration
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "currentTime": currentTime,
            "duration": duration
        ]
    }
}

final class OpenNativeVideoFullScreenChangeResult: OpenComponentBaseResult {
    private let fullScreen: Bool
    private let direction: OpenNativeVideoDirection
    
    init(fullScreen: Bool, direction: OpenNativeVideoDirection?) {
        self.fullScreen = fullScreen
        self.direction = direction ?? .vertical
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        if fullScreen {
            return [
                "fullScreen": fullScreen,
                "direction": direction.rawValue
            ]
        }
        return ["fullScreen": fullScreen]
    }
}

final class OpenNativeVideoSeekCompleteResult: OpenComponentBaseResult {
    private let currentTime: Double
    private let duration: Double
    
    init(currentTime: Double, duration: Double) {
        self.currentTime = currentTime
        self.duration = duration
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "currentTime": currentTime,
            "duration": duration
        ]
    }
}

final class OpenNativeVideoErrorResult: OpenComponentBaseResult {
    private let errno: Int
    private let errString: String
    init(errno: Int, errString: String) {
        self.errno = errno
        self.errString = errString
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return [
            "errno": errno,
            "errString": errString,
        ]
    }
}

final class OpenNativeVideoLoadedMetaDataResult: OpenComponentBaseResult {
    private let width: Int
    private let height: Int
    private let duration: Double
    
    init(width: Int, height: Int, duration: Double) {
        self.width = width
        self.height = height
        self.duration = duration
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "width": width,
            "height": height,
            "duration": duration
        ]
    }
}

final class OpenNativeVideoControlsToggleResult: OpenComponentBaseResult {
    private let show: Bool
    
    init(show: Bool) {
        self.show = show
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        ["show": show]
    }
}

final class OpenNativeVideoUserActionResult: OpenComponentBaseResult {
    private let tag: OpenNativeVideoUserAction
    private let value: Bool?
    
    init(tag: OpenNativeVideoUserAction, value: Bool?) {
        self.tag = tag
        self.value = value
        super.init()
    }
    
    convenience init(tag: OpenNativeVideoUserAction) {
        self.init(tag: tag, value: nil)
    }
    
    override func toJSONDict() -> [String : Encodable] {
        if let _ = value {
            return [
                "tag": tag.rawValue,
                "value": value
            ]
        }
        return ["tag": tag.rawValue]
    }
}

final class OpenNativeVideoPlaybackRateChangeResult: OpenComponentBaseResult {
    private let playbackRate: Double
    
    init(playbackRate: Double) {
        self.playbackRate = playbackRate
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        ["playbackRate": playbackRate]
    }
}

final class OpenNativeVideoMuteChangeResult: OpenComponentBaseResult {
    private let isMuted: Bool
    
    init(isMuted: Bool) {
        self.isMuted = isMuted
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        ["isMuted": isMuted]
    }
}
