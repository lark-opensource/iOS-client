//
//  OpenBasePluginNFC.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/28.
//

import CoreNFC
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPPluginManagerAdapter
import LarkSetting
import LarkContainer

import TTMicroApp

// MARK: - OpenPluginNfc register API

final class OpenPluginNfc: OpenBasePlugin {
    private lazy var nfcSession: NfcSessionAdapter = {
        var result = NfcSessionAdapterFactory.defaultSessionAdapter
        result.delegate = self
        return result
    }()
    private var pauseInterruptionUniqueID: BDPUniqueID?
    private var fireNfcFoundDeviceContext: OpenAPIContext?
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAPI()
    }
    
    deinit {
        if let uniqueID = pauseInterruptionUniqueID {
            fireNfcFoundDeviceContext?.apiTrace.warn("nfcSessionAdapter didInvalidate! resumeInterruption for uuid: \(uniqueID)")
            /// NFC 扫描界面消失以后恢复 API打断机制
            BDPAPIInterruptionManager.shared().resumeInterruption(for: uniqueID)
        }
    }
}

// MARK: -  retister API

extension OpenPluginNfc {
    enum APIName: String {
        /// 开始扫描NFC标签
        case nfcStartDiscovery
        /// 停止扫描NFC标签
        case nfcStopDiscovery
        /// on方法 native -> JS
        case nfcFoundDevice
        /// 标签建立连接
        case nfcConnect
        /// nfc关闭连接
        case nfcClose
        /// nfc原生命令
        case nfcTransceive
//        /// 写ndef命令
//        case writeNdefMessage
//        /// 写ndef命令
//        case readNdefMessage
    }
   
