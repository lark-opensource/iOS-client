//
//  AcquireFaceImagePlugin.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/5/26.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import OPPluginBiz
import LarkContainer

///人脸采集api
final class AcquireFaceImagePlugin: OpenBasePlugin {

    func startAcquireFaceImage(params: OpenPluginAcquireFaceImageRequest, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginAcquireFaceImageResponse>) -> Void) {
        context.apiTrace.info("startAcquireFaceImage call")
     
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext,
              let controller = gadgetContext.controller else {
              let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                  .setMonitorMessage("gadgetContext or controller is nil")
                  .setErrno(OpenAPICommonErrno.internalError)
              callback(.failure(error: error))
              return
        }
        
        guard let delegate = EMAProtocolProvider.getLiveFaceDelegate() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("EERoute delegate nil")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return
        }
        let faceAngleLimit = Int32(truncatingIfNeeded: Int64(params.pitchAngle ?? -1))
        context.apiTrace.info("startAcquireFaceImage faceAngleLimit:\(faceAngleLimit)")
        ///人脸采集
        delegate.startFaceQualityDetect(withBeautyIntensity: 0,
                                        backCamera: params.cameraDevice == .back,
                                        faceAngleLimit: faceAngleLimit,
                                        from: controller) { error, faceImage, result in
            if let err = error {
                let code = (err as NSError).code
                let msg = err.localizedDescription
                let apiErr = OpenAPIError(code: AcquireFaceImageErrorCode(rawValue: code) ?? AcquireFaceImageErrorCode.unknownError)
                    .setMonitorMessage("faceQualityDetect error, code: \(code), msg: \(msg)")
                    .setOuterMessage(msg)
                    .setErrno(FaceVerifyUtils.splitCertSdkError(certErrorCode: code, msg: msg))
                callback(.failure(error: apiErr))
                return
            }

            if let result = result {
                context.apiTrace.info("acquireFaceImage result:\(result)")
            }
            if let faceImage = faceImage {
                do {
                    context.apiTrace.info("faceQualityDetect faceImage success")

                    let imageData = faceImage.jpegData(compressionQuality: 1.0)
                    
                    guard let imageData = imageData, let fileExtension = TMACustomHelper.contentType(forImageData: imageData) else {
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("imageData or fileExtension is nil")
                            .setErrno(OpenAPICommonErrno.unknown)
                        context.apiTrace.error("imageData or fileExtension is nil")
                        callback(.failure(error: error))
                        return
                    }
                        
                    /// 存入沙箱temp
                    let randomFile = FileObject.generateRandomTTFile(type: .temp, fileExtension: fileExtension)
                    let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID,
                                                       trace: context.apiTrace,
                                                       tag: "acquireFaceImage")
                    /// 写入数据
                    try FileSystemCompatible.writeSystemData(imageData, to: randomFile, context: fsContext)
                    callback(.success(data: OpenPluginAcquireFaceImageResponse(tempFilePath: randomFile.rawValue)))

                } catch is FileSystemError {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("write file fail")
                        .setErrno(OpenAPIBiologyErrno.failedSaveImage)
                    callback(.failure(error: error))
                } catch {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("file system error")
                        .setErrno(OpenAPICommonErrno.unknown)
                    callback(.failure(error: error))
                }
            }else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("faceQualityDetect faceImage nil")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
           
        }
    }
    
    
    // MARK: - register
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

        registerInstanceAsyncHandler(for: "acquireFaceImage", pluginType: Self.self, paramsType: OpenPluginAcquireFaceImageRequest.self, resultType: OpenPluginAcquireFaceImageResponse.self) { (this, params, context, callback) in
            
            this.startAcquireFaceImage(params: params, context:context, callback: callback)
        }
  
    }
    
}
