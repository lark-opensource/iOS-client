//
//  ASLDebugDataManager.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/7/19.
//

import Foundation
import RxSwift
import RxCocoa

public protocol ASLContextIDProtocol {

    func contextIDOnNext(contextID: String)

    func getContextIDDriver() -> Driver<String>
}

final public class ASLDebugDataManager: ASLContextIDProtocol {

    private let debugContextID: PublishSubject<String>

    public init() {
        self.debugContextID = PublishSubject<String>()
    }

    public func contextIDOnNext(contextID: String) {
        debugContextID.onNext(contextID)
    }

    public func getContextIDDriver() -> Driver<String> {
        return debugContextID.asDriver(onErrorJustReturn: "")
    }
}
