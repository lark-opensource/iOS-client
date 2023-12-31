//
//  BDPAppPage+EditorExtension.swift
//  LarkMicroApp
//
//  Created by 新竹路车神 on 2020/9/9.
//
// swiftlint:disable all
import EEMicroAppSDK
import LKCommonsLogging
import LarkOPInterface
import SpaceInterface
import SwiftyJSON
import TTMicroApp
import WebKit
import LarkContainer

private let log = Logger.oplog(BDPAppPage.self, category: "BDPAppPageEditorExtension")
private var bdpAppPageAssociatedObjectKey: UInt8 = 0
func handlerBDPAppPageInit(with page: BDPAppPage) {
    let ske = BDPAppPage.editorFactory.createEditorDocsView(jsEngine: page, uiContainer: page, delegate: page, bridgeName: "editorBridge")
    ske.startObserver()
    objc_setAssociatedObject(page, &bdpAppPageAssociatedObjectKey, ske, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
func handlerBDPAppPageDealloc(with page: BDPAppPage) {
    (objc_getAssociatedObject(page, &bdpAppPageAssociatedObjectKey) as? SKEditorDocsViewObserverProtocol)?.removeObserver()
}

//  按照要求迁移原先对EditorWebView做的at数据请求扩展
extension BDPAppPage: SKEditorDocsViewRequestProtocol {
    
    @InjectedSafeLazy static var editorFactory: SKEditorDocsViewCreateInterface

    public func editorRequestMentionData(with key: String, success: @escaping ([MentionInfo]) -> Void) {
        /*
        guard let uniqueID = uniqueID else {
         */
        //  未修改任何逻辑 OC号称不为nil的不靠谱，必须判断一下
        guard uniqueID != nil else {
            log.error("request mention failed, uniqueID is nil")
            return
        }
        guard let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) else {
            log.error("request mention failed, bdpcommon is nil")
            return
        }
        let session = TMASessionManager.shared()?.getSession(common.sandbox) ?? ""
        guard !session.isEmpty else {
            log.error("request mention failed, session is empty, please call tt.login")
            return
        }
        let appID = uniqueID.appID
        guard !appID.isEmpty else {
            log.error("request mention failed, appid is empty")
            return
        }
        let params: [String: String] = [
            "keyword": key,
            "session": session,
            "appid": appID
        ]
        let tracing = EMARequestUtil.generateRequestTracing(uniqueID)

        func handleResult(
            json: [AnyHashable: Any]?,
            error: Error?
        ) {
            guard let json = json,
                let data = json["data"] as? [String: String],
                let dataStr = data["data"] else {
                    log.error("request mention failed, server error", error: error)
                    return
            }
            let models = JSON(parseJSON: dataStr).arrayValue
            var infos = [MentionInfo]()
            for model in models {
                let avatarUrl = model["avatar_url"].stringValue
                let department = model["department"].stringValue
                let enName = model["en_name"].stringValue
                let cnName = model["cn_name"].stringValue
                let isExternal = model["is_external"].stringValue
                let token = model["id"].stringValue
                let extra = [
                    "en_name": enName,
                    "cn_name": cnName,
                    "is_external": isExternal
                ]
                /// 展示的名字需要国际化
                var nameToShow: String
                let language = BDPApplicationManager.language() ?? ""
                if language == "zh_CN" {
                    nameToShow = cnName
                } else if language == "en_US" {
                    nameToShow = enName
                } else {
                    /// 默认英文
                    nameToShow = enName
                }
                /// token:和后端通信的唯一标志符，使用小程序后端返回的id，icon：头像url，name：显示的名字（国际化），detail：名字下面显示的信息，extra：其他信息
                let info = MentionInfo(token: token, icon: URL(string: avatarUrl), name: nameToShow, detail: department, extra: extra)
                infos.append(info)
            }
            success(infos)
        }
        
        let url = EMAAPI.editorSearchURL()
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.searchPeople) {
            OPECONetworkInterface.postForOpenDomain(url: url,
                                       context: OpenECONetworkAppContext(trace: tracing, uniqueId: uniqueID, source: .api),
                                       params: params,
                                       header: [:]) { json, _, _, error in
                handleResult(json: json, error: error)
            }
        } else {
            EMANetworkManager.shared().postUrl(url, params: params, completionWithJsonData: { (json, error) in
                handleResult(json: json, error: error)
            }, eventName: "requestMetionInfo", requestTracing: tracing)
        }
    }
}

// swiftlint:enable all
