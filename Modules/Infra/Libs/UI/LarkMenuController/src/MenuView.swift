//
//  MenuView.swift
//  LarkMenuController
//
//  Created by 李晨 on 2019/6/11.
//

import UIKit
import Foundation

protocol MenuViewDelegate: AnyObject {

    // 判断是否由 menu view 响应 hittest
    // 返回 true 进行下一步判断
    // 返回 false 直接不响应 hittest
    func recognitionTouchIn(_ view: MenuView, _ point: CGPoint) -> Bool

    // 返回 响应 hittest 事件的 view
    func recognitionHitTest(_ view: MenuView, _ point: CGPoint) -> UIView?
}

final class MenuView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !penetrable, let delegate = self.delegate, delegate.recognitionTouchIn(self, point) {
            if let hitView = self.delegate?.recognitionHitTest(self, point) { return hitView }
            return super.hitTest(point, with: event)
        }
        return nil
    }

    weak var delegate: MenuViewDelegate?
    var penetrable: Bool = false // 穿透性 如果这个值为 true，hitTest 返回 nil

    init(delegate: MenuViewDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
