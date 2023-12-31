//
//  DocsRustNetStatus.swift
//  SKFoundation
//
//  Created by bupozhuang on 2021/10/25.
//

import Foundation
import RustPB
import RxSwift
import RxCocoa

// 监听网络质量
public typealias RustNetStatus = RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus
public protocol DocsRustNetStatusService {
    var status: BehaviorRelay<RustNetStatus> { get }
}

public final class DocsRustNetStatus: DocsRustNetStatusService {
    private let bag = DisposeBag()
    public var status: BehaviorRelay<RustNetStatus>
    public init(statusObservable: Observable<RustNetStatus>) {
        status = BehaviorRelay<RustNetStatus>(value: .excellent)
        statusObservable.bind(to: status).disposed(by: bag)
    }
}
