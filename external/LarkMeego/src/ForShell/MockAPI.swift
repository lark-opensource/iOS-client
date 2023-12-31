//
//  MockAPI.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/1/22.
//

import Foundation
import RxSwift

final public class MockMeegoAPI: MeegoAPI {
    public init() {}

    public func fetchMeegoEntranceEnable() -> RxSwift.Observable<Bool> {
        return .just(true)
    }

    public func fetchRouteSettings(fields: [String]) -> RxSwift.Observable<[String: String]> {
        return .just([:])
    }
}
