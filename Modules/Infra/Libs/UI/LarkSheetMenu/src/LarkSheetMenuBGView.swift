//
//  LarkSheetMenuBGView.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/24.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignShadow
import SnapKit
final class LarkSheetMenuBGView: UIView {
    var penetrable: Bool = false
    var handleTouchView: ((CGPoint, UIViewController) -> UIView?)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !penetrable,
           let delegate = self.delegate,
           delegate.recognitionTouchIn(self, point) {
            if let hitView = self.delegate?.recognitionHitTest(self, point) {
                return hitView
            }
            return super.hitTest(point, with: event)
        }
        return nil
    }

    weak var delegate: MenuViewTouchDelegate?

    private var blurView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .ud.bgMask
        view.alpha = 0
        return view
    }()

    func changeBackGroundAlphaTo(_ alpha: CGFloat) {
        blurView.alpha = alpha * 0.7
        layer.shadowOpacity = Float(1 - alpha) * 0.25
    }

    init(delegate: MenuViewTouchDelegate, shadowDown: Bool) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        superview?.layer.cornerRadius = 8
        if shadowDown {
            layer.ud.setShadow(type: UDShadowType(x: 0, y: 0, blur: 40, spread: 0, color: UDShadowColorTheme.s5DownColor, alpha: 0.3), shouldRasterize: false)
        } else {
            layer.ud.setShadow(type: UDShadowType(x: 0, y: 0, blur: 4, spread: 0, color: .ud.staticBlack, alpha: 0.25), shouldRasterize: false)

        }
        isUserInteractionEnabled = true
        self.delegate = delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MenuViewTouchDelegate: AnyObject {
    // 判断是否由 menu view 响应 hittest
    // 返回 true 进行下一步判断
    // 返回 false 直接不响应 hittest
    func recognitionTouchIn(_ view: LarkSheetMenuBGView, _ point: CGPoint) -> Bool

    // 返回 响应 hittest 事件的 view
    func recognitionHitTest(_ view: LarkSheetMenuBGView, _ point: CGPoint) -> UIView?
}

extension LarkSheetMenuController: MenuViewTouchDelegate {
    func recognitionTouchIn(_ view: LarkSheetMenuBGView, _ point: CGPoint) -> Bool {
        // 如果子视图(两种menuview)可以接收事件，则响应触控
        // 局部选择菜单内点击
        if self.isInPartial && !partialView.isHidden && partialView.alpha == 1 {
            let point = view.convert(point, to: partialView)
            if partialView.hitTest(point, with: nil) != nil {
                return true
            }
        }

        // 全选菜单内点击
        if !self.isInPartial && !menuView.isHidden && menuView.alpha == 1 {
            let point = view.convert(point, to: menuView)
            if menuView.hitTest(point, with: nil) != nil {
                return true
            }
        }

        if !_enableTransmitTouch {
            return true
        }

        // handleTouchArea内点击
        if let handleTouchArea = self._handleTouchArea,
            handleTouchArea(point, self) {
            return false
        }

        // handleTouchArea内点击
        if let handleTouchView = self._handleTouchView,
            handleTouchView(point, self) != nil {
            return true
        }

        // 因为手势的响应级别低于系统控件， 所以这里判断是否下一层返回的是不是 UIControl
        // 如果返回的是 以下 UIControl 的一种 则在 menuView 截获手势， 最终由 tap 手势响应
        let controlSet: [AnyClass] = [
            UIButton.self, UISwitch.self, UISegmentedControl.self,
            UIStepper.self, UIPageControl.self, UISlider.self,
            UISwitch.self, UITextView.self, UITextField.self]
        view.penetrable = true
        defer { view.penetrable = false }
        if let superview = view.superview {
            let superPoint = view.convert(point, to: superview)
            if let hitView = superview.hitTest(superPoint, with: nil),
                controlSet.contains(where: { hitView.isKind(of: $0) }) {
                return true
            }
        }

        return false
    }

    func recognitionHitTest(_ view: LarkSheetMenuBGView, _ point: CGPoint) -> UIView? {
        // 菜单内点击
        for subview in view.subviews where !subview.isHidden && subview.alpha == 1 && subview.isUserInteractionEnabled {
            let point = view.convert(point, to: subview)
            if let hitView = subview.hitTest(point, with: nil) {
                return hitView
            }
        }

        if !_enableTransmitTouch {
            return view
        }

        // handleTouchView内点击
        if let handleTouchView = self._handleTouchView,
            let hitView = handleTouchView(point, self) {
            return hitView
        }
        return nil
    }
}
