//
//  OPMockEMAProtocolService.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/10/10.
//

import Foundation
import Swinject
import LarkContainer
import LarkAssembler
import LarkOPInterface
import OPFoundation

final class OPMockEMAProtocolService: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Swinject.Container) {
        
        container.register(EMAProtocol.self) {_ in
            OPMockEMAProtocolImpl()
        }.inObjectScope(.container)
    }
}

final class OPMockEMAProtocolImpl: NSObject, EMAProtocol {
    func updateAppBadge(_ appID: String!, appType: LarkOPInterface.AppBadgeAppType, extra: LarkOPInterface.UpdateBadgeRequestParameters!, completion: @escaping (LarkOPInterface.UpdateAppBadgeNodeResponse?, Error?) -> Void) {
    }
    
    func pullAppBadge(_ appID: String!, appType: LarkOPInterface.AppBadgeAppType, extra: LarkOPInterface.PullBadgeRequestParameters!, completion: @escaping (LarkOPInterface.PullAppBadgeNodeResponse?, Error?) -> Void) {
    }
    
    
    func regist() {
    }
    
    func trackerEvent(_ event: String?, params: [AnyHashable : Any]?, option: OPMonitorReportPlatform) {
    }
    
    func shareWebUrl(_ url: String?, title: String?, content: String?) {
    }
    
    func shareCard(withTitle title: String?, uniqueID: OPAppUniqueID?, imageData: Data?, url: String?, appLinkHref: String?, options: EMAShareOptions = [], callback: EMAShareResultBlock? = nil) {
    }
    
    func canOpen(_ url: URL!, fromScene: OpenUrlFromScene) -> Bool {
        return true
    }
    
    func open(_ url: URL!, fromScene: OpenUrlFromScene, uniqueID: OPAppUniqueID?, from fromController: UIViewController?) {
    }
    
    func openInternalWebView(_ url: URL!, uniqueID: OPAppUniqueID?, from controller: UIViewController?) -> Bool {
        return true
    }
    
    func filePicker(_ maxSelectedCount: Int, pickerTitle title: String?, pickerComfirm comfirm: String?, uniqueID: OPAppUniqueID?, from fromController: UIViewController?, block: @escaping (Bool, [[AnyHashable : Any]]?) -> Void) {
    }
    
    func handleQRCode(_ qrCode: String!, uniqueID: OPAppUniqueID?, from fromController: UIViewController?) -> Bool {
        return true
    }
    
    func checkWatermark() -> Bool {
        return true
    }
    
    func hasWatermark() -> Bool {
        return true
    }
    
    func docsPickerTitle(_ title: String!, maxNum num: Int, confirm: String!, uniqueID: OPAppUniqueID?, from fromController: UIViewController?, block: (([AnyHashable : Any]?, Bool) -> Void)!) {
    }
    
    func passwordVerify(for uniqueID: OPAppUniqueID?, block: (([String : Any]?) -> Void)!) {
    }
    
    func chooseChat(_ params: [String : Any]!, title: String!, selectType type: Int, uniqueID: OPAppUniqueID?, from controller: UIViewController?, block: (([String : Any]?, Bool) -> Void)!) {
    }
    
    func getChatInfo(_ chatId: String!) -> [AnyHashable : Any]! {
        return [:]
    }
    
    func getAtInfo(_ chatId: String!, block: (([AnyHashable : Any]?) -> Void)!) {
    }
    
    func onBadgeChange(_ chatId: String!, block: (([String : Any]?) -> Void)!) {
    }
    
    func offBadgeChange(_ chatId: String!) {
    }
    
    func openAboutVC(with uniqueID: OPAppUniqueID?, appVersion: String) {
    }
    
    func openMineAboutVC(with uniqueID: OPAppUniqueID?, from controller: UIViewController?) {
    }
    
    func appName() -> String! {
        return ""
    }
    
    func getUserInfoExSuccess(_ success: (([String : Any]?) -> Void)!, fail: (() -> Void)!) {
    }
    
    func getTriggerContext(withTriggerCode triggerCode: String, block: EMATriggerContextResultBlock? = nil) {
        block?(["chatID": "chatID"])
    }
    
    func sendMessageCard(with uniqueID: OPAppUniqueID?, scene: String, triggerCode: String?, chatIDs: [String]?, cardContent: [AnyHashable : Any], withMessage: Bool, block: EMASendMessageCardResultBlock? = nil) {
        block?(.noError, "test", [], [], [])
    }
    
    func chooseSendCard(with uniqueID: OPAppUniqueID?, cardContent: [AnyHashable : Any], withMessage: Bool, params: OPFoundation.SendMessagecardChooseChatParams, res: @escaping EMASendMessageCardResultBlock) {
    }
    
    func monitorService(_ service: String, metricsData: [AnyHashable : Any], categoriesData: [AnyHashable : Any], platform: OPMonitorReportPlatform) {
    }
    
    func setHMDInjectedInfoWith(_ notification: Notification!, localLibVersionString: String!) {
    }
    
    func removeHMDInjectedInfo() {
    }
    
    func hostDeviceID() -> String {
        return ""
    }
    
    func getExperimentValue(forKey key: String, withExposure: Bool) -> Any? {
        return ["use": true]
    }
    
    func onServerBadgePush(_ appId: String, subAppIds: [String], completion: @escaping ((AppBadgeNode) -> Void)) {
    }
    
    func offServerBadgePush(_ appId: String, subAppIds: [String]) {
    }
    
//    func updateAppBadge(_ appID: String!, appType: BDPType, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
//    }
    
    func updateAppBadge(_ appID: String!, appType: BDPType, badgeNum: Int, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)) {
    }
    
//    func pullAppBadge(_ appID: String!, appType: BDPType, extra: PullBadgeRequestParameters?, completion: ((PullAppBadgeNodeResponse?, Error?) -> Void)?) {
//    }
    
    func openSDKPreview(_ fileName: String!, fileUrl: URL!, fileType: String!, fileID: String!, showMore: Bool, from: UIViewController!, thirdPartyAppID: String!, padFullScreen: Bool) {
    }
    
    func snsShare(_ controller: UIViewController!, appID: String!, channel: String!, contentType: String!, traceId: String!, title: String!, url: String!, desc: String!, imageData: Data!, successHandler: @escaping () -> Void, failedHandler: @escaping (Error?) -> Void) {
    }
    
    func registerWorkerInterpreters() -> [AnyHashable : Any]? {
        return nil
    }
}
