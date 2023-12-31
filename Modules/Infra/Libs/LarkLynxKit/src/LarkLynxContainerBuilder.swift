//
//  OPLynxContainerBuilder.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/3.
//

import Foundation
import ECOProbe
import Lynx
import LKCommonsLogging

public struct LynxContainerContext {
    var containerType: String?
    public var bizExtra: [String: Any]?
    
    public init(containerType: String? = nil, bizExtra: [String: Any]? = nil) {
        self.containerType = containerType
        self.bizExtra = bizExtra
    }
}

public struct CustomLynxBridgeModule {
    var moduleClass: LynxContextModule.Type
    public var param: [String: Any]
    
    public init(moduleClass: LynxContextModule.Type, param: [String: Any]) {
        self.moduleClass = moduleClass
        self.param = param
    }
}

public struct LynxViewSizeConfig {
    public var layoutWidthMode: LynxViewSizeMode?
    public var layoutHeightMode: LynxViewSizeMode?
    public var preferredMaxLayoutWidth: CGFloat?
    public var preferredMaxLayoutHeight: CGFloat?
    public var preferredLayoutWidth: CGFloat?
    public var preferredLayoutHeight: CGFloat?
    
    public init(layoutWidthMode: LynxViewSizeMode? = nil, layoutHeightMode: LynxViewSizeMode? = nil, preferredMaxLayoutWidth: CGFloat? = nil, preferredMaxLayoutHeight: CGFloat? = nil, preferredLayoutWidth: CGFloat? = nil, preferredLayoutHeight: CGFloat? = nil) {
        self.layoutWidthMode = layoutWidthMode
        self.layoutHeightMode = layoutHeightMode
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        self.preferredMaxLayoutHeight = preferredMaxLayoutHeight
        self.preferredLayoutWidth = preferredLayoutWidth
        self.preferredLayoutHeight = preferredLayoutHeight
    }
}

struct LarkLynxBridgeData {
    var bridgeDispatcher: LarkLynxBridgeMethodProtocol?
    var context: LynxContainerContext?
    var tagForBridgeMethodGroup: String?
}

public final class LarkLynxContainerBuilder {
    static let logger = Logger.oplog(LynxContainerContext.self, category: "CommonLynxContainer")
    private var context: LynxContainerContext?
    private var tagForJsContext: String?
    private var tagForCustomComponent: String?
    private var tagForGlobalData: String?
    private var tagForBridgeMethodGroup: String?
    private var tagForLynxGroup: String?
    private var tagForJSModule: String?
    private var tagForResourceLoaders: String?
    private var customBridgeModule: CustomLynxBridgeModule?
    private var tagForBridgeMethodDispatcher: String?
    private weak var lynxViewLifeCycle: LynxViewLifecycle?
    private weak var lynxResourceProvider: LynxResourceProvider?
    private weak var imageFetcher: LynxImageFetcher?
    private weak var resourceFetcher: LynxResourceFetcher?
    private var templateData: Data?
    private var templateUrl: String?
    private var lynxTemplateData: LynxTemplateData?
    private var templatePathForResourceLoader: String?
    private weak var resourceLoaderDelegate: LarkLynxResourceLoaderDelegate?
    private var sizeConfig: LynxViewSizeConfig?
    private var threadStrategyForRender: LynxThreadStrategyForRender?

    public init() {}
    
    /**
     设置业务context，context用于BridgeMethod

     - Parameters:
       - context: 业务context
     */
    public func setupContext(context: LynxContainerContext) -> LarkLynxContainerBuilder {
        self.context = context
        return self
    }
    
    /**
     设置Lynx模版

     - Parameters:
       - data: Lynx模版
     */
    public func setupTemplateData(data: Data) -> LarkLynxContainerBuilder {
        self.templateData = data
        return self
    }
    
    public func setupTemplateUrl(url: String) -> LarkLynxContainerBuilder {
        self.templateUrl = url
        return self
    }

    public func setupTemplatePathForResourceLoader(path: String) -> LarkLynxContainerBuilder {
        self.templatePathForResourceLoader = path
        return self
    }
    
    public func setupInitData(initData: String) -> LarkLynxContainerBuilder {
        self.lynxTemplateData = LynxTemplateData(json: initData)
        return self
    }
    
    public func setupInitData(initData: [AnyHashable: Any]) -> LarkLynxContainerBuilder {
        self.lynxTemplateData = LynxTemplateData(dictionary: initData)
        return self
    }
    
    public func tagForJsContext(tag: String) -> LarkLynxContainerBuilder {
        self.tagForJsContext = tag
        return self
    }
    
    public func tagForLynxGroup(tag: String) -> LarkLynxContainerBuilder {
        self.tagForLynxGroup = tag
        return self
    }
    
