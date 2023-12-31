import ECOProbeMeta

final class PassportMonitorMetaAuthorization: OPMonitorCodeBase {
    
    private init(code: Int, message: String) {
        super.init(domain: "client.monitor.passport.auth", code: code, level: .normal, message: message)
    }
}

extension PassportMonitorMetaAuthorization {
    
    static let authorizationEnter = PassportMonitorMetaAuthorization(code: 10000, message: "auth_enter")
    
    static let startAuthorizationScan = PassportMonitorMetaAuthorization(code: 10001, message: "start_auth_scan")
    
    static let authorizationScanResult = PassportMonitorMetaAuthorization(code: 10002, message: "auth_scan_result")
    
    static let startAuthorizationConfirm = PassportMonitorMetaAuthorization(code: 10003, message: "start_auth_confirm")
    
    static let authorizationConfirmResult = PassportMonitorMetaAuthorization(code: 10004, message: "auth_confirm_result")
    
    static let startAuthorizationCancel = PassportMonitorMetaAuthorization(code: 10005, message: "start_auth_cancel")
    
    static let authorizationCancelResult = PassportMonitorMetaAuthorization(code: 10006, message: "auth_cancel_result")
}
