//
// Created by maozhixiang.lip on 2022/10/12.
//

import Foundation
import BDXServiceCenter
import BDXLynxKit
import BDXBridgeKit
import Lynx
import ByteViewCommon
import UniverseDesignColor

typealias Logger = ByteViewCommon.Logger

public protocol LynxDependency {
    func syncResource()
    func loadTemplate(path: String, callback: ((Data?, Error?) -> Void)?)
    var globalProps: [String: Any] { get }
}

public final class LynxManager {
    public static let shared = LynxManager()
    public static let bizId: String = "vc-product"

    private var lynxKit: BDXLynxKitProtocol
    private var devTool: BDXLynxDevtoolProtocol

    private init() {
        self.lynxKit = BDXServiceManager.getObject(BDXLynxKitProtocol.self, BDXLynxKitProtocol.self)!
        self.devTool = DevTool()
        self.setupLynxKit()
        self.setupBridge()
        UDColor.registerToken()
    }

    private func setupLynxKit() {
        self.lynxKit.initLynxKit()
        self.lynxKit.addDevtoolDelegate(self.devTool)
        #if DEBUG
        LynxEnv.sharedInstance().devtoolEnabled = true
        #endif
    }

    private func setupBridge() {
        BDXBridge.registerEngineClass(BDXBridgeEngineAdapter_TTBridgeUnify.self, inDevelopmentMode: true)
        BDXBridge.registerDefaultGlobalMethods(filter: nil)
    }

    public func connectDevServer(_ url: URL) -> Bool {
        LynxEnv.sharedInstance().devtoolEnabled = true
        let res = self.lynxKit.enableLynxDevtool(url)
        Logger.lynx.debug("connect to dev server, url = \(url), res = \(res)")
        return res
    }

    private class DevTool: NSObject, BDXLynxDevtoolProtocol {
        func openDevtoolCard(_ url: String) -> Bool {
            let router = BDXServiceManager.getObject(BDXRouterProtocol.self, BDXRouterProtocol.self)
            let context = BDXContext()
            router?.open(withUrl: url, context: context, completion: nil)
            return true
        }
    }
}

extension BDXServiceManager {
    static func getObject<T>(_ proto: Protocol, _: T.Type) -> T? {
        Self.getObjectWith(proto, bizID: nil) as? T // TODO @maozhixiang.lip : bizID?
    }
}

extension Logger {
    static let lynx = getLogger("lynx")
}

extension LynxManager {
    private static var dependencyFactory: ((String) -> LynxDependency?)?

    public static func setDependency(factory: @escaping (String) -> LynxDependency?) {
        self.dependencyFactory = factory
    }

    private func getDependency(userId: String) -> LynxDependency? {
        if let dependency = LynxManager.dependencyFactory?(userId) {
            return dependency
        } else {
            Logger.lynx.error("getDependency for user \(userId) failed")
            assertionFailure("getDependency for user \(userId) failed")
            return nil
        }
    }

    public func syncResource(userId: String) {
        getDependency(userId: userId)?.syncResource()
    }

    func createView(userId: String, path: String, builderBlock: @escaping (LynxViewBuilder) -> Void) -> LynxView? {
        guard let dependency = getDependency(userId: userId) else { return nil }
        let builder = LynxViewBuilder(kit: self.lynxKit, path: path)
            .globalProps(dependency.globalProps)
            .sizeMode(widthMode: .exact, heightMode: .exact)
            .templateProvider(LocalTemplateProvider(path: path))
            .nativeModule(LynxLoggerModule.self)
            .nativeModule(LynxTrackerModule.self)
            .imageFetcher(LynxViewImageFetcher.shared)
            .uiElement(name: LynxSwitchElement.name, elementType: LynxSwitchElement.self)
            .uiElement(name: LynxCheckBoxElement.name, elementType: LynxCheckBoxElement.self)
            .uiElement(name: LynxAvatarElement.name, elementType: LynxAvatarElement.self)
            .uiElement(name: LynxListElement.name, elementType: LynxListElement.self)
            .uiElement(name: LynxCardHeaderElement.name, elementType: LynxCardHeaderElement.self)
        #if DEBUG
//        builder.templateProvider(DebugTemplateProvider())
        #endif
        builderBlock(builder)
        return builder.build()
    }
}

private class DebugTemplateProvider: NSObject, LynxTemplateProvider {
    func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
        guard let requestUrl = URL(string: url) else { return }
        let request = URLRequest(url: requestUrl)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let lastModified = (response as? HTTPURLResponse)?.allHeaderFields["Last-Modified"] ?? ""
            DispatchQueue.main.async {
                Logger.lynx.info("loadTemplate complete, url = \(String(describing: url)), lastModified = \(lastModified), error = \(String(describing: error))")
                if error != nil {
                    callback(data, error)
                } else if data != nil {
                    callback(data, nil)
                }
            }
        }
        task.resume()
    }
}

private class LocalTemplateProvider: NSObject, LynxTemplateProvider {
    private let path: String

    init(path: String) {
        self.path = path
        super.init()
    }

    func loadTemplate(withUrl url: String!, onComplete callback: LynxTemplateLoadBlock!) {
        Logger.lynx.info("load local template, path = \(self.path)")
        if let data = LynxResources.loadLynxTemplate(self.path) {
            callback(data, nil)
        }
    }
}