    public func lynxViewSizeConfig(sizeConfig: LynxViewSizeConfig?) -> LarkLynxContainerBuilder {
        self.sizeConfig = sizeConfig
        return self
    }
    
    /**
     用于多个LynxView复用Lynx自定义组件

     - Parameters:
       - tag: 业务标识
     
     - Warning:业务tag要与框架初始化时注册自定义组件(registerCustomComponents)的tag一致
     */
    public func tagForCustomComponent(tag: String) -> LarkLynxContainerBuilder {
        self.tagForCustomComponent = tag
        return self
    }
    
    public func tagForGlobalData(tag: String) -> LarkLynxContainerBuilder {
        self.tagForGlobalData = tag
        return self
    }
    
    /**
     用于多个LynxView复用Lynx自定义组件

     - Parameters:
       - tag: 业务标识
     
     - Warning:业务tag要与框架初始化时注册JSBridge协议的实例的tag一致
     */
    public func tagForBridgeMethodDispatcher(tag: String) -> LarkLynxContainerBuilder {
        self.tagForBridgeMethodDispatcher = tag
        return self
    }
    
    public func tagForBridgeMethodGroup(tag: String) -> LarkLynxContainerBuilder {
        self.tagForBridgeMethodGroup = tag
        return self
    }
    
    /**
     设置处理LynxView的回调的实例
     - Parameters:
       - lynxViewLifeCycle: 处理LynxView的回调的实例
     */
    public func lynxViewLifeCycle(lynxViewLifeCycle: LynxViewLifecycle) -> LarkLynxContainerBuilder {
        self.lynxViewLifeCycle = lynxViewLifeCycle
        return self
    }
    
    public func addLynxResourceProvider(lynxResourceProvider: LynxResourceProvider) -> LarkLynxContainerBuilder {
        self.lynxResourceProvider = lynxResourceProvider
        return self
    }
    
    public func tagForJSModule(tag: String) -> LarkLynxContainerBuilder {
        self.tagForJSModule = tag
        return self
    }
    
    /**
     设置业务LynxView的图片加载器

     - Parameters:
       - imageFetcher: 业务LynxView的图片加载器
     */
    public func lynxViewImageLoader(imageFetcher: LynxImageFetcher) -> LarkLynxContainerBuilder {
        self.imageFetcher = imageFetcher
        return self
    }
    
    /**
     设置业务自定义的BridgeModule

     - Parameters:
       - bridgeModule: 业务自定义的BridgeModule
     */
    public func bridgeModule(bridgeModule: CustomLynxBridgeModule) -> LarkLynxContainerBuilder {
        self.customBridgeModule = bridgeModule
        return self
    }
    
    
    /**
     设置业务LynxView的资源加载器

     - Parameters:
       - imageFetcher: 业务LynxView的资源加载器
     */
    public func lynxViewResourceFetcher(resourceFetcher: LynxResourceFetcher) -> LarkLynxContainerBuilder {
        self.resourceFetcher = resourceFetcher
        return self
    }

    /**
     用于多个LynxView间可复用的资源加载器，需要现在 LarkLynxInitializer 里注册

     - Parameters:
       - tag: 业务标识
     - Warning:业务tag要与框架初始化时注册自定义组件(registerResourceLoaders)的tag一致
     */
    public func tagForResourceLoaders(tag: String) -> LarkLynxContainerBuilder {
        self.tagForResourceLoaders = tag
        return self
    }

    /**
     设置 ResourceLoader 加载回调的实例

     - Parameters:
       - resourceLoaderDelegate: 监听 ResourceLoader 的加载回调的实例
     */
    public func resourceLoaderDelegate(resourceLoaderDelegate: LarkLynxResourceLoaderDelegate) -> LarkLynxContainerBuilder {
        self.resourceLoaderDelegate = resourceLoaderDelegate
        return self
    }

    public func setThreadStrategyForRender(_ threadStrategy: LynxThreadStrategyForRender) -> LarkLynxContainerBuilder{
        self.threadStrategyForRender = threadStrategy
        return self
    }

