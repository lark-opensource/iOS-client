// 支持 Forms API 在 Web 容器下运行

import LarkContainer
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkQuickLaunchInterface
import LarkTab
import LKCommonsLogging
import OPFoundation
import SKFoundation
import WebBrowser

// MARK: - API Register

/// 收集表/表单分享页 开放平台 API 插件
final class FormsAPIPlugin: OpenBasePlugin {
    
    static let logger = Logger.formsWebLog(FormsAPIPlugin.self, category: "FormsAPIPlugin")
    
    required init(resolver: UserResolver) {
        
        super.init(resolver: resolver)
        
        Self.logger.info("FormsAPIPlugin init")
        
        registerConfig()
        
        registerAttachment()
        
        registerDevice()
        
        registerLocation()
        
        registerPerformance()
        
    }
    
    deinit {
        Self.logger.info("FormsAPIPlugin deinit")
    }
    
    /// 注册配置 API
    private func registerConfig() {
        
        registerAsyncHandler(
            for: "biz.bitable.formConfiguration",
            resultType: FormsConfigurationResult.self
        ) { (_, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let code = -1
                let msg = "gadgetContext is nil"
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(msg)
                    .setOuterMessage(msg)
                    .setOuterCode(code)
                context.apiTrace.error(msg)
                callback(.failure(error: error))
                return
            }
            guard let vc = apiContext.controller as? WebBrowser else {
                let code = -2
                let msg = "apiContext.controller is nil"
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(msg)
                    .setOuterMessage(msg)
                    .setOuterCode(code)
                context.apiTrace.error(msg)
                callback(.failure(error: error))
                return
            }
            guard FormsConfiguration.checkHostFormsValid(url: vc.browserURL) else {
                let code = -999997
                let msg = "no permission for \(vc.browserURL)"
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage(msg)
                    .setOuterMessage(msg)
                    .setOuterCode(code)
                context.apiTrace.error(msg)
                callback(.failure(error: error))
                return
            }
            callback(.success(data: FormsConfigurationResult()))
        }
        
    }
    
