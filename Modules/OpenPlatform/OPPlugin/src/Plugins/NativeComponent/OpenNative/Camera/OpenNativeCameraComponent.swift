//
//  OpenNativeCameraComponent.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/6/29.
//

import Foundation
import OPPluginManagerAdapter
import LKCommonsLogging
import LarkOpenAPIModel
import LarkWebviewNativeComponent
import LarkOpenAPIModel
import TTVideoEditor
import LarkVideoDirector

final class OpenNativeCameraComponent: OpenPluginNativeComponent {
    fileprivate static let logger = Logger.oplog(OpenNativeCameraComponent.self, category: "LarkWebviewNativeComponent")
    // 组件标签名字
    override class func nativeComponentName() -> String {
        return "camera"
    }
    
    override init() {
        super.init()
        self.register()
    }
    
    private var camera: (OPCameraComponent & OPCameraNativeProtocol)?
    
    // 组件插入接收，返回view
    override func insert(context: Context, callback: @escaping (OpenComponentInsertResponse) -> Void) {
        
        let trace = context.trace
        let params = context.params
        let uniqueID = context.uniqueID
        
        trace.info("insert start")
        
        let model = OpenNativeCameraInsertParams(with: params)
        
        do {
            try self.createCamera(with: model, uniqueID: uniqueID, trace: trace, callback: callback)
            trace.info("insert end")
        } catch {
            let errno = OpenNativeCameraErrnoFireEvent.cameraInitError
            self.bindError(error: OpenNativeCameraBindErrorResult(errno: errno.errno(), errString: errno.errString))
            callback(.failure(error: OpenAPIError(errno: errno)))
        }
    }
    
    private func createCamera(with model: OpenNativeCameraInsertParams, uniqueID: OPAppUniqueID, trace: OPTrace, callback: @escaping (OpenComponentInsertResponse) -> Void) throws {
        trace.info("createCamera start, model: \(model.description)")

        // 准备VE相关的环境
        VideoEditorManager.shared.setupVideoEditorIfNeeded()
        VEPreloadModule.prepareVEContext()
        
        var camera: OPCameraComponent & OPCameraNativeProtocol
        if model.mode == .scanCode {
            camera = try OPScanCodeCamera(params: model, uniqueID: uniqueID)
        } else {
            camera = OPNormalCamera(params: model, uniqueID: uniqueID)
        }
        camera.set(delegate: self)
        self.camera = camera
        callback(.success(view: camera.preview))
        trace.info("did createCamera, uniqueID: \(uniqueID.fullString)")
    }
    
    override func onUniqueCheckFail() -> OpenAPIErrnoProtocol? {
        let errno = OpenNativeCameraErrnoFireEvent.moreThanOneCamera
        self.bindError(error: OpenNativeCameraBindErrorResult(errno: errno.errno(), errString: errno.errString))
        return errno
    }
    
