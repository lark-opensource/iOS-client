//
//  RustNotificationDiagnoseAPI.swift
//  LarkSDK
//
//  Created by 姚启灏 on 2022/3/14.
//

import Foundation
import LarkSDKInterface
import RustPB
import ServerPB
import RxSwift
import LarkReleaseConfig

final class RustNotificationDiagnoseAPI: LarkAPI, NotificationDiagnoseAPI {

    func sentDiagnoseMessage() -> Observable<RustPB.Im_V1_SendDiagnosticMessageResponse> {
        var request = RustPB.Im_V1_SendDiagnosticMessageRequest()
        request.type = .text
        return client.sendAsyncRequest(request)
    }

    func sendDiagnoseEvent(ID: String, name: String, params: [RustPB.Im_V1_SendDiagnosticEventRequest.Param]) -> Observable<Void> {
        var request = RustPB.Im_V1_SendDiagnosticEventRequest()
        var eventInfo = RustPB.Im_V1_SendDiagnosticEventRequest.EventInfo()
        var eventParams = RustPB.Im_V1_SendDiagnosticEventRequest.Params()
        eventParams.params = params
        eventInfo.params = eventParams
        request.eventInfo = eventInfo
        request.eventName = name
        request.id = ID
        return client.sendAsyncRequest(request)
    }

    func fetchDiagnoseMessageConfig() -> Observable<ServerPB_Messages_DiagnoseMessageConfigResponse> {
        var request = ServerPB_Messages_DiagnoseMessageConfigRequest()
        request.packageAppID = Int64(ReleaseConfig.appId) ?? -1
        return client.sendPassThroughAsyncRequest(request, serCommand: .diagnoseMessageConfig)
    }
}
