//
//  SKInfraConfig.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/4/13.
//

import Foundation
import RxSwift
import RxRelay

public protocol SKInfraConfigDelegate: AnyObject {
    var isUseSimplePackage: Bool { get }
    
    var offlineSynIdle: BehaviorRelay<Bool> { get }
    
    var isReadingLocalJSFile: BehaviorRelay<Bool> { get }
    
    var canReloadRnObserverable: BehaviorRelay<Bool> { get }

}

public final class SKInfraConfig {

    public static let shared = SKInfraConfig()
    public weak var delegate: SKInfraConfigDelegate?
}

extension SKInfraConfig: SKInfraConfigDelegate {
    
    //Gecko相关
    public var canReloadRnObserverable: RxRelay.BehaviorRelay<Bool> {
        return delegate?.canReloadRnObserverable ?? BehaviorRelay(value: false)
    }
    
    public var isReadingLocalJSFile: RxRelay.BehaviorRelay<Bool> {
        return delegate?.isReadingLocalJSFile ?? BehaviorRelay(value: false)
    }
    
    public var offlineSynIdle: RxRelay.BehaviorRelay<Bool> {
        return delegate?.offlineSynIdle ?? BehaviorRelay(value: true)
    }
    
    public var isUseSimplePackage: Bool {
        return delegate?.isUseSimplePackage ?? false
    }
}
