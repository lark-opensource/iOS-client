//
//  LarkInterface+Advertising.swift
//  LarkTourInterface
//
//  Created by Meng on 2020/4/17.
//

import Foundation

/// 投放相关服务，业务可以根据投放内容做场景化适配
public protocol AdvertisingService: AnyObject {
    /// 投放来源, 可取值如 vc, spm, okr等
    var source: String? { get }

    var hasSource: Bool { get }
}

extension AdvertisingService {
    public var hasSource: Bool {
        return source != nil
    }
}