    /// 注册附件 API
    private func registerAttachment() {
        
        registerAsyncHandler(
            for: "biz.bitable.chooseAttachment",
            paramsType: FormsChooseAttachmentParams.self,
            resultType: BitableChooseAttachmentResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                let mode = FormsChooseAttachmentMode(rawValue: params.mode) ?? .default
                form
                    .0
                    .formsAttachment
                    .chooseAttachment(
                        vc: form.1,
                        params: params
                    ) { infos in
                        callback(.success(data: BitableChooseAttachmentResult(infos: infos)))
                    } failure: { error in
                        callback(.failure(error: error))
                    } cancel: {
                        let code = -3
                        let msg = "user cancel chooseAttachment"
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage(msg)
                            .setOuterMessage(msg)
                            .setOuterCode(code)
                        context.apiTrace.error(msg)
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.checkAttachmentValid",
            paramsType: FormsCheckAttachmentParams.self,
            resultType: FormsCheckAttachmentResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsAttachment
                    .checkAttachment(
                        params: params
                    ) { infos in
                        callback(.success(data: FormsCheckAttachmentResult(infos: infos)))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.previewAttachment",
            paramsType: FormsPreviewAttachmentParams.self,
            resultType: OpenAPIBaseResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsAttachment
                    .previewAttachment(
                        vc: form.1,
                        params: params
                    ) {
                        callback(.success(data: nil))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.deleteAttachment",
            paramsType: FormsDeleteAttachmentParams.self,
            resultType: OpenAPIBaseResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsAttachment
                    .deleteAttachment(
                        params: params
                    ) {
                        callback(.success(data: nil))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.uploadAttachment",
            paramsType: FormsUploadAttachmentParams.self,
            resultType: FormsUploadAttachmentResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsAttachment
                    .uploadAttachment(
                        params: params
                    ) { token in
                        callback(.success(data: FormsUploadAttachmentResult(token: token)))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
    }
    
    /// 注册设备相关 API
    private func registerDevice() {
        
        func registerScan(name: String) {
            
            registerAsyncHandler(
                for: name,
                resultType: FormsScanCodeResult.self
            ) { (_, context, callback) in
                switch self.formsContext(context: context) {
                case .success(let form):
                    form
                        .0
                        .formsDevice
                        .scanCode(
                            vc: form.1
                        ) { result in
                            callback(.success(data: result))
                        } cancel: {
                            let code = -1
                            let msg = "user cancel scanCode"
                            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(msg)
                                .setOuterMessage(msg)
                                .setOuterCode(code)
                            context.apiTrace.error(msg)
                            callback(.failure(error: error))
                        }
                case .failure(let error):
                    callback(.failure(error: error))
                }
            }
            
        }
        
        registerScan(name: "biz.forms.scanCode")
        registerScan(name: "biz.util.scan") // 独立容器后不会兼容开放平台老 biz 系列 API，在此做个兼容
        
    }

    /// 注册定位/地图 API
    private func registerLocation() {
        
        registerAsyncHandler(
            for: "biz.bitable.getLocation",
            paramsType: FormsGetLocationParams.self,
            resultType: FormsGetLocationResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsLocation
                    .getLocation(
                        params: params
                    ) { result in
                        callback(.success(data: result))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.reverseGeocodeLocation",
            paramsType: FormsReverseGeocodeLocationParams.self,
            resultType: FormsReverseGeocodeLocationResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsLocation
                    .reverseGeocodeLocation(
                        params: params
                    ) { result in
                        callback(.success(data: result))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.openLocation",
            paramsType: FormsOpenLocationParams.self,
            resultType: OpenAPIBaseResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsLocation
                    .openLocation(
                        vc: form.1,
                        params: params
                    ) {
                        callback(.success(data: nil))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.bitable.chooseLocation",
            resultType: FormsChooseLocationResult.self
        ) { [weak self] (_, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsLocation
                    .chooseLocation(
                        vc: form.1
                    ) { result in
                        callback(.success(data: result))
                    } failure: { error in
                        callback(.failure(error: error))
                    }
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
    }
    
    /// 注册性能API
    private func registerPerformance() {
        
        registerAsyncHandler(
            for: "biz.forms.createTraceId",
            paramsType: FormsCreateTraceIdParams.self,
            resultType: FormsCreateTraceIdResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsPerformance
                    .createTraceId(
                        params: params,
                        success: { data in
                            callback(.success(data: data))
                        },
                        failure: { error in
                            callback(.failure(error: error))
                        }
                    )
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
        registerAsyncHandler(
            for: "biz.forms.reportWithTraceId",
            paramsType: FormsReportWithTraceIdParams.self,
            resultType: OpenAPIBaseResult.self
        ) { [weak self] (params, context, callback) in
            guard let self = self else { return }
            switch self.formsContext(context: context) {
            case .success(let form):
                form
                    .0
                    .formsPerformance
                    .reportWithTraceId(
                        params: params
                    )
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
        
    }
    
    private func formsContext(context: OpenAPIContext) -> Result<(FormsAPI, UIViewController), OpenAPIError> {
        guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
            let code = -999999
            let msg = "gadgetContext is nil"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            context.apiTrace.error(msg)
            return .failure(error)
        }
        
        guard let vc = apiContext.controller as? WebBrowser else {
            let code = -999998
            let msg = "controller is nil"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            context.apiTrace.error(msg)
            return .failure(error)
        }
        
        // 如果是 Forms 独立容器则无需做 URL 判断，否则需要
        guard vc.resolve(FormsExtensionItem.self)?.isFormsBrowser == true || FormsConfiguration.checkHostFormsValid(url: vc.browserURL) else {
            let code = -999997
            let msg = "no permission for \(vc.browserURL)"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            context.apiTrace.error(msg)
            return .failure(error)
        }
        
        return .success((vc.formsAPI, vc))
    }
}
