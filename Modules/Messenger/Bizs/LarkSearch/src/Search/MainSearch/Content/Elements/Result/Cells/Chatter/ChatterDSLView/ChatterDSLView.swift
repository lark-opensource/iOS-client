//
//  ChatterDSLView.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/11/29.
//

import UIKit
import Foundation
import AsyncComponent

class ChatterDSLView: UIView {

    private var renderer: ASComponentRenderer?

    /// 更新cell
    ///
    /// - Parameters:
    ///   - renderer: 渲染引擎（包含布局等信息）
    ///   - cellId: cell的唯一标识（例如消息id）
    public func update(with renderer: ASComponentRenderer) {
        renderer.bind(to: self)
        UIView.setAnimationsEnabled(false)
        renderer.render(self)
        UIView.setAnimationsEnabled(true)
        self.renderer = renderer
        self.backgroundColor = UIColor.clear
    }

    /// 通过key获取cell上的view
    ///
    /// - Parameter key: 指定的cell的key
    /// - Returns: 对应的view
    public func getView(by key: String) -> UIView? {
        return renderer?.getView(by: key)
    }
}
