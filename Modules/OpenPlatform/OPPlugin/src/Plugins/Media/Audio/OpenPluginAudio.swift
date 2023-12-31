//
//  OpenPluginAudio.swift
//  OPPlugin
//
//  Created by yi on 2021/6/8.
//

import Foundation
import TTMicroApp
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPFoundation
import TTVideoEngine
import LarkContainer

final class OpenPluginAudio: OpenBasePlugin {

    var lastestAudioID = 0
    var playerDict: [AnyHashable: Any] = [:]
    var streamingRecorder: BDPStreamingAudioRecorder?

    func createAudioInstance(params: OpenAPIBaseParams, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPICreateAudioInstanceResult> {
        context.apiTrace.info("createAudioInstance call begin")
        lastestAudioID = lastestAudioID + 1
        context.apiTrace.info("createAudioInstance call end \(lastestAudioID)")
        return .success(data: OpenAPICreateAudioInstanceResult(audioId: lastestAudioID))
    }

    func destroyAudioInstance(params: OpenAPIAudioInstanceParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("destroyAudioInstance call begin")
        playerDict.removeValue(forKey: params.audioId)
        callback(.success(data: nil))
        context.apiTrace.info("destroyAudioInstance call end")
    }

    func operateAudio(params: OpenAPIOperateAudioParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("operateAudio call begin")
        let currentTime = params.currentTime.doubleValue
        guard let player = playerDict[params.audioId] as? BDPAudioPlayer else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("player is nil")
            callback(.failure(error: error))
            return
        }

        if params.operationType == "seek" {
            /// player seek 的单位为 seconds，前端传递的是 millisecond
            player.seek(CGFloat(currentTime) / 1000) { (success) in
                if success {
                    callback(.success(data: nil))
                    return
                }
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setOuterMessage("operateAudio operation `seek` failed.")
                    .setMonitorMessage("operateAudio operation `seek` failed.")
                callback(.failure(error: error))
            }
            return
        } else if params.operationType == "play" {
            player.play { success, errorInfo in
                if success {
                    callback(.success(data: nil))
                } else {
                    let error = OpenAPIError(errno: OpenAPIInnerAudioErrno.innerAudioHigherPriorityFailed(errorString: errorInfo ?? ""))
                    callback(.failure(error: error))
                }
            }
            return
        } else if params.operationType == "pause" {
            if player.pause() {
                callback(.success(data: nil))
                return
            }
        } else if params.operationType == "stop" {
            if player.stop() {
                callback(.success(data: nil))
                return
            }
        }
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setErrno(OpenAPICommonErrno.unknown)
            .setOuterMessage("operateAudio operation is invalid")
            .setMonitorMessage("operateAudio operation is invalid")
        callback(.failure(error: error))
        context.apiTrace.info("operateAudio call end")
    }

    func getAudioState(params: OpenAPIAudioInstanceParams, context: OpenAPIContext) -> OpenAPIBaseResponse<OpenAPIGetAudioStateResult> {
        context.apiTrace.info("getAudioState call begin")
        if let player = playerDict[params.audioId] as? BDPAudioPlayer, let state = player.getAudioState() as? [AnyHashable: Any] {
            context.apiTrace.info("getAudioState call end")
            return .success(data: OpenAPIGetAudioStateResult(state: state))
        } else {
            context.apiTrace.info("getAudioState call end")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
            return .failure(error: error)
        }
    }

