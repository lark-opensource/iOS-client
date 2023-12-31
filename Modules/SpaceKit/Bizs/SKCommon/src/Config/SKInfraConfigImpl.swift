//
//  SKInfraConfigImpl.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/4/13.
//

import Foundation
import SKInfra
import RxSwift
import RxRelay

public final class SKInfraConfigImpl {

    public static let shared = SKInfraConfigImpl()

    private init() { }

    public func config() {
        SKInfraConfig.shared.delegate = self
    }
}

extension SKInfraConfigImpl: SKInfraConfigDelegate {
    
    public var canReloadRnObserverable: RxRelay.BehaviorRelay<Bool> {
        return RNManager.manager.canReloadRnObserverable
    }
    
    public var isReadingLocalJSFile: RxRelay.BehaviorRelay<Bool> {
        return ResourceService.isReadingLocalJSFile
    }
    
    public var offlineSynIdle: RxRelay.BehaviorRelay<Bool> {
        return DocsOfflineSyncManager.shared.offlineSynIdle
    }
    
    public var isUseSimplePackage: Bool {
        return DocsDebugConstant.isUseSimplePackage
    }
}
