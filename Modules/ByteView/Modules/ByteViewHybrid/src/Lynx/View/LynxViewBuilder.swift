//
// Created by maozhixiang.lip on 2022/10/19.
//

import Foundation
import BDXServiceCenter
import BDXLynxKit
import BDXBridgeKit

class LynxViewBuilder {
    private let kit: BDXLynxKitProtocol
    private let path: String
    private var params: BDXLynxKitParams
    private var frame: CGRect = .zero
    private var bridgeHandlers: [String: BDXLynxBridgeHandler] = [:]
    private var nativeModules: [(AnyClass, Any?)] = []
    private var uiElements: [String: AnyClass] = [:]
    private var templateProvider: LynxTemplateProvider?
    private var imageFetcher: LynxImageFetcher?
    private var lifecycleDelegate: LynxViewLifecycleDelegate?

    init(kit: BDXLynxKitProtocol, path: String) {
        self.kit = kit
        self.path = path
        self.params = BDXLynxKitParams()
        //必传，用于区分每个lynxview https://bytedance.feishu.cn/wiki/wikcn6udV7Rw7wPW4BqrFBY4Fpb#
        self.params.sourceUrl = "http://localhost:9090/dist/\(path)"
        self.params.context = BDXContext()
        if let data = LynxTemplateData(dictionary: [:]) {
            self.params.globalProps = data
        }
        if let data = LynxTemplateData(dictionary: [:]) {
            self.params.initialProperties = data
        }
    }

    @discardableResult
    func frame(_ frame: CGRect) -> Self {
        self.frame = frame
        return self
    }

    @discardableResult
    func sizeMode(widthMode: BDXLynxViewSizeMode, heightMode: BDXLynxViewSizeMode) -> Self {
        self.params.widthMode = widthMode
        self.params.heightMode = heightMode
        return self
    }

    @discardableResult
    func group(_ groupName: String) -> Self {
        self.params.groupContext = groupName
        return self
    }

    @discardableResult
    func templateProvider(_ provider: LynxTemplateProvider) -> Self {
        self.templateProvider = provider
        self.params.templateProvider = self.templateProvider // weak
        return self
    }

    @discardableResult
    func imageFetcher(_ fetcher: LynxImageFetcher) -> Self {
        self.imageFetcher = fetcher
        self.params.imageFetcher = self.imageFetcher // weak
        return self
    }

    @discardableResult
    func lifecycleDelegate(_ delegate: LynxViewLifecycleDelegate) -> Self {
        self.lifecycleDelegate = delegate
        return self
    }

    @discardableResult
    func globalProps(_ props: [String: Any]) -> Self {
        (self.params.globalProps as? LynxTemplateData)?.update(with: props)
        return self
    }

    @discardableResult
    func globalProps(_ key: String, _ value: Any) -> Self {
        (self.params.globalProps as? LynxTemplateData)?.update(value, forKey: key)
        return self
    }

    @discardableResult
    func initProps(_ props: [String: Any]) -> Self {
        (self.params.initialProperties as? LynxTemplateData)?.update(with: props)
        return self
    }

    @discardableResult
    func initProps(_ key: String, _ value: Any) -> Self {
        (self.params.initialProperties as? LynxTemplateData)?.update(value, forKey: key)
        return self
    }

    @discardableResult
    func bridgeHandler(_ name: String, handler: @escaping (LynxBridgeParams?, LynxBridgeCallback) -> Void) -> Self {
        self.bridgeHandlers[name] = { _, _, params, callback in
            handler(params, { callback($0.rawValue, $1) })
        }
        return self
    }

    @discardableResult
    func bridgeHandler<T: LynxBridgeHandler>(_ handler: T) -> Self {
        self.bridgeHandlers[handler.name] = { _, _, params, callback in
            handler.handle(param: params, callback: { status, callbackParams in
                callback(status.rawValue, callbackParams)
            })
        }
        return self
    }

    @discardableResult
    func nativeModule<T: LynxNativeModule>(_ module: T.Type, param: T.Param? = nil) -> Self {
        self.nativeModules.append((module, param))
        return self
    }

    @discardableResult
    func uiElement<T: UIView>(name: String, elementType: LynxUI<T>.Type) -> Self {
        self.uiElements[name] = elementType
        return self
    }

    func build() -> LynxView? {
        guard let view = self.kit.createView(withFrame: self.frame, params: self.params) else { return nil }
        self.bridgeHandlers.forEach { name, handler in view.registerHandler(handler, forMethod: name) }
        self.nativeModules.forEach { module, param in view.registerModule(module, param: param) }
        self.uiElements.forEach { name, element in view.registerUI?(element, withName: name) }
        view.lifecycleDelegate = self.lifecycleDelegate // weak
        // view.load()
        let context = LynxView.Context.init(
            params: self.params,
            imageFetcher: self.imageFetcher,
            templateProvider: self.templateProvider
        )
        return .init(kitView: view, context: context)
    }
}
