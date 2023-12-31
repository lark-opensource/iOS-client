//
//  LoadFinishService.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/19.
//

import SKFoundation

class LoadFinishService: WASimpleContainerBridgeService {
    
    override var name: WABridgeName {
        .loadFinish
    }
    
    override func handle(invocation: WABridgeInvocation) {
        guard let loadStatus =
                try? CodableUtility.decode(LoadFinishData.self, withJSONObject: invocation.params) else {
            Self.logger.error("LoadFinish params err", tag: "[Open]")
            assertionFailure()
            let error = WALoadError.webError(showPage: false, err: NSError(domain: "webError", code: Self.invalidParam))
            self.container?.loader?.updateLoadStatus(.error(error))
            return
        }
        
        Self.logger.info("web load finish \(loadStatus.success), \(loadStatus)", tag: "[Open]")
        if loadStatus.success {
            self.container?.loader?.updateLoadStatus(.success)
        } else {
            let webError = NSError(domain: "webError", code: loadStatus.code)
            let error = WALoadError.webError(showPage: loadStatus.showErrorPage ?? false, err: webError)
            self.container?.loader?.updateLoadStatus(.error(error))
        }
    }
}

extension LoadFinishService {
    static let invalidParam = -100000
    
    struct LoadFinishData: Codable {
        let code: Int
        let showErrorPage: Bool?
        let errorMessage: String?
        
        var success: Bool {
            self.code == 0
        }
    }
}
