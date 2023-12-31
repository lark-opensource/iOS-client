//
//  OpenPluginVideo.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/23.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import UniverseDesignToast
import OPPluginManagerAdapter
import OPPluginBiz
import OPFoundation
import LarkContainer

// 按照lilun.ios的建议修改，改完就能build 通过了。本人未修改到这里的任何相关逻辑，不承担任何咨询Oncall事宜及相关责任，仅帮助CI通过
final class OpenPluginVideoAPI: OpenBasePlugin {
    @InjectedSafeLazy var mediaProvider: OpenPluginMediaProxy

    private func genVideoSourceType(params: OpenAPIChooseVideoParams) -> BDPVideoSourceType {
        var videoSourceType: BDPVideoSourceType = .init(rawValue: 0)
        if params.sourceType.contains("album") {
            videoSourceType.formUnion(.album)
        }
        if params.sourceType.contains("camera") {
            videoSourceType.formUnion(.camera)
        }
        if videoSourceType == .init(rawValue: 0) {
            videoSourceType.formUnion(.album)
            videoSourceType.formUnion(.camera)
        }
        return videoSourceType
    }

    func chooseVideo(
        with inParams: OpenAPIChooseVideoParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIChooseVideoResult>) -> Void)
    {
        /// 通用错误回调方法
        let errorCallBack: ((String, OpenAPICommonErrorCode, OpenAPIErrnoProtocol) -> Void) = { (errorMsg, code, errno) in
            let error = OpenAPIError(code: code)
                .setMonitorMessage(errorMsg)
                .setErrno(errno)
            callback(.failure(error: error))
            context.apiTrace.error("chooseVideo fail \(errorMsg) \(code)")
        }
        
        
        context.apiTrace.info("choose video start \(inParams.sourceType)")
        var videoSourceType: BDPVideoSourceType = genVideoSourceType(params: inParams)
        context.apiTrace.info("choose video videoSourceType \(videoSourceType)")
        /// 输入参数
        context.apiTrace.info("choose video inParams \(inParams.maxDuration) \(inParams.compressed)")
        var params = inParams

        do {
            let moudleManager = BDPModuleManager(of: gadgetContext.uniqueID.appType)
            guard let storage = moudleManager.resolveModule(with: BDPStorageModuleProtocol.self) as? BDPStorageModuleProtocol else {
                let errorMsg = "can't find storage"
                errorCallBack(errorMsg, .unknown, OpenAPICommonErrno.internalError)
                return
            }
            guard let sandbox = OPUnsafeObject(storage.minimalSandbox(with: gadgetContext.uniqueID)) as? BDPMinimalSandboxProtocol else {
                let errorMsg = "can't find sandbox"
                errorCallBack(errorMsg, .unknown, OpenAPICommonErrno.internalError)
                return
            }
            guard let controller = gadgetContext.controller,
                  let fromVC = OPNavigatorHelper.topMostAppController(window: controller.view.window) else {
                let errorMsg = "can't find top view controller"
                errorCallBack(errorMsg, .unknown, OpenAPICommonErrno.unknown)
                return
            }
            var path: String
            guard let randomPath = FileSystemUtils.generateRandomPrivateTmpPath(with: sandbox) else {
                errorCallBack("can't generate random private temp path", .unknown, OpenAPICommonErrno.unknown)
                return
            }
            path = URL(fileURLWithPath: randomPath).absoluteString


            guard let model = BDPChooseVideoParam(maxDuration: TimeInterval(params.maxDuration),
                                                  sourceType: videoSourceType,
                                                  from: controller,
                                                  compressed: params.compressed,
                                                  outputFilePathWithoutExtention: path) else {
                let errorMsg = "param error"
                context.apiTrace.error("param init error, vc: \(controller), path: \(path)")
                errorCallBack(errorMsg, .unknown, OpenAPICommonErrno.unknown)
                return
            }
            
            EMAImagePicker.pickVideo(param: model, controller: model.fromController) { (result) in
                guard result.code == .success else {
                    context.apiTrace.error("chooseVideo failed, error code: \(result.code)")
                    var _error: OpenAPIError?
                    if result.code == .timeLimitExceed {
                        _error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("over the maxDuration")
                            .setErrno(OpenAPIVideoErrno.OverMaxDuration)
                    } else if result.code == .cancel {
                        _error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setOuterMessage("user cancel")
                            .setErrno(OpenAPIVideoErrno.UserCanceled)
                    } else {
                        _error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("intenal err: \(result.code)")
                            .setErrno(OpenAPICommonErrno.unknown)
                    }
                    guard let error = _error else {
                        context.apiTrace.error("chooseVideo failed, code should not run here!!!")
                        //这块不会走到，但是为了代码的严谨性，也加上callBack
                        let error = OpenAPIError(errno: OpenAPICommonErrno.unknown)
                        callback(.failure(error: error))
                        return
                    }
                    callback(.failure(error: error))
                    return
                }
                
                guard let filePath = result.filePath else {
                    context.apiTrace.error("chooseVideo failed, filePath is nil")
                    errorCallBack("intenal err: filePath is nil", .unknown, OpenAPICommonErrno.unknown)
                    return
                }
                var _ttpath: String?

                    do {
                        let randomTemp = FileObject.generateRandomTTFile(type: .temp, fileExtension: (filePath as NSString).pathExtension)
                        let fsContext = FileSystem.Context.init(uniqueId: gadgetContext.uniqueID, trace: context.apiTrace, tag: "chooseVideo")
                        try FileSystemCompatible.moveSystemFile(filePath, to: randomTemp, context: fsContext)
                        _ttpath = randomTemp.rawValue
                    } catch let error as FileSystemError {
                        context.apiTrace.error("copy system file to temp error", error: error)
                    } catch {
                        context.apiTrace.error("copy system file to temp unknown error", error: error)
                    }
                guard let ttPath = _ttpath else {
                    context.apiTrace.error("chooseVideo failed, ttPath is nil")
                    errorCallBack("intenal err: ttPath is nil", .unknown, OpenAPICommonErrno.unknown)
                    return
                }
                let response = OpenAPIChooseVideoResult(tempFilePath: ttPath,
                                                        duration: result.duration,
                                                        size: result.size,
                                                        height: result.height,
                                                        width: result.width)
                callback(.success(data: response))
            }
            
        } catch {
            let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(error.localizedDescription)
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: apiError))
            context.apiTrace.error(error.localizedDescription)
        }
    }
    func saveVideoToPhotosAlbum(
        with params: OpenAPISaveVideoParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        standardSaveVideoToPhotosAlbum(with: params, context: context, gadgetContext:gadgetContext, callback: callback)
    }
    private func standardSaveVideoToPhotosAlbum(
        with params: OpenAPISaveVideoParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        /// 开启加解密后，不允许保存
        if FSCrypto.isCryptoInterceptEnable(type: .apiSaveVideoToPhotosAlbum) {
            DispatchQueue.main.async {
                if let view = context.controller?.view {
                    UDToast.showTips(
                        with: BundleI18n.OPPlugin.OpenPlatform_Workplace_SafetyWarning_SaveFailed,
                        on: view
                    )
                } else {
                    context.apiTrace.error("cannot find controller view to show crypto tips")
                }
            }
            let apiError = OpenAPIError(code: OpenAPIFileSystemErrorCode.securityPermissionDenied)
                .setErrno(OpenAPIVideoErrno.SecurityPermissionDenied)
            callback(.failure(error: apiError))
            return
        }

        do {
            let file = try FileObject(rawValue: params.filePath)
            let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID, trace: context.apiTrace, tag: "saveVideoToPhotosAlbum")
            let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)
            mediaProvider.saveVideoToPhotosAlbum(tokenIdentifier: OPSensitivityEntryToken.OpenPluginImage_saveVideoToPhotosAlbum_creationRequestForAsset.stringValue, fileURL: URL(fileURLWithPath: systemFilePath)) { success, error in
                context.apiTrace.info("saveVideoToPhotosAlbum result success = \(success), error = \(error?.localizedDescription ?? "")")
                guard success else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("BDPSaveVideoToPhotosAlbum failed, error: \(error?.localizedDescription ?? "")")
                        .setErrno(OpenAPIVideoErrno.UnableToSaveVideo)
                    callback(.failure(error: error))
                    return
                }
                callback(.success(data: nil))
            }
        } catch let error as FileSystemError {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("saveVideoToPhotosAlbum get system file failed, error: \(error.localizedDescription)")
                .setErrno(error.fileCommonErrno)
            callback(.failure(error: error))
        } catch {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("saveVideoToPhotosAlbum get system file unknwon failed, error: \(error.localizedDescription)")
                .setErrno(OpenAPICommonErrno.unknown)
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "chooseVideo", pluginType: Self.self,
                             paramsType: OpenAPIChooseVideoParams.self,
                             resultType: OpenAPIChooseVideoResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.chooseVideo(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "saveVideoToPhotosAlbum", pluginType: Self.self,
                             paramsType: OpenAPISaveVideoParams.self,
                             resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.saveVideoToPhotosAlbum(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}