    func setAudioState(
        params: OpenAPISetAudioStateParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
            standardSetAudioState(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
    }

    /// 沙箱文件操作标准化收敛改造，原来逻辑乱到没法下手，整体还要涉及到同异步改造，还是重写一份吧，但结果上还是等价改造。
    ///     1. 调整 API 结构为更加合理的顺序
    ///     2. 清理 warnings
    ///     3. 去除重复/不必要的日志，补充缺失的 monitor message
    ///     4. 文件相关操作使用标准化的沙箱文件操作，包括 BDPAudioModel 的初始化，package 路径的统一处理等。
    ///     5. JSSDK 同步调用问题改造完成后，考虑到后续加解密场景下的耗时，需要将 API 实现改造为真异步。
    private func standardSetAudioState(
        params: OpenAPISetAudioStateParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("resolve common failed")
            callback(.failure(error: error))
            return
        }

        /// 初始化 model 需要读取文件（可能有解密），为避免耗时需要在异步线程读取
        DispatchQueue.global().async {
            /// 初始化 model
            var model: BDPAudioModel
            do {
                model = try BDPAudioModel(dictionary: params.data, uniqueID: gadgetContext.uniqueID)
            } catch {
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("init model failed, error: \(error.localizedDescription)")
                callback(.failure(error: apiError))
                return
            }

            /// 检查 src
            guard model.src.hasPrefix("file:") || common.auth.checkURL(model.src, authType: .request) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setOuterMessage("audio set fail, src is not valid domains,src == \(model.src), audioid == \(params.audioId)")
                callback(.failure(error: error))
                return
            }

            DispatchQueue.main.async { [weak self] in
                self?.setAudioStateModel(
                    params: params,
                    context: context,
                    callback: callback,
                    gadgetContext: gadgetContext,
                    model: model
                )
            }
        }
    }

    /// 获取当前 player（如果没有则生成，与老逻辑一致），设置 player 的 model。
    /// player 相关的内容需要再主线程调用
    private func setAudioStateModel(
        params: OpenAPISetAudioStateParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void,
        gadgetContext: GadgetAPIContext,
        model: BDPAudioModel
    ) {
        /// 获取 player
        var player = playerDict[params.audioId] as? BDPAudioPlayer
        if player == nil {
            context.apiTrace.info("setAudioState set player")
            let innerPlayer = EMAAudioPlayer(uniqueID: gadgetContext.uniqueID)
            Self.setCallback(player: innerPlayer, context: context)
            innerPlayer.audioID = params.audioId
            playerDict[params.audioId] = innerPlayer
            player = innerPlayer
        }

        guard let player = player else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("player is nil")
            callback(.failure(error: error))
            return
        }

        /// 设置 state
        player.setAudioState(model)
        callback(.success(data: nil))
    }
    
    private class func setCallback(player: EMAAudioPlayer, context: OpenAPIContext) {
        player.fireEvent({ (event, sourceID, data) in
            do {
                guard let event = event, let data = data else { return }
                let fireEvent = try OpenAPIFireEventParams(event: event, data: data, preCheckType: .none)
                _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            } catch {
                context.apiTrace.error("setAudioState api, fire Event fail")
            }
        })
        player.onError { player, error in
            guard let error = error else {
                return
            }
            let audioErrno = error.toAudioErrno()
            let errno = OpenAPIError(errno: audioErrno)
            var data = errno.errnoInfo
            data["audioId"] = player.audioID
            data["state"] = "error"
            do {
                let fireEvent = try OpenAPIFireEventParams(event: "onAudioStateChange", data: data, preCheckType: .none)
                context.apiTrace.info("fire event onAudioStateChange params \(data), player errorCode: \(error._code), audioErrno: \(audioErrno.rawValue)")
                _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            } catch let error {
                context.apiTrace.info("fire event onAudioStateChange params error \(error)")
            }
        }
    }

    func operateRecorder(params: OpenAPIOperateRecorderParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("operateRecorder call begin with \(params.data)")
        if streamingRecorder == nil {
            streamingRecorder = BDPStreamingAudioRecorder.shareInstance()
        }
        guard let recorder = streamingRecorder else {
            context.apiTrace.error("recorder is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("recorder is nil")
            callback(.failure(error: error))
            return
        }
        recorder.uniqueID = gadgetContext.uniqueID;
        recorder.stateChangeBlock = { data in
            do {
                let fireEvent = try OpenAPIFireEventParams(event: "onRecorderStateChange", data: data, preCheckType: .none)
                let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            } catch {
                context.apiTrace.error("operateRecorder api, fire Event fail")
            }
        }
        recorder.operateState(params.data) {
            errCode, errMsg in
            if errCode == .success {
                callback(.success(data: nil))
            } else if errCode == .startLockMutexFail {
                let error = OpenAPIError(errno: OpenAPIRecorderErrno.startRecordHigherPriorityFailed(errorString: errMsg ?? ""))
                callback(.failure(error: error))
            } else if errCode == .resumeLockMutexFail {
                let error = OpenAPIError(errno: OpenAPIRecorderErrno.resumeRecordHigherPriorityFailed(errorString: errMsg ?? ""))
                callback(.failure(error: error))
            } else {
                let apiType = params.data["operationType"] as? String ?? ""
                let error = OpenAPIError(code: GetRecorderManagerAPIErrorCode.typeInvalid)
                    .setErrno(OpenAPIRecorderErrno.recordOperateFailed(apiType: apiType, errString: errMsg ?? ""))
                callback(.failure(error: error))
            }
            context.apiTrace.info("operateRecorder call end")
        }
    }
    
    deinit {
        if let streamingRecorder {
            streamingRecorder.forceStop()
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceSyncHandler(for: "createAudioInstance", pluginType: Self.self, resultType: OpenAPICreateAudioInstanceResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPICreateAudioInstanceResult> in
            
            return this.createAudioInstance(params: params, context: context)
        }

        registerInstanceAsyncHandler(for: "destroyAudioInstance", pluginType: Self.self, paramsType: OpenAPIAudioInstanceParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.destroyAudioInstance(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "operateAudio", pluginType: Self.self, paramsType: OpenAPIOperateAudioParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.operateAudio(params: params, context: context, callback: callback)
        }

        registerInstanceSyncHandler(for: "getAudioState", pluginType: Self.self, paramsType: OpenAPIAudioInstanceParams.self, resultType: OpenAPIGetAudioStateResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIGetAudioStateResult> in
            
            return this.getAudioState(params: params, context: context)
        }

        registerInstanceAsyncHandlerGadget(for: "setAudioState", pluginType: Self.self, paramsType: OpenAPISetAudioStateParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.setAudioState(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "operateRecorder", pluginType: Self.self, paramsType: OpenAPIOperateRecorderParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.operateRecorder(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}


// MARK: - TTVideoEngine Code
// @see as TTPlayerSDK/av_error.h, AVError.ErrorType
fileprivate extension Error {
    // 私有错误类型映射，和 Android 保持对齐
    // https://bytedance.feishu.cn/docx/Y2T3dJDFSoxiTSx0qW3cVEUdnRk
    func toAudioErrno() -> OpenAPIInnerAudioErrno {
        var audioErrno: OpenAPIInnerAudioErrno
        if isTTVideoEngineSrcInvalid() {
            audioErrno = .innerAudioSrcInvalid
        } else if isTTVideoEngineRequestError() {
            audioErrno = .innerAudioRequestFailed
        } else if isTTVideoEngineDNSError() {
            audioErrno = .innerAudioDnsLookupFailed
        } else if isTTVideoEngineError() {
            audioErrno = .innerAudioAudioEngineError
        } else {
            audioErrno = .innerAudioNetworkError
        }
        return audioErrno
    }
}
