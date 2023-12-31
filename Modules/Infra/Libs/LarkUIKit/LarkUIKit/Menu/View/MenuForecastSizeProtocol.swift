//
//  MenuForecastSizeProtocol.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/24.
//

import Foundation
import UIKit

@objc
/// 菜单计算大小的协议，提供计算视图大小的方法
public protocol MenuForecastSizeProtocol {
    /// 计算视图的预期大小
    func forecastSize() -> CGSize

    /// 根据父视图的建议大小返回最终的期望大小
    /// - Parameter suggestionSize: 父视图给的建议大小
    /// - Returns : 返回根据自己调整后的建议大小
    func reallySize(for suggestionSize: CGSize) -> CGSize
}
