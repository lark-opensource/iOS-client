//
//  ASLynxBridgeManeger.swift
//  LarkSearch
//
//  Created by ZhangHongyun on 2021/7/18.
//

import Foundation
import UIKit
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import LKCommonsTracker
import SwiftyJSON
import UniverseDesignTheme
import Lynx
import RxSwift
import LarkContainer
import LarkSDKInterface
import LarkFoundation
import LarkLocationPicker
import LarkUIKit
import LarkGuide
import LarkFeatureGating
import LarkSetting
import LarkStorage
import UniverseDesignToast
import LarkRustClient
import RustPB
import ServerPB
import LarkAccountInterface
import SwiftProtobuf
import LarkEMM
import LarkSensitivityControl

public protocol ASLynxBridgeModule: LynxModule {
    func openSchema(url: String)
    func sendEvent(eventName: String, params: [String: Any])
    func isDarkMode() -> Bool
    func openSearch(query: String)
    func getAvatarUrl(key: String, callback: @escaping (String) -> Void)
    func log(msg: String)
    func getStringByKey(key: String) -> String
    func getFGEnable(fgKey: String) -> Bool
    func encrypt(content: String) -> String
    func contentChange()
    func openDial(name: String, phoneNum: String)
    func openSearchTab(appId: String, tabName: String)
    func openLocation(latitude: Double, longitude: Double)
    func openProfile(userId: String)
    func sendClickEvent(params: [String: Any])
    func cardAction(id: String, action: Int)
    func cardActionPassThrough(jsonString: String)
    func seeMoreDefinitions(abbrName: String, jsonString: String)
    func checkToShowGuide(guideKey: String) -> Bool
    func completeGuide(guideKey: String)
    func getDomainSetting(settingKey: String) -> String
    func showToast(toast: String)
    func setStorageItem(key: String, value: String)
    func getStorageItem(key: String) -> String
    func callRust(command: Int, data: [UInt8], isPassThrough: Bool, callback: @escaping LynxCallbackBlock)
    /// 创建一个空白的通用Lynx页面
    func openLynxPage(channelName: String, templateName: String, JSON: String)
    func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock)
    func writeClipboard(content: String?)
}

public protocol ASLynxBridgeDependency: AnyObject {
    func contentChange()
    func changeQuery(_ query: String)
    func sendClickEvent(params: [String: Any])
    func openProfile(userId: String)
    func openSearchTab(appId: String, tabName: String)
    func openSchema(url: String)
    func closePage()
    func cardAction(id: String, action: Int)
    func cardActionPassThrough(jsonString: String)
    /// 查看更多页面，用于老版卡片
    func seeMoreDefinitions(abbrName: String, jsonString: String)
    func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock)
    var userResolver: UserResolver { get }
}

public extension ASLynxBridgeDependency {
    func contentChange() { }
    func changeQuery(_ query: String) { }
    func sendClickEvent(params: [String: Any]) { }
    func openProfile(userId: String) { }
    func openSearchTab(appId: String, tabName: String) { }
    func closePage() { }
    func cardAction(id: String, action: Int) { }
    func cardActionPassThrough(jsonString: String) { }
    func seeMoreDefinitions(abbrName: String, jsonString: String) { }
}

public final class ASLynxBridge: NSObject, ASLynxBridgeModule {

    private static let globalStore = KVStores.Search.globalStore
    private static let logger = Logger.log(ASLynxBridge.self, category: "Module.Search.ASLynxBridge")
    private let vmFactory = LynxViewModelFactory()
    public static var i18nKeyMap: [String: String] = ["Lark_Feed_QuickSwitcherUnfold": BundleI18n.LarkSearchCore.Lark_Feed_QuickSwitcherUnfold,
                                                       "Lark_Feed_QuickSwitcherFold": BundleI18n.LarkSearchCore.Lark_Feed_QuickSwitcherFold]
    private let disposeBag = DisposeBag()

    public var dependency: ASLynxBridgeDependency?

