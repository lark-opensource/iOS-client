//
//  OpenPluginNativeComponentErrno+Camera.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/7/28.
//

import Foundation
import LarkOpenAPIModel
import LarkWebviewNativeComponent


// MARK: - Camera Errno

protocol OpenNativeCameraErrnoProtocol: OpenNativeComponentErrnoProtocol {}

extension OpenNativeCameraErrnoProtocol {
    var componentDomain: OpenNativeComponentType { .camera }
}

enum OpenNativeCameraErrno: OpenNativeCameraErrnoProtocol {
    var apiDomain: OpenNativeAPIDomain {
        switch self {
        case .commonInternalError:
            return .common
        case .insertInternalError:
            return .insert
        case .updateInternalError:
            return .update
        case .deleteInternalError:
            return .delete
        case .dispatchAction(let err):
            return err.apiDomain
        case .fireEvent(let err):
            return err.apiDomain
        }
    }
    
    var rawValue: Int {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError, .deleteInternalError:
            return 00
        case .dispatchAction(let err):
            return err.rawValue
        case .fireEvent(let err):
            return err.rawValue
        }
    }
    
    var errString: String {
        switch self {
        case .commonInternalError, .insertInternalError, .updateInternalError, .deleteInternalError:
            return "internalError"
        case .dispatchAction(let err):
            return err.errString
        case .fireEvent(let err):
            return err.errString
        }
    }
    
    case commonInternalError
    case insertInternalError
    case updateInternalError
    case deleteInternalError
    case dispatchAction(_ err: OpenNativeCameraErrnoDispatchAction)
    case fireEvent(_ err: OpenNativeCameraErrnoFireEvent)
}

enum OpenNativeCameraErrnoDispatchAction: OpenNativeCameraErrnoProtocol {
    
    enum CameraAPIName: String, CaseIterable {
        case takePhoto
        case setZoom
        case startRecord
        case stopRecord
    }
    
    var apiDomain: OpenNativeAPIDomain { .dispatchAction }
    
    case internalError
    case cameraInitError
    case notAllowInScanCodeMode(_ apiName: CameraAPIName)
    
    // startRecord error
    case recordAlreadyStarted
    case startRecordInnerError
    
    // stopRecord error
    case recordNotStarted
    case stopRecordInnerError
    case stopRecordSaveFileError
    
    // setZoom
    case setZoomTimeout
    
    // takePhoto error
    case takePhotoInnerError
    case takePhotoSaveFileError
    case takePhotoLastCaptureNotFinish
    
    var rawValue: Int {
        switch self {
        case .internalError: return 00
        case .cameraInitError: return 01
        case .notAllowInScanCodeMode: return 02
            
        case .recordAlreadyStarted: return 11
        case .startRecordInnerError: return 12
            
            // stopRecord error
        case .recordNotStarted: return 21
        case .stopRecordInnerError: return 22
        case .stopRecordSaveFileError: return 23
            
            // setZoom errror
        case .setZoomTimeout: return 31
            
            // takePhoto errror
        case .takePhotoInnerError: return 41
        case .takePhotoSaveFileError: return 42
        case .takePhotoLastCaptureNotFinish: return 43
        }
    }
    
    var errString: String {
        switch self {
        case .internalError: return "internalError"
            // camera API 通用错误
        case .cameraInitError:
            return "Camera init error"
        case .notAllowInScanCodeMode(let apiName):
            return "Not allow to invoke \(apiName.rawValue) in 'scanCode' mode"
            
            // takePhoto error
        case .takePhotoInnerError:
            return "TakePhoto camera error"
        case .takePhotoSaveFileError:
            return "TakePhoto save file error"
        case .takePhotoLastCaptureNotFinish:
            return "TakePhoto last capture not finish"
            
            // startRecord error
        case .recordAlreadyStarted:
            return "StartRecord record already started"
        case .startRecordInnerError:
            return "StartRecord camera error"
            
            // stopRecord error
        case .recordNotStarted:
            return "StopRecord record not started"
        case .stopRecordInnerError:
            return "StopRecord camera error"
        case .stopRecordSaveFileError:
            return "StartRecord save file error"
            
            // setZoom
        case .setZoomTimeout:
            return "SetZoom fail: time out"
        }
    }
    
    static func notAllowedError(_ apiName: CameraAPIName) -> OpenAPIError {
        return OpenAPIError(errno: OpenNativeCameraErrno
            .dispatchAction(.notAllowInScanCodeMode(apiName)))
    }
}

enum OpenNativeCameraErrnoFireEvent: Int, OpenNativeCameraErrnoProtocol {
    
    var apiDomain: OpenNativeAPIDomain { .fireEvent }
    
    case internalError = 00
    case cameraInitError = 01   // 相机初始化错误
    case moreThanOneCamera = 02 // 同一页面超过一个camera组件
    
    var errString: String {
        switch self {
        case .cameraInitError:
            return "Camera init error"
        case .moreThanOneCamera:
            return "Cannot add more than one camera component"
        case .internalError: fallthrough
        default:
            return "internalError"
        }
    }
}

// MARK: - OpenAPIError extension

extension OpenAPIError {
    /// 适配旧的component error
    func setCameraError(_ error: OpenNativeCameraComponentError) -> OpenAPIError {
        self.setMonitorCode(error.innerCode)
        if let errMsg = error.innerErrorMsg {
            self.setMonitorMessage(errMsg)
        }
        return self
    }
}

// MARK: - Camera Inner Error
// 区分innerError与给开发者的error
enum OpenNativeCameraComponentError: Int, OpenNativeComponentErrorProtocol {
    case noSelf = 3000201
    case noCamera = 3000202
    case frameCallbackNoFrame = 3000203 // frame call back no frame
    case noDelegate = 3000204 // no delegate
    case isNotCapture = 3000205

    var innerCode: Int {
        return self.rawValue
    }
    
    var innerErrorMsg: String? {
        switch self {
        case .noCamera:
            return "noCamera"
        case .noSelf:
            return "noSelf"
        case .frameCallbackNoFrame:
            return "frame callback without frame"
        case .noDelegate:
            return "there is no delegate"
        case .isNotCapture:
            return "camera is not capture now"
        }
    }
}
