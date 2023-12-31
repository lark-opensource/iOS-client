import SecGuard

class SecDelegate: NSObject, SGMSafeGuardDelegate {
    func sgm_sectoken(_ token: String) {
    
    }
    
    let did: String

    init(did: String) {
        self.did = did
    }

    // @override
    public func sgm_customDeviceID() -> String {
        return self.did
    }

    // @overide
    public func sgm_sessionID() -> String {
        return ""
    }

    // @overide
    public func sgm_installChannel() -> String {
        return ""
    }

}

public func standaloneUdid(domain: String, appID: String, did: String) -> [String: Any]? {
    let delegate = SecDelegate(did: did)
    let config = SGMSafeGuardConfig.init(domain: domain, appID: appID)

    let manager = SGMSafeGuardManager.shared()
    // apply delegate and config
    manager.sgm_start(with: config, delegate: delegate)

    return manager.sgm_standaloneUUID() as NSDictionary? as? [String: Any]
}
