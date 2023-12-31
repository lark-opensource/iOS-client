//
//  SetMainNavRightItems.swift
//  EcosystemWeb
//
//  Created by 新竹路车神 on 2021/9/7.
//

import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkUIKit
import OPSDK
import WebBrowser
import OPFoundation
import LarkContainer

final class SetMainNavRightItemsPlugin: OpenBasePlugin {
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerAsyncHandler(for: "setMainNavRightItems", paramsType: SetMainNavRightItemsParams.self) { (params, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                context.apiTrace.error("gadgetContext is nil")
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("apiContext.controller is not WebBrowser")
                context.apiTrace.error("apiContext.controller is not WebBrowser")
                callback(.failure(error: error))
                return
            }
            guard let mainNavigationAndTabWebBrowser = browser.parent as? SetMainNavRightItemsProtocol else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("is not main navigation mode")
                context.apiTrace.error("is not main navigation mode")
                callback(.failure(error: error))
                return
            }
            guard mainNavigationAndTabWebBrowser.customMainNavigationItemsMode else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("is not custom main navigation items mode")
                context.apiTrace.error("is not custom main navigation items mode")
                callback(.failure(error: error))
                return
            }
            mainNavigationAndTabWebBrowser.mainNavRightItemsParams = params
            mainNavigationAndTabWebBrowser.reloadMainNavigationBar()
            callback(.success(data: nil))
        }
    }
}

public protocol SetMainNavRightItemsProtocol: AnyObject {
    var customMainNavigationItemsMode: Bool { get }
    var mainNavRightItemsParams: SetMainNavRightItemsParams? { get set }
    func reloadMainNavigationBar()
}

public final class SetMainNavRightItemsParams: OpenAPIBaseParams {
    
    public final class SetMainNavRightItemsModelParams: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "iconURL", validChecker: {
            !$0.isEmpty
        })
        public var iconURL: String
        
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "id", validChecker: {
            !$0.isEmpty
        })
        public var id: String
        
        public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            [_iconURL, _id]
        }
    }
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "items", validChecker: {
        !$0.isEmpty && $0.count < 4
    })
    public var items: [SetMainNavRightItemsModelParams]
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_items]
    }
}

public final class MainNavRightItemButton: UIButton {
    public let item: SetMainNavRightItemsParams.SetMainNavRightItemsModelParams
    public init(item: SetMainNavRightItemsParams.SetMainNavRightItemsModelParams) {
        self.item = item
        super.init(frame: .zero)
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
