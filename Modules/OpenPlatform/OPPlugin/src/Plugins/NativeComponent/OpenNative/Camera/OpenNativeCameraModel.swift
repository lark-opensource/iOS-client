//
//  OpenNativeCameraModel.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/29.
//

import Foundation
import LarkOpenAPIModel
import LarkWebviewNativeComponent


// MARK: - Insert

final class OpenNativeCameraInsertParams: OpenComponentBaseParams {
    
    /// description: 应用模式，只在初始化时有效，不能动态变更
    /// mode = normal
    /// mode = scanCode
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "mode",
        defaultValue: .normal)
    var mode: CameraMode
    
    /// description:
    /// resolution = low 可选的值：
    /// resolution = medium 可选的值：medium
    /// resolution = high 可选的值：high
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "resolution",
        defaultValue: .medium)
    var resolution: CameraResolution
    
    /// description: device-position = back
    /// device-position = front
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "devicePosition",
        defaultValue: .back)
    var devicePosition: CameraDevicePosition
    
    /// description: flash = auto
    /// flash = on
    /// flash = off
    /// flash = torch
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "flash",
        defaultValue: .auto)
    var flash: CameraFlash
    
    /// description: frame-size = small
    /// frame-size = medium
    /// frame-size = large
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "frameSize",
        defaultValue: .medium)
    var frameSize: CameraFrameSize
    
    /// description: 扫码回调方式，只在初始化时有效，不能动态变更
    /// mode = continuous
    /// mode = single
    @OpenComponentRequiredParam(
        userOptionWithJsonKey: "scanCodeType",
        defaultValue: .continuous)
    var scanCodeType: CameraScanCodeType
    
    @OpenComponentOptionalParam(jsonKey: "style")
    var style: OpenComponentCameraStyleInfo?
    
    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_mode, _resolution, _devicePosition, _flash, _frameSize, _style, _scanCodeType];
    }
}

// MARK: - Update

final class OpenNativeCameraUpdateParams: OpenComponentBaseParams {
    
    /// description: device-position = back
    /// device-position = front
    @OpenComponentOptionalParam(
        jsonKey: "devicePosition")
    var devicePosition: CameraDevicePosition?
    
    /// description: flash = auto
    /// flash = on
    /// flash = off
    /// flash = torch
    @OpenComponentOptionalParam(
        jsonKey: "flash")
    var flash: CameraFlash?
    
    /// description: frame-size = small
    /// frame-size = medium
    /// frame-size = large
    @OpenComponentOptionalParam(
        jsonKey: "frameSize")
    var frameSize: CameraFrameSize?
    
    @OpenComponentOptionalParam(jsonKey: "style")
    var style: OpenComponentCameraStyleInfo?
    
    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_devicePosition, _flash, _frameSize, _style]
    }
}

final class OpenComponentCameraStyleInfo: OpenComponentBaseParams {
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "top", defaultValue: 0)
    public var top: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "left", defaultValue: 0)
    public var left: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "height", defaultValue: 0)
    public var height: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "width", defaultValue: 0)
    public var width: Double
    
    @OpenComponentRequiredParam(userOptionWithJsonKey: "fixed", defaultValue: false)
    public var fixed: Bool

    override var autoCheckProperties: [OpenComponentParamPropertyProtocol] {
        return [_top, _left, _height, _width, _fixed]
    }
    
    func frame() -> CGRect {
        return CGRect(origin: CGPoint(x: left, y: top), size: CGSize(width: width, height: height))
    }
}

// MARK: - BindInitDone Action

final class OpenNativeCameraBindInitDoneResult: OpenComponentBaseResult {
    private let maxZoom: Double
    private let devicePosition: CameraDevicePosition
    init(maxZoom: Double, devicePosition: CameraDevicePosition) {
        self.maxZoom = maxZoom
        self.devicePosition = devicePosition
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return [
            "maxZoom": maxZoom,
            "devicePosition": devicePosition.rawValue,
        ]
    }
}

// MARK: - BindError Action

