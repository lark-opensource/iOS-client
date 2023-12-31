//
//  PushCardFloatingBox.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/9/26.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkPushCard
import LKWindowManager

final class UrgencyFloatingBox: UIControl {
    lazy var cardArchives: [Cardable] = [] {
        didSet {
            self.setText(text: "\(cardArchives.count)")
        }
    }

    private let imageView = UIImageView()
    private let label = UILabel()
    private var urgencyLayer = UrgencyBoxLayer(frame: .zero)

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 72, height: 40))
        self.isHidden = true
        self.commonInit()
        self.addTarget(self, action: #selector(clickUrgencyFloatingBox(_:)), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        self.imageView.image = UDIcon.getIconByKey(.buzzFilled,
                                                   iconColor: UIColor.ud.functionDangerContentDefault,
                                                   size: CGSize(width: 16, height: 16))
        self.addSubview(self.imageView)

        self.imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(6)
        }

        imageView.layer.cornerRadius = 15.0
        imageView.contentMode = .center
        imageView.isUserInteractionEnabled = false
        imageView.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        self.label.textColor = UIColor.ud.primaryOnPrimaryFill
        self.label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        self.addSubview(self.label)
        self.label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-9.5)
            make.left.equalTo(self.imageView.snp.right).offset(9)
        }
        self.label.isUserInteractionEnabled = false
    }

    override var bounds: CGRect {
        didSet {
            self.urgencyLayer.removeFromSuperlayer()
            self.urgencyLayer = UrgencyBoxLayer(frame: self.bounds)
            self.layer.insertSublayer(self.urgencyLayer, at: 0)
        }
    }

    func setText(text: String) {
        self.label.text = text
    }

    override public var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = Cons.cardFloatingHeight
        return size
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.remakeBoxConstraints()
    }

    func remakeBoxConstraints() {
        guard self.superview != nil else { return }
        guard let interfaceOrientation = Utility.getCurrentInterfaceOrientation() else { return }
        self.snp.remakeConstraints { make in
            if interfaceOrientation == .landscapeLeft, UIDevice.current.userInterfaceIdiom == .phone {
                make.left.equalToSuperview()
                make.height.equalTo(Cons.cardFloatingHeight)
                make.bottom.equalTo(-Cons.cardFloatingBottom)
            } else {
                make.right.equalToSuperview()
                make.height.equalTo(Cons.cardFloatingHeight)
                make.bottom.equalTo(-Cons.cardFloatingBottom)
            }
        }
        self.layoutIfNeeded()
        UrgencyManager.urgentBoxToggled(urgencyBox: self, showed: true)
    }

    func presentBox(animated: Bool = true) {
        self.layoutIfNeeded()
        let orientation = Utility.getCurrentInterfaceOrientation() ?? .portrait
        let transform = CGAffineTransform(
            translationX: (orientation == .landscapeLeft && UIDevice.current.userInterfaceIdiom == .phone) ? -self.bounds.width : self.bounds.width,
            y: 0
        )
        self.transform = transform
        self.isHidden = false
        self.layoutIfNeeded()
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.transform = .identity
            }) { _ in
                UrgencyManager.urgentBoxToggled(urgencyBox: self, showed: true)
            }
        } else {
            self.transform = .identity
        }
    }

    func dismissBox(animated: Bool = true, completion: (() -> Void)? = nil) {
        let orientation = Utility.getCurrentInterfaceOrientation() ?? .portrait
        let transform = CGAffineTransform(
            translationX: (orientation == .landscapeLeft && UIDevice.current.userInterfaceIdiom == .phone) ? -self.bounds.width : self.bounds.width,
            y: 0
        )
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.transform = transform
            }, completion: { [weak self] _ in
                self?.isHidden = true
                UrgencyManager.urgentBoxToggled(urgencyBox: self, showed: false)
                completion?()

            })
        } else {
            self.transform = transform
            self.isHidden = true
            UrgencyManager.urgentBoxToggled(urgencyBox: self, showed: false)
            completion?()

        }
    }

    @objc
    func clickUrgencyFloatingBox(_ sender: UIControl) {
        let postModel = { [weak self] in
            guard let self = self else { return }
            PushCardCenter.shared.post(self.cardArchives)
            self.cardArchives.removeAll()
            self.dismissBox(animated: true) { [weak self] in
                self?.window?.removeFromSuperview()
            }
        }

        if Thread.isMainThread {
            postModel()
        } else {
            DispatchQueue.main.async {
                postModel()
            }
        }
    }
}

extension UrgencyFloatingBox {
    enum Cons {
        /// 悬浮球高度
        static var cardFloatingHeight: CGFloat {
            return 40
        }
        /// 悬浮球底部距离
        static var cardFloatingBottom: CGFloat {
            return UIDevice.current.userInterfaceIdiom == .pad ? 208 : 190
        }

        /// 出现键盘时，距离键盘距离
        static var keyboardOffset: CGFloat {
            return UIDevice.current.userInterfaceIdiom == .pad ? 120 : 102
        }
    }
}
