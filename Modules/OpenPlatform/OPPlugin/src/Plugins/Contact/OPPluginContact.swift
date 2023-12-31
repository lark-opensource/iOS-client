//
//  EMAPluginContact.m
//  Action
//
//  Created by yin on 2019/6/10.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import ECOProbe
import LarkSetting
import LarkContainer
import LarkOPInterface

final class OPPluginContact: OpenBasePlugin {
    // TODO: check生命周期是否是全局
    /// 标识是否显示了选择联系人弹窗
    var isSelectChatterNamesVCPresented: Bool = false
    /// 选择联系人回调
    var chooseContactCallback: ((OpenAPIBaseResponse<OpenAPIChooseContactResult>) -> Void)?
    
    lazy var exEmployeeFilterParamConfig: [String: Any] = {
        do {
            return try userResolver.settings.setting(with: .make(userKeyLiteral: "enable_choose_contact_type"))
        } catch {
            return [
                "containers": [],
                "apps": []
            ]
        }
    }()
    
    enum APIName: String {
        case enterProfile
        case chooseContact
    }
    
    @InjectedSafeLazy
    var outerService: OpenPlatformOuterService
    
    @FeatureGatingValue(key: "openplatform.api.pluginmanager.extension.enable")
    var apiExtensionEnable: Bool
    
    @FeatureGatingValue(key: "openplatform.open.interface.api.unite.opt")
    public static var apiUniteOpt: Bool
    
    @ScopedProvider var openApiService: LarkOpenAPIService?

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        if apiExtensionEnable {
            registerAsync(
                for: APIName.enterProfile.rawValue,
                registerInfo: .init(pluginType: Self.self),
                extensionInfo: .init(
                    type: OpenAPIContactExtension.self,
                    defaultCanBeUsed: false)) { Self.enterProfileV2($0) }
        } else {
            registerInstanceAsyncHandlerGadget(
                for: APIName.enterProfile.rawValue,
                pluginType: Self.self,
                paramsType: OpenAPIEnterProfileParams.self,
                resultType: OpenAPIBaseResult.self)
            { (this, params, context, gadgetContext, callback) in
                this.enterProfile(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            }
        }
        
        registerInstanceAsyncHandlerGadget(
            for: APIName.chooseContact.rawValue,
            pluginType: Self.self,
            paramsType: OpenAPIChooseContactParams.self,
            resultType: OpenAPIChooseContactResult.self)
        { (this, params, context, gadgetContext, callback) in
            this.chooseContact(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