final class OpenNativeCameraBindErrorResult: OpenComponentBaseResult {
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

// MARK: - BindScanCode Action

final class OpenNativeCameraBindScanCodeResult: OpenComponentBaseResult {
    private let type: String
    private let result: String
    init(type: String, result: String) {
        self.type = type
        self.result = result
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return [
            "type": type,
            "result": result,
        ]
    }
}

// MARK: - BindLumaDetect Action

final class OpenNativeCameraBindLumaDetectResult: OpenComponentBaseResult {
    private let scene: Int
    init(scene: Int) {
        self.scene = scene
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return [
            "scene": scene,
        ]
    }
}

// MARK: - TakePhoto API

final class OpenNativeCameraTakePhotoParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "quality",
        defaultValue: .medium)
    var quality: CameraResolution
    
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "selfieMirror",
        defaultValue: true)
    var selfieMirror: Bool
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_quality, _selfieMirror];
    }
}

final class OpenNativeCameraTakePhotoResult: OpenComponentBaseResult {
    private let tempImagePath: String
    init(tempImagePath: String) {
        self.tempImagePath = tempImagePath
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return ["tempImagePath": tempImagePath]
    }
}

// MARK: - SetZoom API

final class OpenNativeCameraSetZoomParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "zoom",
        defaultValue: 1.0)
    var zoom: Double
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_zoom];
    }
}

final class OpenNativeCameraSetZoomResult: OpenComponentBaseResult {
    private let zoom: Double
    init(zoom: Double) {
        self.zoom = zoom
        super.init()
    }
    override func toJSONDict() -> [String : Encodable] {
        return ["zoom": zoom]
    }
}

// MARK: - StartRecord API

let kCameraRecordTimeoutDefault: Double = 30.0
let kCameraRecordTimeoutMax: Double = 300

final class OpenNativeCameraStartRecordParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "timeout",
        defaultValue: kCameraRecordTimeoutDefault)
    var timeout: Double
    
    // VE SDK不支持预览与文件镜像，不支持录制镜像能力
//    @OpenAPIRequiredParam(
//        userOptionWithJsonKey: "selfieMirror",
//        defaultValue: true)
//    var selfieMirror: Bool
    
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "timeoutCallbackId",
        defaultValue: 0)
    var timeoutCallbackId: Double
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_timeout, /*_selfieMirror,*/ _timeoutCallbackId];
    }
    
    public required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if timeout <= 0 {
            timeout = kCameraRecordTimeoutDefault
        } else if timeout > kCameraRecordTimeoutMax {
            timeout = kCameraRecordTimeoutMax
        }
    }
}

final class OpenNativeCameraRecordTimeoutAction: OpenNativeCameraStopRecordResult {
    private let timeoutCallbackId: Double
    init(tempThumbPath: String, tempVideoPath: String, timeoutCallbackId: Double) {
        self.timeoutCallbackId = timeoutCallbackId
        super.init(tempThumbPath: tempThumbPath, tempVideoPath: tempVideoPath)
    }
    
    init(stopRecordResult: OpenNativeCameraStopRecordResult, timeoutCallbackId: Double) {
        self.timeoutCallbackId = timeoutCallbackId
        super.init(tempThumbPath: stopRecordResult.tempThumbPath, tempVideoPath: stopRecordResult.tempVideoPath)
    }
    
    override func toJSONDict() -> [String : Encodable] {
        var result = super.toJSONDict()
        result["timeoutCallbackId"] = timeoutCallbackId
        return result
    }
}

// MARK: - StopRecord API

final class OpenNativeCameraStopRecordParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(
        userOptionWithJsonKey: "compressed",
        defaultValue: false)
    var compressed: Bool
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_compressed];
    }
}

class OpenNativeCameraStopRecordResult: OpenComponentBaseResult {
    fileprivate let tempThumbPath: String
    fileprivate let tempVideoPath: String
    init(tempThumbPath: String, tempVideoPath: String) {
        self.tempThumbPath = tempThumbPath
        self.tempVideoPath = tempVideoPath
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "tempThumbPath": tempThumbPath,
            "tempVideoPath": tempVideoPath,
        ]
    }
}

// MARK: - onCameraFrame API

final class OpenNativeCameraCameraFrameAction: OpenComponentBaseResult {
    private let width: Int
    private let height: Int
    private let data: String
    init(width: Int, height: Int, data: String) {
        self.width = width
        self.height = height
        self.data = data
        super.init()
    }
    
    override func toJSONDict() -> [String : Encodable] {
        return [
            "width": width,
            "height": height,
            "data": data,
        ]
    }
}