    public var userResolver: UserResolver?

    var resourceAPI: ResourceAPI?
    var rust: RustService?
    var newGuideManager: NewGuideService?

    required override public init() {
    }

    required public init(param: Any) {
        dependency = param as? ASLynxBridgeDependency
        self.userResolver = dependency?.userResolver
        self.resourceAPI = try? userResolver?.resolve(assert: ResourceAPI.self)
        self.rust = try? userResolver?.resolve(assert: RustService.self)
        self.newGuideManager = try? userResolver?.resolve(assert: NewGuideService.self)
    }

    public static var name = "ASLynxBridge"
    public static var methodLookup = ["openSchema": NSStringFromSelector(#selector(openSchema(url:))),
                               "getAvatarUrl": NSStringFromSelector(#selector(getAvatarUrl(key:callback:))),
                               "log": NSStringFromSelector(#selector(log(msg:))),
                               "isDarkMode": NSStringFromSelector(#selector(isDarkMode)),
                               "contentChange": NSStringFromSelector(#selector(contentChange)),
                               "openSearch": NSStringFromSelector(#selector(openSearch(query:))),
                               "sendEvent": NSStringFromSelector(#selector(sendEvent(eventName:params:))),
                               "sendClickEvent": NSStringFromSelector(#selector(sendClickEvent(params:))),
                               "getStringByKey": NSStringFromSelector(#selector(getStringByKey(key:))),
                               "getFGEnable": NSStringFromSelector(#selector(getFGEnable(fgKey:))),
                               "openDial": NSStringFromSelector(#selector(openDial(name:phoneNum:))),
                               "openSearchTab": NSStringFromSelector(#selector(openSearchTab(appId:tabName:))),
                               "openLocation": NSStringFromSelector(#selector(openLocation(latitude:longitude:))),
                               "openProfile": NSStringFromSelector(#selector(openProfile(userId:))),
                               "closePage": NSStringFromSelector(#selector(closePage)),
                               "cardAction": NSStringFromSelector(#selector(cardAction(id:action:))),
                               "cardActionPassThrough": NSStringFromSelector(#selector(cardActionPassThrough(jsonString:))),
                               "seeMoreDefinitions": NSStringFromSelector(#selector(seeMoreDefinitions(abbrName:jsonString:))),
                               "checkToShowGuide": NSStringFromSelector(#selector(checkToShowGuide(guideKey:))),
                               "completeGuide": NSStringFromSelector(#selector(completeGuide(guideKey:))),
                               "encrypt": NSStringFromSelector(#selector(encrypt(content:))),
                               "getDomainSetting": NSStringFromSelector(#selector(getDomainSetting(settingKey:))),
                               "showToast": NSStringFromSelector(#selector(showToast(toast:))),
                               "setStorageItem": NSStringFromSelector(#selector(setStorageItem(key:value:))),
                               "getStorageItem": NSStringFromSelector(#selector(getStorageItem(key:))),
                               "callRust": NSStringFromSelector(#selector(callRust(command:data:isPassThrough:callback:))),
                               "openShare": NSStringFromSelector(#selector(openShare(msgContent:title:callBack:))),
                               "openLynxPage": NSStringFromSelector(#selector(openLynxPage(channelName:templateName:JSON:))),
                               "writeClipboard": NSStringFromSelector(#selector(writeClipboard(content:)))
    ]

    @objc
    public func openSchema(url: String) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: openSchema begin!")
        dependency?.openSchema(url: url)
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: openSchema end!")
    }

    @objc
    public func isDarkMode() -> Bool {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: isDarkMode begin!")
        var darkModeStatus = false
        if #available(iOS 13.0, *) {
            darkModeStatus = UDThemeManager.userInterfaceStyle == .dark
        }
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: dark mode status: \(darkModeStatus)")
        return darkModeStatus
    }

    @objc
    public func openSearch(query: String) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: In openSearch method and the query is : \(query)")
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.changeQuery(query)
        }
    }

    @objc
    public func sendEvent(eventName: String, params: [String: Any]) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: In sendEvent method and the eventName is : \(eventName)")
        Tracker.post(TeaEvent(eventName, params: params))
    }

    @objc
    public func sendClickEvent(params: [String: Any]) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: In sendClickEvent method and the params is : \(params)")
        self.dependency?.sendClickEvent(params: params)
    }

    @objc
    public func getAvatarUrl(key: String, callback: @escaping (String) -> Void) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: In getAvatarUrl method and the key is : \(key)")
        self.resourceAPI?.fetchResourcePath(entityID: "", key: key, size: 100, dpr: 100, format: "png")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { response in
                callback(response)
                Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: getAvatarUrl success!")
            }, onError: { error in
                Self.logger.error("【LarkSearch.ASLynxBridge】- ERROR: getAvatarUrl error: \(error)")
            }).disposed(by: disposeBag)
    }

    @objc
    public func log(msg: String) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: \(msg)")
    }

    @objc
    public func getStringByKey(key: String) -> String {
        if let value = Self.i18nKeyMap[key] {
            return value
        }
        return ""
    }
    @objc
    public func getFGEnable(fgKey: String) -> Bool {
        return userResolver?.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: fgKey)) ?? false
    }
    @objc
    public func encrypt(content: String) -> String {
        let result = SearchTrackUtil.encrypt(id: content)
        return result
    }

    @objc
    public func contentChange() {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: contentChange called")
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.contentChange()
        }
    }
    @objc
    public func openDial(name: String, phoneNum: String) {
        DispatchQueue.main.async { [weak self] in
            guard let vc = self?.userResolver?.navigator.mainSceneTopMost else {
                Self.logger.error("【LarkSearch.ASLynxBridge】- ERROR: vc is null！")
                return
            }
            let num = phoneNum.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression, range: nil)
            self?.userResolver?.navigator.open(body: OpenTelBody(number: num), from: vc)
        }
    }
    @objc
    public func openSearchTab(appId: String, tabName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.openSearchTab(appId: appId, tabName: tabName)
        }
    }
    @objc
    public func openLocation(latitude: Double, longitude: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let vc = self?.userResolver?.navigator.mainSceneTopMost else {
                Self.logger.error("【LarkSearch.ASLynxBridge】- ERROR: vc is null！")
                return
            }
            LarkLocationPickerUtils.showMapSelectionSheet(from: vc,
                                                          isInternal: false,
                                                          locationName: "",
                                                          latitude: latitude,
                                                          longitude: longitude)
        }
    }
    @objc
    public func openProfile(userId: String) {
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.openProfile(userId: userId)
        }
    }
    @objc
    public func closePage() {
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.closePage()
        }
    }
    @objc
    public func cardAction(id: String, action: Int) {
        self.dependency?.cardAction(id: id, action: action)
    }
    @objc
    public func cardActionPassThrough(jsonString: String) {
        self.dependency?.cardActionPassThrough(jsonString: jsonString)
    }
    @objc
    public func seeMoreDefinitions(abbrName: String, jsonString: String) {
        DispatchQueue.main.async { [weak self] in
            self?.dependency?.seeMoreDefinitions(abbrName: abbrName, jsonString: jsonString)
        }
    }
    @objc
    public func checkToShowGuide(guideKey: String) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            result = self.newGuideManager?.checkShouldShowGuide(key: guideKey) ?? false
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
    @objc
    public func completeGuide(guideKey: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.newGuideManager?.didShowedGuide(guideKey: guideKey)
        }
    }
    @objc
    public func getDomainSetting(settingKey: String) -> String {
        guard let domainKey = DomainKey(rawValue: settingKey), let domain = DomainSettingManager.shared.currentSetting[domainKey]?.first else {
            return ""
        }
        return domain
    }
    @objc
    public func showToast(toast: String) {
        DispatchQueue.main.async(execute: {
            if #available(iOS 13.0, *) {
                let win = UIApplication.shared.windowApplicationScenes
                    .first(where: { $0 is UIWindowScene && $0.activationState == .foregroundActive })
                    .flatMap({ $0 as? UIWindowScene })?.windows
                    .first(where: \.isKeyWindow)
                if let window = win {
                    UDToast.showTips(with: toast, on: window)
                }
            } else {
                if let window = UIApplication.shared.keyWindow {
                    UDToast.showTips(with: toast, on: window)
                }
            }
        })
    }
    @objc
    public func setStorageItem(key: String, value: String) {
        Self.globalStore[key] = value
    }
    @objc
    public func getStorageItem(key: String) -> String {
        return Self.globalStore[key] ?? ""
    }

    @objc
    public func callRust(command: Int, data: [UInt8], isPassThrough: Bool, callback: @escaping LynxCallbackBlock) {
        func error(msg: String) {
            Self.logger.error("【LarkSearch.ASLynxBridge】- ERROR: \(msg)")
            callback([
                "isSuccess": false,
                "rawResponse": ["error": msg]
            ])
        }
        let requestData = Data(data)
        let request: RawRequestPacket
        if isPassThrough {
            guard let serCommand = ServerCommand(rawValue: command) else {
                return error(msg: "invalid server command \(command)")
            }
            request = RawRequestPacket(serCommand: serCommand, message: requestData)
        } else {
            guard let cmd = Basic_V1_Command(rawValue: command) else {
                return error(msg: "invalid rust command \(command)")
            }
            request = RawRequestPacket(command: cmd, message: requestData)
        }

        rust?.async(request) { (response) in
            var responseParam: [String: Any] = [:]
            switch response.result {
            case .success(let data):
                Self.logger.info("【LarkSearch.ASLynxBridge】- Info: callRust \(isPassThrough ? "" : "none")passThrough cmd \(command) Succeeded")
                responseParam["isSuccess"] = true
                responseParam["rawResponse"] = data
                callback(responseParam)
            case .failure(let error):
                Self.logger.error("【LarkSearch.ASLynxBridge】- Error: callRust \(isPassThrough ? "" : "none")passThrough cmd \(command) Failed, error: \(error)")
                responseParam["isSuccess"] = false
                responseParam["rawResponse"] = ["error": error.localizedDescription]
                callback(responseParam)
            }
        }
    }

    @objc
    public func openLynxPage(channelName: String, templateName: String, JSON: String) {
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: openLynxPage begin!")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let userResolver = self.userResolver else { return }
            guard let vc = userResolver.navigator.mainSceneTopMost else {
                Self.logger.error("【LarkSearch.ASLynxBridgeDependencyWrapper】- ERROR: vc is null！")
                return
            }
            let vm = self.vmFactory.createFullPageLynxViewModel(channelName: channelName,
                                                                templateName: templateName,
                                                                json: JSON,
                                                                supportOrientations: vc.supportedInterfaceOrientations)
            let params = FullPageLynxDependency(userResolver: userResolver, viewModel: vm)
            let lynxViewController = FullPageLynxViewController(viewModel: vm, params: params)
            if Display.pad {
                userResolver.navigator.present(
                    lynxViewController, wrap: LkNavigationController.self, from: vc,
                    prepare: {
                        $0.modalPresentationStyle = .formSheet
                    },
                    animated: true)
            } else {
                userResolver.navigator.present(
                    lynxViewController, wrap: LkNavigationController.self, from: vc,
                    prepare: {
                        $0.transitioningDelegate = lynxViewController
                        $0.modalPresentationStyle = .custom
                    },
                    animated: true)
            }
        }
        Self.logger.info("【LarkSearch.ASLynxBridge】- INFO: openLynxPage end!")
    }

    @objc
    public func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock) {
        dependency?.openShare(msgContent: msgContent, title: title, callBack: callBack)
    }

    @objc
    public func writeClipboard(content: String?) {
        let config = PasteboardConfig(token: Token("LARK-PSDA-asl_lynx_bridge_copy_ios"))
        SCPasteboard.general(config).string = content
    }

}
