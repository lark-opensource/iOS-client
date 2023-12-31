//
//  NotificationDiagnosisAPI.swift
//  LarkSDKInterface
//
//  Created by 姚启灏 on 2022/3/14.
//

import Foundation
import RxSwift
import ServerPB
import RustPB

public protocol NotificationDiagnoseAPI {

    // 发送测试信息
    func sentDiagnoseMessage() -> Observable<RustPB.Im_V1_SendDiagnosticMessageResponse>

    func sendDiagnoseEvent(ID: String, name: String, params: [RustPB.Im_V1_SendDiagnosticEventRequest.Param]) -> Observable<Void>

    func fetchDiagnoseMessageConfig() -> Observable<ServerPB_Messages_DiagnoseMessageConfigResponse>
}
