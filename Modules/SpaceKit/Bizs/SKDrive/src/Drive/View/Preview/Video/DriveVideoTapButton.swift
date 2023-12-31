//
//  DriveVideoTapButton.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/12/27.
//

import UIKit
import SKFoundation

class DriveVideoTapButton: UIButton, UIGestureRecognizerDelegate {
    // 处理同层渲染下，iPad pointer无法点击播放按钮问题， 通过tap事件解决，同时让同层渲染框架修复
    private weak var myTarget: AnyObject?
    private var myAction: Selector?
    private lazy var singleTap: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.addTarget(self, action: #selector(didTap))
        tap.delegate = self
        return tap
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        guard controlEvents.contains(.touchUpInside) else {
            spaceAssertionFailure("only support touch up inside")
            return
        }
        self.myTarget = target as AnyObject?
        self.myAction = action
    }
    
    @objc
    private func didTap() {
        guard let tar = myTarget, let sel = myAction else {
            return
        }
        _ = tar.perform(sel, with: self)
    }
    
    private func setupUI() {
        self.addGestureRecognizer(singleTap)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
