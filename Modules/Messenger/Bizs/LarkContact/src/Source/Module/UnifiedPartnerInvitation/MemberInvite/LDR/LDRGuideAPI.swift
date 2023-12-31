//
//  LDRGuideAPI.swift
//  LarkContact
//
//  Created by mochangxing on 2021/4/2.
//

import Foundation
import RxSwift
import ServerPB

typealias GetLDRServiceAppLinkResponse = ServerPB_Flow_GetLDRServiceAppLinkResponse
typealias LDRFlowOption = ServerPB_Flow_Option
typealias GetOperationLinkResponse = ServerPB_Retention_GetOperationLinkResponse

protocol LDRGuideAPI {
    func getLDRService() -> Observable<(GetLDRServiceAppLinkResponse)>

    func reportEvent(eventKeyList: [String]) -> Observable<(Void)>

    func getOperationLink() -> Observable<(GetOperationLinkResponse)>
}