    private func registerAPI() {
        registerInstanceAsyncHandlerGadget(for: APIName.nfcStartDiscovery.rawValue, pluginType: Self.self,
                             paramsType: OpenAPIBaseParams.self,
                             resultType: OpenAPIBaseResult.self) { this, params, context, gadgetContext, callback in
            context.apiTrace.info("nfcStartDiscovery API call start")
            this.nfcStartDiscovery(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("nfcStartDiscovery API call end")
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.nfcStopDiscovery.rawValue, pluginType: Self.self,
                             paramsType: OpenAPIBaseParams.self,
                             resultType: OpenAPIBaseResult.self) { this, params, context, gadgetContext, callback in
            context.apiTrace.info("nfcStopDiscovery API call start")
            this.nfcStopDiscovery(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("nfcStopDiscovery API call end")
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.nfcConnect.rawValue, pluginType: Self.self,
                             paramsType: OpenPluginNfcConnectRequest.self,
                             resultType: OpenAPIBaseResult.self) { this, params, context, gadgetContext, callback in
            
            context.apiTrace.info("nfcConnect API call start")
            this.nfcConnect(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("nfcConnect API call end")
        }
        
        registerInstanceAsyncHandlerGadget(for: APIName.nfcClose.rawValue, pluginType: Self.self,
                             paramsType: OpenPluginNfcCloseRequest.self,
                             resultType: OpenAPIBaseResult.self) { this, params, context, gadgetContext, callback in
            
            context.apiTrace.info("nfcClose API call start")
            this.nfcClose(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("nfcClose API call end")
        }
        
       
        
        registerInstanceAsyncHandlerGadget(for: APIName.nfcTransceive.rawValue, pluginType: Self.self,
                             paramsType: OpenPluginNfcTransceiveRequest.self,
                             resultType: OpenPluginNfcTransceiveResponse.self) { this, params, context, gadgetContext, callback in
            context.apiTrace.info("nfcTransceive API call start")
            this.transceive(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("nfcTransceive API call end")
        }
    }
}

// MARK: - OpenPluginNfc API Implementation

extension OpenPluginNfc {
    func nfcStartDiscovery(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        do {
            fireNfcFoundDeviceContext = context
            try nfcSession.startPolling()
            context.apiTrace.error("nfcStartDiscovery callback success")
            callback(.success(data: nil))
        } catch {
            let resultError = error.generateOpenAPINfcErrno()
            context.apiTrace.error("nfcStopDiscovery callback rawError:\(error), resultError:\(resultError)")
            callback(.failure(error: resultError))
        }
    }

    func nfcStopDiscovery(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        do {
            try nfcSession.stopPolling()
            context.apiTrace.error("nfcStopDiscovery callback success")
            callback(.success(data: nil))
        } catch {
            let resultError = error.generateOpenAPINfcErrno()
            context.apiTrace.error("nfcStopDiscovery callback rawError:\(error), resultError:\(resultError)")
            callback(.failure(error: resultError))
        }
    }
    
    func nfcConnect(
        params: OpenPluginNfcConnectRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        context.apiTrace.info("nfcConnect params \(params.tech)")
        do {
            try nfcSession.getTagAdapter(tech: params.tech)
                .connect(handler: { error in
                    if let resultError = error?.generateOpenAPINfcErrno() {
                        context.apiTrace.error("nfcConnect rawError:\(error), resultError:\(resultError)")
                        callback(.failure(error: resultError))
                        return
                    }
                    context.apiTrace.info("nfcConnect success")
                    callback(.success(data: nil))
                })
        } catch {
            let resultError = error.generateOpenAPINfcErrno()
            context.apiTrace.error("nfcConnect callback throw error! rawError:\(error), resultError:\(resultError)")
            callback(.failure(error: resultError))
        }
    }
    
    func nfcClose(
        params: OpenPluginNfcCloseRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        do {
            try nfcSession.getTagAdapter(tech: params.tech).close()
            context.apiTrace.info("nfcClose success")
            callback(.success(data: nil))
        } catch {
            let resultError = error.generateOpenAPINfcErrno()
            context.apiTrace.error("nfcClose callback throw error! rawError:\(error), resultError:\(resultError)")
            callback(.failure(error: resultError))
        }
    }

    func transceive(
        params: OpenPluginNfcTransceiveRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginNfcTransceiveResponse>) -> Void)
    {
        do {
            context.apiTrace.info("transceive commandData: \(params.data)")
            try nfcSession.getTagAdapter(tech: params.tech)
                .transceive(data: params.data, success: { data in
                    context.apiTrace.info("transceive callbackSuccess. result: \(data?.bytes)")
                    callback(.success(data: OpenPluginNfcTransceiveResponse(data: data)))
                }, failure: { error in
                    let resultError = error.generateOpenAPINfcErrno()
                    context.apiTrace.error("transceive callback rawError:\(error), resultError:\(resultError)")
                    callback(.failure(error: resultError))
                })
        } catch {
            let resultError = error.generateOpenAPINfcErrno()
            context.apiTrace.error("transceive callback throw error! rawError:\(error), resultError:\(resultError)")
            callback(.failure(error: resultError))
        }
    }
    
    /// 发送nfcFoundDevice
    private func fireNfcFoundDeviceEvent(detectedTag: DetectedTag, context: OpenAPIContext) {
        do {
            
            let message = try detectedTag.fireEventParams()
            let fireEvent = try OpenAPIFireEventParams(event: APIName.nfcFoundDevice.rawValue,
                                                       sourceID: NSNotFound,
                                                       data: message,
                                                       preCheckType: .none,
                                                       sceneType: .normal)
            if case let .failure(error) = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context) {
                context.apiTrace.error("fire nfcFoundDevice syncCall failed: \(error) ")
            } else {
                context.apiTrace.info("fire nfcFoundDevice success, errorMessage: \(detectedTag)")
            }
        } catch {
            context.apiTrace.error("syncCall fireEvent nfcFoundDevice error: \(error)")
        }
    }
    
}

// MARK: - NfcSessionAdapterDelegate
extension OpenPluginNfc: NfcSessionAdapterDelegate {
    func nfcSessionAdapter(_ session: NfcSessionAdapter, didDetectTag: DetectedTag) {
        guard let context = fireNfcFoundDeviceContext else {
            return
        }
        self.fireNfcFoundDeviceEvent(detectedTag: didDetectTag, context: context)
    }
    
    func nfcSeessionAdapterDidBecomeActive(_ session: NfcSessionAdapter) {
        /// 兜底FG 防止此逻辑有较大影响
        guard !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.nfc.pause_interrupt.disable") else {
            return
        }
        guard let context = fireNfcFoundDeviceContext, let uniqueID = context.uniqueID else {
            return
        }
        /// NFC开始扫描以后 应用会收到resignActive的通知，应用此时无法交互，此时小程序JSBridge会处于interrupt 状态，所有API调用都会被暂停。
        /// 所以在这里加入暂停APIInterruption机制保证其余API可以正常调用
        context.apiTrace.warn("nfcSessionAdapter didBecomeActive! pauseInterruption for uuid: \(uniqueID)")
        pauseInterruptionUniqueID = uniqueID
        BDPAPIInterruptionManager.shared().pauseInterruption(for: uniqueID)
    }
    
    func nfcSessionAdapter(_ session: NfcSessionAdapter, didInvalidateWithError error: Error) {
        /// 兜底FG 防止此逻辑有较大影响
        guard !userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.api.nfc.pause_interrupt.disable") else {
            return
        }
        guard let context = fireNfcFoundDeviceContext, let uniqueID = context.uniqueID else {
            return
        }
        pauseInterruptionUniqueID = nil
        context.apiTrace.warn("nfcSessionAdapter didInvalidate! resumeInterruption for uuid: \(uniqueID)")
        /// NFC 扫描界面消失以后恢复 API打断机制
        BDPAPIInterruptionManager.shared().resumeInterruption(for: uniqueID)
    }
}

/// DetectedTag 转换为 native -> js `nfcFoundDevice` event 的参数
/// 参看 https://open.feishu.cn/document/uYjL24iN/uUDN4YjL1QDO24SN0gjN
private extension DetectedTag {
    func fireEventParams() throws -> [AnyHashable: Any] {
        var result = [AnyHashable: Any]()
        result["techs"] = try techs.map { try OPNfcTechnology.transform(from: $0).rawValue }
        /// 对齐线上，本意是要放ndef的消息，真实情况是这里无法获取。为了防止线上有用户以来此处，所以返回一个空数组
        result["message"] = []
        result["uid"] = identifier
        return result
    }
}

private extension Error {
    func generateOpenAPINfcErrno() -> OpenAPIError {
        let result: OpenAPIError
        if let nfcError = self as? NFCAdapterError {
            result = OpenAPIError(errno: nfcError.opErrno)
        } else if let readerError = self as? NFCReaderError,
                  let code = NFCReaderError.Code(rawValue: readerError.errorCode)
        {
            result = OpenAPIError(errno: code.opErrno)
        } else {
            result = OpenAPIError(errno: OpenAPICommonErrno.unknown)
        }
        result.setMonitorMessage("\(self)")
        return result
    }
}

private extension NFCReaderError.Code {
    var opErrno: OpenAPINfcErrno {
        switch self {
        case .readerErrorUnsupportedFeature:
            return .techFuncNotSupport
        case .readerErrorSecurityViolation:
            return .transceiveError
        case .readerErrorInvalidParameter:
            return .transceiveError
        case .readerErrorInvalidParameterLength:
            return .transceiveError
        case .readerErrorParameterOutOfBound:
            return .transceiveError
        case .readerErrorRadioDisabled:
            return .notOpened
        case .readerTransceiveErrorTagConnectionLost:
            return .serviceDead
        case .readerTransceiveErrorRetryExceeded:
            return .transceiveError
        case .readerTransceiveErrorTagResponseError:
            return .transceiveError
        case .readerTransceiveErrorSessionInvalidated:
            return .serviceDead
        case .readerTransceiveErrorTagNotConnected:
            return .techNotConnected
        case .readerTransceiveErrorPacketTooLong:
            return .transceiveError
        case .readerSessionInvalidationErrorUserCanceled:
            return .serviceDead
        case .readerSessionInvalidationErrorSessionTimeout:
            return .serviceDead
        case .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
            return .serviceDead
        case .readerSessionInvalidationErrorSystemIsBusy:
            return .serviceDead
        case .readerSessionInvalidationErrorFirstNDEFTagRead:
            return .serviceDead
        case .tagCommandConfigurationErrorInvalidParameters:
            return .transceiveError
        case .ndefReaderSessionErrorTagNotWritable:
            return .techFuncNotSupport
        case .ndefReaderSessionErrorTagUpdateFailure:
            return .transceiveError
        case .ndefReaderSessionErrorTagSizeTooSmall:
            return .transceiveError
        case .ndefReaderSessionErrorZeroLengthMessage:
            return .transceiveError
        }
    }
}

private extension NFCAdapterError {
    var opErrno: OpenAPINfcErrno {
        switch self {
        case .isDiscovering:
            return .isDiscovering
        case .techAlreadyConnected:
            return .techAlreadyConnected
        case .techNotConnected:
            return .techNotConnected
        case .techNotDiscovered:
            return .techNotDiscovered
        case .techNotSupport:
            return .techNotSupport
        case .techFuncNotSupport:
            return .techFuncNotSupport
        case .dataIsNull:
            return .dataIsNull
        case .arrayBufferEmpty:
            return .arrayBufferEmpty
        case .base64ValueEmpty:
            return .base64ValueEmpty
        case .base64DecodeError:
            return .base64DecodeError
        case .transceiveError:
            return .transceiveError
        case .typeEmpty:
            return .typeEmpty
        case .serviceDead:
            return .serviceDead
        case .notAvailable:
            return .notAvailable
        case .notOpened:
            return .notOpened
        }
    }
}

private extension NfcSessionAdapter {
    func getTagAdapter(tech: OPNfcTechnology) throws -> any NfcTagAdapter {
        return try getTag(tech: try NfcTechnology.transform(from: tech))
    }
}

private extension OPNfcTechnology {
    static func transform(from tech: NfcTechnology) throws -> OPNfcTechnology {
        switch tech {
        case .nfcA:
            return .nfcA
        case .ndef:
            return .ndef
        }
    }
}

private extension NfcTechnology {
    static func transform(from tech: OPNfcTechnology) throws -> NfcTechnology {
        switch tech {
        case .nfcA:
            return .nfcA
        case .ndef:
            return .ndef
        }
    }
}
