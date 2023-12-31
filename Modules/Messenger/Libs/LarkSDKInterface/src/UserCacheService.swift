//
//  LarkSDKInterface+UserSpace.swift
//  LarkSDKInterface
//
//  Created by Yuguo on 2018/5/16.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

public protocol UserCacheService {
    func calculateCacheSize() -> Observable<Float>
    func clearCache() -> Observable<Float>
}

public protocol DocsCacheDependency {
    func calculateCacheSize() -> Observable<Float>
    func clearCache() -> Observable<Void>
}
