//
//  V3JoinTenantScanViewModel.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/2.
//

import Foundation
import RxSwift

class V3JoinTenantScanViewModel: V3JoinTenantBaseViewModel {

    let joinTenantScanInfo: V4JoinTenantScanInfo

    //是否需要发起请求，当代理web端扫码时不需要请求
    let externalHandler: ((String) -> Void)?

    init(
        step: String,
        joinTenantScanInfo: V4JoinTenantScanInfo,
        api: JoinTeamAPIProtocol,
        context: UniContextProtocol,
        externalHandler: ((String) -> Void)? = nil
    ) {
        self.joinTenantScanInfo = joinTenantScanInfo
        self.externalHandler = externalHandler
        super.init(
            step: step,
            joinType: .scanQRCode,
            stepInfo: joinTenantScanInfo,
            api: api,
            context: context
        )
    }

    var qrUrl: String = ""
    
    override func getServerInfo() -> ServerInfo {
        return joinTenantScanInfo
    }

    public override func getParams() -> (teamCode: String?, qrUrL: String?, flowType: String?) {
        return (nil, qrUrl, self.joinTenantScanInfo.flowType)
    }
}

extension V3JoinTenantScanViewModel {
    var subtitle: NSAttributedString {
        if let subtitle = joinTenantScanInfo.subtitle {
            return subtitle.html2Attributed(font: UIFont.systemFont(ofSize: 14, weight: .medium))
        } else {
            return NSAttributedString(string: "")
        }
    }
}