    /**
     构建LynxContainer
     */
    public func build() -> LarkLynxContainerProtocol {
        Self.logger.info("LarkLynxContainerBuilder: build")
        let lynxView = LynxView { (builder) in
            let config = LynxConfig(provider: LarkLynxTemplateProvider())
            if let threadStrategy = self.threadStrategyForRender {
                builder.setThreadStrategyForRender(threadStrategy)
            }
            if let tagForCustomComponent = self.tagForCustomComponent, let extensionUIDic = LarkLynxInitializer.shared.getCustomComponent(tag: tagForCustomComponent) {
                for (key, value) in extensionUIDic {
                    config.registerUI(value.0, withName: key)
                    if let shadowNodeClass = value.1 {
                        config.registerShadowNode(shadowNodeClass, withName: key)
                    }
                }
            }
            if let bizContext = self.context?.bizExtra {
                config.contextDict = NSMutableDictionary(dictionary: bizContext)
            }
            if let customBridgeModule = self.customBridgeModule {
                config.register(customBridgeModule.moduleClass.self, param: customBridgeModule.param)
            } else {
                let params: LarkLynxBridgeData = LarkLynxBridgeData(
                    bridgeDispatcher: LarkLynxInitializer.shared.getBridgeMethodDispatcher(tag: self.tagForBridgeMethodDispatcher ?? ""),
                    context: self.context,
                    tagForBridgeMethodGroup: self.tagForBridgeMethodGroup)
                config.register(LarkLynxBridgeModule.self, param: params)
            }
            if let lynxResourceProvider = self.lynxResourceProvider {
                builder.addLynxResourceProvider(LYNX_PROVIDER_TYPE_EXTERNAL_JS, provider: lynxResourceProvider)
            }
            
            builder.config = config
            if let tagForLynxGroup = self.tagForLynxGroup, let lynxGroup = LarkLynxInitializer.shared.getLynxGroup(groupName: tagForLynxGroup) {
                builder.group = lynxGroup
            }
        }
        if let tagForGlobalData = self.tagForGlobalData {
            let dic = LarkLynxInitializer.shared.getGlobalData(tag: tagForGlobalData) ?? [:]
            lynxView.setGlobalPropsWith(dic)
        }
        if let sizeConfig = self.sizeConfig {
            if let layoutWidthMode = sizeConfig.layoutWidthMode {
                lynxView.layoutWidthMode = layoutWidthMode
            }
            if let layoutHeightMode = sizeConfig.layoutHeightMode {
                lynxView.layoutHeightMode = layoutHeightMode
            }
            if let preferredMaxLayoutWidth = sizeConfig.preferredMaxLayoutWidth {
                lynxView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
            }
            if let preferredMaxLayoutHeight = sizeConfig.preferredMaxLayoutHeight {
                lynxView.preferredMaxLayoutHeight = preferredMaxLayoutHeight
            }
            if let preferredLayoutWidth = sizeConfig.preferredLayoutWidth {
                lynxView.preferredLayoutWidth = preferredLayoutWidth
            }
            if let preferredLayoutHeight = sizeConfig.preferredLayoutHeight {
                lynxView.preferredLayoutHeight = preferredLayoutHeight
            }
        }
        if let imageFetcher = self.imageFetcher {
            lynxView.imageFetcher = imageFetcher
        }
        if let resourceFetcher = self.resourceFetcher {
            lynxView.resourceFetcher = resourceFetcher
        }
        var lynxTemplateModel: LynxTemplataModel?
        if self.templateUrl != nil
            || self.templateData != nil
            || self.templatePathForResourceLoader != nil
            || self.lynxTemplateData != nil {
            lynxTemplateModel = LynxTemplataModel(template: templateData,
                                                  templateUrl: templateUrl,
                                                  templatePathForResourceLoader: templatePathForResourceLoader,
                                                  lynxTemplateData: lynxTemplateData)
        }
        var moduleEntity: JSModuleEntity?
        if let tagForJSModule = self.tagForJSModule, let jsModuleEntity = LarkLynxInitializer.shared.getJSModule(tag: tagForJSModule) {
            moduleEntity = jsModuleEntity
        }

        var resourceManager: LarkLynxResourceManager?
        if let tagForResourceLoaders {
            resourceManager = LarkLynxResourceManager(tag: tagForResourceLoaders,
                                                      delegate: resourceLoaderDelegate)
        } else {
            // 提醒设置了 templatePath 但是没有设置 loaderTag
            assert(templatePathForResourceLoader == nil, "tag for resourceManager not found when using templatePath for resource loader")
        }

        if let lynxViewLifeCycle = self.lynxViewLifeCycle {
            lynxView.addLifecycleClient(lynxViewLifeCycle)
            var lynxViewContainer = CommonLynxContainer(lynxView: lynxView, lynxTemplateModel: lynxTemplateModel, jsModuleEntity: moduleEntity, resourceManager: resourceManager)
            return lynxViewContainer
        } else {
            let commonLifeCycle: LynxViewLifecycle = LarkLynxViewLifeCycle(context: self.context)
            lynxView.addLifecycleClient(commonLifeCycle)
            var lynxViewContainer = CommonLynxContainer(lynxView: lynxView, lynxTemplateModel: lynxTemplateModel, commonLifeCycle: commonLifeCycle, jsModuleEntity: moduleEntity, resourceManager: resourceManager)
            return lynxViewContainer
        }
    }
}
