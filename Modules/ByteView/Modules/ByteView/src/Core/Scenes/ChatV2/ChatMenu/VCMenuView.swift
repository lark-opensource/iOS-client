//
//  VCMenuView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

enum VCMenuViewHitTestResult {
    /// 不响应 hitTest
    case ignore
    /// 响应 hitTest，使用 UIKit 默认实现，即调用 super.hitTest
    case `default`
    /// 使用指定的 view 响应 hitTest
    case custom(UIView)
}

/**
 * VCMenuView 支持自定义可响应点击范围与对象。
 * 提供一个覆盖全屏 View，该 view 特定部分（可能是不规则形状、不定区域、或跟底层业务逻辑相关的）响应事件，其他部分透传给下层。
 * 具体做法是按照 hitTest 返回值来决定谁处理点击，一共有三种情况：
 * 1. shouldRespondTouchAt 返回 false，表示这部分 menu 视图完全不响应点击，透传给下面的业务
 * 2. shouldRespondTouchAt 内调用 menu 或其 superview 的 hitTest，依据其返回值来决定自身返回值
 * 3. shouldRespondTouchAt 返回 true，表示这次触摸要由 menu 响应。menu 会调用 super.hitTest 来决定响应者
 * 适用场景与用法参考 VCMenuViewController.swift。
 *
 * 以上三种情况在 VCMenuViewController 实现中分别对应：
 * 1. 除气泡、弹出 menu 之外其他部分触摸事件均由下层处理，即弹出 menu 时不影响底层 tableView 的滑动
 * 2. 当 menu 弹出时，如果用户点到了特定的系统控件，如 UITextField, UIButton 等，该事件不透传，而是 menu 内吃掉，防止因系统原因导致的选中态和 menu 展示出现不一致的情况
 * 3. 点击到菜单内部时，由菜单响应该点击事件
 */

protocol VCMenuViewDelegate: AnyObject {
    /// 判断是否由 menu view 响应 hitTest，以及决定响应者是谁（如果需要）。
    func menuView(_ menu: VCMenuView, shouldRespondTouchAt point: CGPoint) -> VCMenuViewHitTestResult
}

class VCMenuView: UIView {
    weak var delegate: VCMenuViewDelegate?
    private var isHitTesting = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // isHitTesting == true 时再次调用该方法，表明 delegate 在调用 hitTest，
        // 并依据该返回值来决定 delegate 自身的逻辑，因此此时假定 MenuView 不响应点击，即返回 nil
        guard !isHitTesting else { return nil }
        isHitTesting = true
        defer { isHitTesting = false }
        guard let result = delegate?.menuView(self, shouldRespondTouchAt: point) else { return nil }
        switch result {
        case .ignore: return nil
        case .default: return super.hitTest(point, with: event)
        case .custom(let view): return view
        }
    }
}
