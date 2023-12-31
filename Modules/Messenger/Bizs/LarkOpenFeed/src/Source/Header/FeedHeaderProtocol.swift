//
//  FeedHeaderProtocol.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public protocol FeedHeaderItemViewModelProtocol {
    var displayDriver: Driver<Bool> { get } // 是否显示
    var updateHeightDriver: Driver<CGFloat> { get } // 高度变化
    var display: Bool { get }
    var viewHeight: CGFloat { get }
    var type: FeedHeaderItemType { get }
    func fireWidth(_ width: CGFloat)
}

public extension FeedHeaderItemViewModelProtocol {
    func fireWidth(_ width: CGFloat) {}
}
