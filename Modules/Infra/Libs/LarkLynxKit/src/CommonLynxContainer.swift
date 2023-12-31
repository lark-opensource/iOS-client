//
//  CommonLynxContainer.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/4.
//

import Foundation
import Lynx
import LKCommonsLogging

public final class CommonLynxContainer: NSObject, LarkLynxContainerProtocol {
    
    
    static let logger = Logger.oplog(CommonLynxContainer.self, category: "CommonLynxContainer")
    private var lynxView: LynxView
    private var lynxTemplateModel: LynxTemplataModel?
    private var commonLifeCycle: LynxViewLifecycle?
    private let jsModuleEntity: JSModuleEntity?
    private var hasRenderedFlag = false
    private var hasLayoutFlag = false
    private let resourceManager: LarkLynxResourceManager?
    
    public init(lynxView: LynxView,
                lynxTemplateModel: LynxTemplataModel? = nil,
                commonLifeCycle: LynxViewLifecycle? = nil,
                jsModuleEntity: JSModuleEntity? = nil,
                resourceManager: LarkLynxResourceManager? = nil) {
        self.lynxView = lynxView
        self.lynxTemplateModel = lynxTemplateModel
        self.commonLifeCycle = commonLifeCycle
        self.jsModuleEntity = jsModuleEntity
        self.resourceManager = resourceManager
        super.init()
    }
    
    // MARK: - LarkLynxContainerProtocol
    
    public func getLynxView() -> UIView {
        return lynxView
    }

    public func getContentSize() -> CGSize {
        return CGSize(width: CGFloat(lynxView.rootWidth()), height: CGFloat(lynxView.rootHeight()))
    }

    public func hasRendered() -> Bool { hasRenderedFlag }

    public func hasLayout() -> Bool { hasLayoutFlag }

    public func render() {
        guard let templateModel = lynxTemplateModel else {
            return
        }

        let template: Data = templateModel.template ?? Data()
        let templateUrl: String = templateModel.templateUrl ?? ""
        Self.logger.info("CommonLynxContainer: render lynx, template is emtpy: \(templateModel.template?.isEmpty), lynxTemData is empty: \(templateModel.lynxTemplateData)")

        if template.isEmpty,
           templateUrl.isEmpty,
           let templatePath = templateModel.templatePathForResourceLoader,
           resourceManager != nil {
            // template 与 templateUrl 都为空，且传入了 templatePath 和 resourceManager，用 resourceManager 进行加载
            render(templatePathUsingResourceLoader: templatePath, initData: templateModel.lynxTemplateData)
        } else {
            self.lynxView.loadTemplate(template, withURL: templateUrl, initData: templateModel.lynxTemplateData)
        }
        self.hasRenderedFlag = true
    }

    public func render(templatePathUsingResourceLoader templatePath: String,
                       initData: String) {
        let lynxTemplateData = LynxTemplateData(json: initData)
        render(templatePathUsingResourceLoader: templatePath, initData: lynxTemplateData)
    }

    public func render(templatePathUsingResourceLoader templatePath: String,
                       initData: [AnyHashable: Any]) {
        let lynxTemplateData = LynxTemplateData(dictionary: initData)
        render(templatePathUsingResourceLoader: templatePath, initData: lynxTemplateData)
    }

