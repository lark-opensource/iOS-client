//
//  LoadConfigDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/18.
//

import Foundation
import SwiftProtobuf
import RxSwift

protocol LoadConfigDependency {
    // TODO: 待梳理
    func sendAsyncRequest(_ request: Message) -> Observable<[String: String]>
}