    override func viewDidInsert(success: Bool) {
        Self.logger.info("viewDidInsert, success: \(success)")
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(onDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func onInsertAuthFail(errno: OpenAPIErrnoProtocol) {
        self.bindError(error: OpenNativeCameraBindErrorResult(errno: errno.errno(), errString: errno.errString))
    }

    // 组件更新
    override func update(nativeView: UIView?, params: [AnyHashable: Any], trace: OPTrace) {
        trace.info("update start")
        
        guard let camera = camera else {
            let error = OpenAPIError(errno: OpenNativeCameraErrno.updateInternalError)
                .setCameraError(.noCamera)
            trace.error("camera is not exist", tag: "", additionalData: nil, error: error)
            return
        }
        
        let model = OpenNativeCameraUpdateParams(with: params)
        camera.update(params: model, trace: trace)
        trace.info("upadte end")
    }

    // 组件删除
    override func delete(trace: OPTrace?) {
        trace?.info("delete")
        self.camera?.destory()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        Self.logger.info("viewDidAppear")
        self.camera?.startCaptureIfNeeded()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        Self.logger.info("viewWillDisappear")
        self.camera?.viewWillDisappear()
    }
    
    override func viewDidDisappear() {
        // viewDidDisappear 时处理 scan camera销毁事件
        super.viewDidDisappear()
        Self.logger.info("viewDidDisappear")
        self.camera?.viewDidDisappear()
    }
    
    override var needListenAppPageStatus: Bool { true }
    override var needUniqueCheck: Bool { true }
    override var insertAuth: [String]? { [BDPInnerScopeCamera] }
    
    @objc private func onDeviceOrientationChange() {
        let orientation = UIDevice.current.orientation
        guard orientation == .portrait ||
                orientation == .landscapeLeft ||
                orientation == .landscapeRight ||
                orientation == .portraitUpsideDown else {
            return
        }
        camera?.onDeviceOrientationChange(orientation)
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Register
extension OpenNativeCameraComponent {
    
    enum CameraDispatchActionType: String, CaseIterable {
        case cameraTakePhoto
        case cameraSetZoom
        case cameraStartRecord
        case cameraStopRecord
        case onCameraFrame
        case offCameraFrame
    }
    
    func register() {
        Self.logger.info("register")
        self.registerCameraHandler(
            for: .cameraTakePhoto,
            OpenNativeCameraTakePhotoParams.self,
            OpenNativeCameraTakePhotoResult.self, {
            camera, params, context, callback in
                camera.takePhoto(params: params, context: context, callback: callback)
            })
        
        self.registerCameraHandler(
            for: .cameraSetZoom,
            OpenNativeCameraSetZoomParams.self,
            OpenNativeCameraSetZoomResult.self, {
            camera, params, context, callback in
                camera.setZoom(params: params, context: context, callback: callback)
            })
        
        self.registerCameraHandler(
            for: .cameraStartRecord,
            OpenNativeCameraStartRecordParams.self,
            OpenComponentBaseResult.self, {
                camera, params, context, callback in
                camera.startRecord(params: params, context: context, callback: callback)
            }, [BDPInnerScopeRecord])
        
        self.registerCameraHandler(
            for: .cameraStopRecord,
            OpenNativeCameraStopRecordParams.self,
            OpenNativeCameraStopRecordResult.self, {
            camera, params, context, callback in
                camera.stopRecord(params: params, context: context, callback: callback)
            })
        
//        self.registerCameraHandler(
//            for: .onCameraFrame,
//            OpenAPIBaseParams.self,
//            OpenComponentBaseResult.self) {
//            camera, _, context, callback in
//                camera.onCameraFrame(context: context, callback: callback)
//        }
//
//        self.registerCameraHandler(
//            for: .offCameraFrame,
//            OpenAPIBaseParams.self,
//            OpenComponentBaseResult.self) {
//            camera, _, context, callback in
//                camera.offCameraFrame(context: context, callback: callback)
//        }
    }
    
    typealias camerahandler<Param: OpenAPIBaseParams, Result: OpenComponentBaseResult> = (
        _ camera: OPCameraComponent & OPCameraNativeProtocol,
        _ params: Param,
        _ context: OpenPluginNativeComponent.Context,
        _ callback: @escaping (OpenComponentBaseResponse<Result>) -> Void
    ) -> Void
    
    func registerCameraHandler<Param, Result>(
        for apiName: CameraDispatchActionType,
        _ paramsType: Param.Type = Param.self,
        _ resultType: Result.Type = Result.self,
        _ handler: @escaping camerahandler<Param, Result>,
        _ scopes: [String] = []
    ) where Param: OpenAPIBaseParams, Result: OpenComponentBaseResult {
        self.registerHandler(for: apiName.rawValue, paramsType: paramsType, resultType: resultType, handler: {
            [weak self] params, context, callback in
            guard let camera = self?.camera else {
                let error = OpenAPIError(errno: OpenNativeCameraErrno.dispatchAction(.cameraInitError))
                    .setCameraError(.noCamera)
                callback(.failure(error: error))
                return
            }
            handler(camera, params, context, callback)
        }, authScopes: scopes)
    }
}

// MARK: - OPCameraComponentDelegate
extension OpenNativeCameraComponent: OPCameraComponentDelegate {
    
    enum CameraComponentActionType: String {
        case onCameraBindStop
        case onCameraBindInitDone
        case onCameraBindError
        case onCameraBindScanCode
        case onCameraBindLumaDetect
        case onCameraRecordTimeout
        case onCameraFrameCallback
    }
    
    func bindStop() -> Void {
        self.fireCameraEvent(event: .onCameraBindStop, params: .init())
    }
    
    func bindInitDone(params: OpenNativeCameraBindInitDoneResult) -> Void {
        self.fireCameraEvent(event: .onCameraBindInitDone, params: params)
    }
    
    /// 用户不允许使用摄像头、相机创建失败等情况触发
    func bindError(error: OpenNativeCameraBindErrorResult) -> Void {
        self.fireCameraEvent(event: .onCameraBindError, params: error)
    }
    
    func onRecordTimeout(action: OpenNativeCameraRecordTimeoutAction) -> Void {
        self.fireCameraEvent(event: .onCameraRecordTimeout, params: action)
    }
    
    func onCameraFrame(frame: OpenNativeCameraCameraFrameAction) -> Void {
        self.fireCameraEvent(event: .onCameraFrameCallback, params: frame)
    }
    
    func bindScanCode(result: OpenNativeCameraBindScanCodeResult) -> Void {
        self.fireCameraEvent(event: .onCameraBindScanCode, params: result)
    }
    
    func bindLumaDetect(result: OpenNativeCameraBindLumaDetectResult) -> Void {
        self.fireCameraEvent(event: .onCameraBindLumaDetect, params: result)
    }
    
    private func fireCameraEvent(event: CameraComponentActionType, params: OpenComponentBaseResult) {
        Self.logger.info("fireCameraEvent, params: \(params)")
        self.fireEvent(event: event.rawValue, params: params.toJSONDict())
    }
}

