//
//  OPCameraComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/29.
//

import Foundation
import ECOProbe
import LarkOpenAPIModel
import LarkWebviewNativeComponent

protocol OPCameraComponent: AnyObject {
    
    // MARK: properties
    
    var resolution: CameraResolution { get }

    var devicePosition: CameraDevicePosition { get }

    var flash: CameraFlash { get }
    
    func set(delegate: OPCameraComponentDelegate)

//    var frameSize: CameraFrameSize { get }
    
    func update(params: OpenNativeCameraUpdateParams, trace: OPTrace)

    // MARK: method takePhoto

    func takePhoto(params: OpenNativeCameraTakePhotoParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraTakePhotoResult>) -> Void)

    // MARK: method setZoom

    func setZoom(params: OpenNativeCameraSetZoomParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraSetZoomResult>) -> Void)

    // MARK: method startRecord

    func startRecord(params: OpenNativeCameraStartRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenComponentBaseResult>) -> Void)
    
    // MARK: method stopRecord
    
    func stopRecord(params: OpenNativeCameraStopRecordParams, context: OpenPluginNativeComponent.Context, callback: @escaping (OpenComponentBaseResponse<OpenNativeCameraStopRecordResult>) -> Void)
}

protocol OPCameraNativeProtocol: AnyObject {
    
    var preview: OPCameraPreview { get }
    
    func destory()
    
    func startCaptureIfNeeded()
    
    /// VE SDK 内部不支持在App ResignActive的时候保持录制，所以 <camera> 组件表现为在didEnterBackground和becomeActive的时候，做停止视频采集和视频采集的处理，同时给开发者上报bindstop和bindinitdone
    /// 另外一点, 如果在resignActive的时候停止采集，stopCaputre，会导致授权弹窗结束开始record时失败
    func viewWillDisappear()
    
    func viewDidDisappear()
    
    func onDeviceOrientationChange(_ orientation: UIDeviceOrientation)
}

protocol OPCameraComponentDelegate: AnyObject {
    
    /// 摄像头在非正常终止时触发，如退出后台等情况
    func bindStop() -> Void
    
    /// - 相机初始化完成时触发，e.detail = {maxZoom}
    /// - 从stop状态回到可用状态时重新触发回调。
    /// - 用户切换摄像头时，本质上是关闭上一个摄像头，开启下一个摄像头。因此会回调 bindstop -> bindinitdone
    func bindInitDone(params: OpenNativeCameraBindInitDoneResult) -> Void
    
    /// 用户不允许使用摄像头、相机创建失败等情况触发
    func bindError(error: OpenNativeCameraBindErrorResult) -> Void
    
    func bindScanCode(result: OpenNativeCameraBindScanCodeResult) -> Void
    
    func bindLumaDetect(result: OpenNativeCameraBindLumaDetectResult) -> Void
    
    func onRecordTimeout(action: OpenNativeCameraRecordTimeoutAction) -> Void
    
    func onCameraFrame(frame: OpenNativeCameraCameraFrameAction) -> Void
}

enum CameraMode: String, OpenAPIEnum {
    case normal
    case scanCode
}

enum CameraScanCodeType: String, OpenAPIEnum {
    case continuous
    case single
}

enum CameraResolution: String, OpenAPIEnum {
    case low
    case medium
    case high
}

enum CameraDevicePosition: String, OpenAPIEnum {
    case back
    case front
}

enum CameraFlash: String, OpenAPIEnum {
    case auto
    case on
    case off
    case torch
}

enum CameraFrameSize: String, OpenAPIEnum {
    case small
    case medium
    case large
}
