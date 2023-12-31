//
//  EMAPluginChat.m
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
import LarkOPInterface
import LarkContainer

/**
 /// 打开指定用户的聊天页面
 BDP_EXPORT_HANDLER(enterChat)
 /// 打开用户会话列表选择会话，调用前确保用户已经登入
 BDP_HANDLER(chooseChat)
 /// 打开用户会话信息
 BDP_HANDLER(getChatInfo)
 /// 监听会话badge数量变化
 BDP_EXPORT_HANDLER(onChatBadgeChange)
 /// 解除监听会话badge数量变化
 BDP_EXPORT_HANDLER(offChatBadgeChange)
 */
final class OPPluginChat: OpenBasePlugin {
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    @ScopedProvider var openApiService: LarkOpenAPIService?
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        /// 进入聊天页
        registerInstanceAsyncHandlerGadget(for: "enterChat", pluginType: Self.self, paramsType: OpenAPIEnterChatParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            this.enterChat(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "getChatInfo", pluginType: Self.self, paramsType: OpenAPIGetChatInfoParams.self, resultType: OpenAPIGetChatInfoResult.self) { (this, params, context, gadgetContext, callback) in
            this.getChatInfo(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
