//
//  LarkMailShareInterfaceImpl.swift
//  Lark
//
//  Created by NewPan on 2021/8/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

#if MessengerMod
import Foundation
import LarkForward
import RxSwift
import Swinject
import LarkMailInterface
import LarkContainer

protocol Into {
    associatedtype T
    func into() -> T
}

extension LarkMailShareEmlAction: Into {
    typealias T = ShareEmlAction
    func into() -> T {
        switch self {
        case .open(let entry): return ShareEmlAction.open(entry.into())
        }
    }
}

extension LarkMailShareEmlEntry: Into {
    typealias T = ShareEmlEntry
    func into() -> T {
        ShareEmlEntry(data: self.data, from: self.from)
    }
}

struct LarkMailShareError: Error {
    var message: String
}

final class LarkMailShareInterfaceImpl: LarkMailShareInterface {
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func onShareEml(action: LarkMailShareEmlAction) -> RxSwift.Observable<()> {
        guard let impl = try? resolver.resolve(assert: LarkMailInterface.self)
        else {
            return RxSwift.Observable.error(LarkMailShareError(message: "LarkMailInterface is nil"))
        }

        return impl.onShareEml(action: action.into())
    }
}
#endif
