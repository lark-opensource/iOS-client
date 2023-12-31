//
//  EdgeTabBar+Info.swift
//  LarkNavigation
//
//  Created by yaoqihao on 2023/6/15.
//

import AnimatedTabBar
import Foundation
import SnapKit

class InfoHitTestView: UIView {
    weak var associateView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self { return associateView }
        return hitView
    }
}

class EdgeTabBarInfoView: UIView {
    var tabbarLayoutStyle: EdgeTabBarLayoutStyle = .vertical {
        didSet {
            updateUI()
        }
    }

    private weak var avatar: UIView?

    private weak var focusView: UIView?

    private weak var searchEntrenceOnPadView: UIView?

    private var avatarHitTestView = InfoHitTestView()

    private var focusHitTestView = InfoHitTestView()

    private var focusContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.6)
        view.layer.cornerRadius = 12
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(avatarHitTestView)
        self.addSubview(focusHitTestView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addAvatar(_ container: UIView) {
        self.avatar?.removeFromSuperview()

        self.addSubview(container)
        self.avatar = container
        self.avatarHitTestView.associateView = container

        self.updateUI()
    }

    func addFocus(_ container: UIView) {
        removeFocus()

        self.addSubview(focusContainer)
        self.sendSubviewToBack(focusContainer)
        container.removeFromSuperview()
        focusContainer.addSubview(container)
        self.focusView = container

        self.focusHitTestView.associateView = container

        self.updateUI()
    }

    func removeFocus() {
        self.focusView?.removeFromSuperview()
        self.focusView = nil
        for subview in focusContainer.subviews {
            subview.removeFromSuperview()
        }
        focusContainer.removeFromSuperview()

        self.updateUI()
    }

    func addSearchEntrenceOnPad(_ container: UIView) {
        self.searchEntrenceOnPadView?.removeFromSuperview()
        self.addSubview(container)
        self.searchEntrenceOnPadView = container
        self.updateUI()
    }

    func removeSearchEntrenceOnPad() {
        self.searchEntrenceOnPadView?.removeFromSuperview()
        self.searchEntrenceOnPadView = nil
        self.updateUI()
    }

    private func updateUI() {
        guard let avatar = avatar else { return }
        focusContainer.isHidden = focusView == nil
        focusHitTestView.isHidden = focusView == nil
        let searchEntranceOnPadViewIsHidden = self.searchEntrenceOnPadView == nil

        /// avatar 可能加载naviBar上，加上superView判断，确保在NaviBar时候不会被更新，否则约束就不对了
        if (avatar.superview == self) {
            let padding = self.tabbarLayoutStyle == .horizontal ? 12 : 16
            avatar.snp.remakeConstraints { (make) in
                make.width.height.equalTo(40)
                make.top.equalTo(34)
                make.left.equalTo(padding)
                if focusContainer.isHidden, searchEntranceOnPadViewIsHidden {
                    make.bottom.equalToSuperview()
                }
            }
        }

        switch self.tabbarLayoutStyle {
        case .horizontal:
            if (avatar.superview == self) {
                avatarHitTestView.snp.remakeConstraints { make in
                    make.top.equalTo(avatar.snp.top).offset(-8)
                    make.left.equalTo(avatar.snp.left).offset(-8)
                    make.right.equalTo(avatar.snp.right).offset(8)
                    make.bottom.equalTo(avatar.snp.bottom).offset(8)
                }
            }
            
            if let focusView = focusView, focusView.superview == focusContainer {
                focusContainer.isHidden = false
                focusContainer.snp.remakeConstraints { (make) in
                    make.top.equalTo(34)
                    make.width.equalTo(60)
                    make.height.equalTo(40)
                    if searchEntranceOnPadViewIsHidden {
                        make.bottom.equalToSuperview()
                    }
                    make.left.equalTo(36)
                    make.right.lessThanOrEqualToSuperview()
                }

                focusView.snp.remakeConstraints { (make) in
                    make.top.right.bottom.equalToSuperview().inset(10)
                    make.width.equalTo(focusView.snp.height)
                }

                focusHitTestView.snp.remakeConstraints { make in
                    make.top.equalTo(avatarHitTestView.snp.top)
                    make.bottom.equalTo(avatarHitTestView.snp.bottom)
                    make.right.equalTo(focusContainer.snp.right).offset(8)
                    make.left.equalTo(avatarHitTestView.snp.right)
                }
            }
            if let searchEntrenceOnPadView = searchEntrenceOnPadView, searchEntrenceOnPadView.superview == self {
                searchEntrenceOnPadView.snp.remakeConstraints { make in
                    make.height.equalTo(42)
                    make.left.equalToSuperview().offset(8)
                    make.right.equalToSuperview().offset(-8)
                    make.bottom.equalToSuperview()
                    make.top.equalTo(avatarHitTestView.snp.bottom).offset(16)
                }
            }
        case .vertical:
            if (avatar.superview == self) {
                avatarHitTestView.snp.remakeConstraints { make in
                    make.top.equalTo(avatar.snp.top).offset(-8)
                    make.left.equalToSuperview().offset(8)
                    make.right.equalToSuperview().offset(-8)
                    make.bottom.equalTo(avatar.snp.bottom).offset(8)
                }
            }
            if let focusView = focusView, focusView.superview == focusContainer {
                focusContainer.isHidden = false
                focusContainer.snp.remakeConstraints { (make) in
                    make.left.equalTo(16)
                    make.width.equalTo(40)
                    make.height.equalTo(60)
                    make.top.equalTo(54)
                    if searchEntranceOnPadViewIsHidden {
                        make.bottom.equalToSuperview()
                    }
                }

                focusView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview().inset(10)
                    make.height.equalTo(focusView.snp.width)
                }

                focusHitTestView.snp.remakeConstraints { make in
                    make.top.equalTo(avatarHitTestView.snp.bottom)
                    make.bottom.equalTo(focusContainer.snp.bottom).offset(8)
                    make.left.equalTo(avatarHitTestView.snp.left)
                    make.right.equalTo(avatarHitTestView.snp.right)
                }
            }
            if let searchEntrenceOnPadView = searchEntrenceOnPadView, searchEntrenceOnPadView.superview == self {
                searchEntrenceOnPadView.snp.remakeConstraints { make in
                    make.height.equalTo(42)
                    make.left.equalToSuperview().offset(8)
                    make.right.equalToSuperview().offset(-8)
                    make.bottom.equalToSuperview()
                    if focusContainer.isHidden {
                        make.top.equalTo(avatarHitTestView.snp.bottom).offset(16)
                    } else {
                        make.top.equalTo(focusContainer.snp.bottom).offset(16)
                    }
                }
            }
        @unknown default:
            break
        }
    }
}