    private func render(templatePathUsingResourceLoader templatePath: String,
                        initData: LynxTemplateData?) {
        guard let resourceManager else {
            Self.logger.error("resourceManager not set when render templatePath: \(templatePath)")
            assertionFailure("set tagForResourceManager in containerBuilder first")
            return
        }
        let tag = resourceManager.tag
        Self.logger.info("CommonLynxContainer:render resource templatePath: \(templatePath), tag: \(tag)")
        resourceManager.load(templatePath: templatePath) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case let .success(templateInfo):
                    let template = templateInfo.templateData
                    let templateUrl = ""
                    Self.logger.info("CommonLynxContainer:render resource, template is empty: \(template.isEmpty)")
                    self.lynxView.loadTemplate(template,
                                               withURL: templateUrl,
                                               initData: initData)
                    self.hasRenderedFlag = true
                case let .failure(error):
                    Self.logger.error("CommonLynxContainer:render resource failed, templatePath: \(templatePath), tag: \(tag)", error: error)
                }
            }
        }
    }

    public func processLayout(template: Data, withURL: String, initData: [AnyHashable: Any]) {
        Self.logger.info("CommonLynxContainer:render template:\(template.count), initData:\(initData.count)")
        let lynxData = LynxTemplateData(dictionary: initData)
        self.lynxView.processLayout(template, withURL: withURL, initData: lynxData)
        self.hasLayoutFlag = true
    }

    public func processRender() {
        self.lynxView.processRender()
        self.hasRenderedFlag = true
    }

    public func render(template: Data, initData: String) {
        Self.logger.info("CommonLynxContainer:render template:\(template.count), initData:\(initData.count)")
        let lynxTemData = LynxTemplateData(json: initData)
        self.lynxView.loadTemplate(template, withURL: "", initData: lynxTemData)
        self.hasLayoutFlag = true
        self.hasRenderedFlag = true
    }
    
    public func render(bundle: LynxTemplateBundle, initData: [AnyHashable: Any]) {
        let lynxTemData = LynxTemplateData(dictionary: initData)
        self.lynxView.load(bundle, withURL: "", initData: lynxTemData)
        self.hasLayoutFlag = true
        self.hasRenderedFlag = true
    }
    
    public func render(template: Data, initData: [AnyHashable: Any]) {
        Self.logger.info("CommonLynxContainer:render template:\(template.count), initData:\(initData.count)")
        let lynxTemData = LynxTemplateData(dictionary: initData)
        self.lynxView.loadTemplate(template, withURL: "", initData: lynxTemData)
        self.hasLayoutFlag = true
        self.hasRenderedFlag = true
    }
    
    public func render(templateUrl: String, initData: String) {
        Self.logger.info("CommonLynxContainer:render templateUrl:\(templateUrl.isEmpty), dataJson:\(initData.count)")
        let lynxTemData = LynxTemplateData(json: initData)
        self.lynxView.loadTemplate(fromURL: templateUrl, initData: lynxTemData)
        self.hasLayoutFlag = true
        self.hasRenderedFlag = true
    }
    
    public func render(templateUrl: String, initData: [AnyHashable: Any]) {
        Self.logger.info("CommonLynxContainer:render templateUrl:\(templateUrl.isEmpty), dataJson:\(initData.count)")
        let lynxTemData = LynxTemplateData(dictionary: initData)
        self.lynxView.loadTemplate(fromURL: templateUrl, initData: lynxTemData)
        self.hasLayoutFlag = true
        self.hasRenderedFlag = true
    }
    
    public func update(data: String) {
        let lynxTemData = LynxTemplateData(json: data)
        self.lynxView.updateData(with: lynxTemData)
    }
    
    public func update(data: [AnyHashable: Any]) {
        let lynxTemData = LynxTemplateData(dictionary: data)
        self.lynxView.updateData(with: lynxTemData)
    }
    
    public func updateGlobalData(data: [String : Any]) {
        self.lynxView.updateGlobalProps(with: data)
    }
    
    public func updateGlobalData(data: String) {
        let templateData: LynxTemplateData = LynxTemplateData(json: data)
        self.lynxView.updateGlobalProps(with: templateData)
    }
    
    public func updateLayoutIfNeeded(sizeConfig: LynxViewSizeConfig) {
        let  preferredLayoutWidth: CGFloat = sizeConfig.preferredLayoutWidth ?? 0
        let  preferredLayoutHeight: CGFloat = sizeConfig.preferredLayoutHeight ?? 0
        if let preferredMaxLayoutHeight = sizeConfig.preferredMaxLayoutHeight {
            lynxView.preferredMaxLayoutHeight = preferredMaxLayoutHeight
        }
        if let preferredMaxLayoutWidth = sizeConfig.preferredMaxLayoutWidth {
            lynxView.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        }
        if preferredLayoutWidth != lynxView.preferredLayoutWidth || preferredLayoutHeight != lynxView.preferredLayoutHeight {
            lynxView.updateViewport(withPreferredLayoutWidth: preferredLayoutWidth, preferredLayoutHeight: preferredLayoutHeight, needLayout: true)
        }
    }
    
    public func updateModeIfNeeded(sizeConfig: LynxViewSizeConfig) {
        if let width = sizeConfig.layoutWidthMode {
            lynxView.layoutWidthMode = width
        }
        if let height = sizeConfig.layoutHeightMode {
            lynxView.layoutHeightMode = height
        }
    }
    
    public func sendGlobalEventToJS(event: String, dataArray: [Any]) {
        Self.logger.info("CommonLynxContainer:sendGlobalEvent")
        self.lynxView.sendGlobalEvent(event, withParams: dataArray)
    }
    
    public func sendDataToJSByModule(dataArray: [Any]) {
        if let jsModuleEntity = self.jsModuleEntity, let apiModule = lynxView.getJSModule(jsModuleEntity.jsModuleName) {
            Self.logger.info("CommonLynxContainer:send data by custom jsModule")
            apiModule.fire(jsModuleEntity.functionName, withParams: dataArray)
        } else if let apiModule = lynxView.getJSModule(LarkLynxDefines.defaultModuleName) {
            apiModule.fire(LarkLynxDefines.defaultFunName, withParams: dataArray)
        } else {
            Self.logger.error("CommonLynxContainer:not find apiModule")
        }
    }
    
    
    public func show() {
        self.lynxView.onEnterForeground()
    }
    
    public func hide() {
        self.lynxView.onEnterBackground()
    }
    
    public func setExtraTiming(extraTimingDic: [AnyHashable: Any]) {
        self.lynxView.setExtraTimingWith(extraTimingDic)
    }
    
}

