//  Created by weidong fu on 7/4/2018.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra
import SpaceInterface

class NotifyReadyService: BaseJSService {
    func jsService(_ jsService: NotifyReadyService, addPreloadType type: String) {
        model?.requestAgent.addPreloadType(type)
    }
}

extension NotifyReadyService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.notifyReady]
    }

    func handle(params: [String: Any], serviceName: String) {
        let webviewIdentify = (model == nil) ? "null" : model!.jsEngine.editorIdentity
        if let type = params["type"] as? String {
            var preloadStatus = PreloadStatus()
            preloadStatus.addType(type)
            PreloadStatistics.shared.endRecordPreload("\(webviewIdentify)",
                                                      hasLoadSomeThing: preloadStatus.hasLoadSomeThing,
                                                      statisticsStage: preloadStatus.statisticsStage ?? DocsType.unknownDefaultType.name,
                                                      hasComplete: preloadStatus.hasComplete)
            DocsLogger.info("\(webviewIdentify) mainFrameReady for \(type)", component: LogComponents.fileOpen)
            jsService(self, addPreloadType: type)
            model?.userResolver.docs.editorManager?.reportPreloadStatics()

            if type == "doc" {
                #if DEBUG
                if #available(iOS 12.0, *) {
                    os_signpost(.end, log: DocsSDK.openFileLog, name: "loadBlank")
                }
                #endif
                NotificationCenter.default.post(name: Notification.Name.Docs.preloadDocsFinished,
                                                object: nil,
                                                userInfo: nil )
            } else if type == "sheet" {
                ///Sheet支持多Key提前加载数据
                ///https://bytedance.feishu.cn/docs/doccn4Uiv88LRnIhfow5SLwkYng
                let keyArr = (params["data"] as? [String: Any]) ?? [:]
                CCMKeyValue.globalUserDefault.setDictionary(keyArr, forKey: UserDefaultKeys.sheetPreFetchData)
            }
        }
        let isConnected: Bool = (DocsNetStateMonitor.shared.accessType != .notReachable)

        let params = ["type": DocsNetStateMonitor.shared.accessType.rawValue, "connected": isConnected] as [String: Any]
               model?.jsEngine.callFunction(DocsJSCallBack.notityNetStatus, params: params, completion: nil)

        if DocsSDK.isBeingTest {
            NotificationCenter.default.post(name: Notification.Name.PreloadTest.preloadok,
                                            object: nil,
                                            userInfo: [Notification.DocsKey.editorIdentifer: model!.jsEngine.editorIdentity] )
        }
    }
}
