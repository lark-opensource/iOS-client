//
//  PadLargeModalViewController.swift
//  LarkUIKit
//
//  Created by liluobin on 2020/12/24.
//

import Foundation
import UIKit
import SnapKit
public final class PadLargeModalViewController: UIViewController, UIGestureRecognizerDelegate {

    public weak var delegate: PadLargeModalDelegate?
    public var childVC: UIViewController?
    private weak var childVCView: UIView?
    private lazy var containView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        self.view.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        return view
    }()

    /// 竖屏的高度 即屏幕的最长边
    private lazy var portraitHeight: CGFloat = {
        let size = UIScreen.main.bounds.size
        return max(size.width, size.height)
    }()

    private var hadShowAnimation = false

    public init() {
        super.init(nibName: nil, bundle: nil)
        /// 设置PresentationStyle
        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        let tapGesture = self.view.lu.addTapGestureRecognizer(action: #selector(onBackgroundClick), target: self)
        tapGesture.delegate = self
        if let child = self.childVC {
            self.addChildVC(child)
        }
    }

    public func dismissSelf() {
        self.clearBackgroundColor()
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func onBackgroundClick() {
        delegate?.padLargeModalViewControllerBackgroundClicked()
        dismissSelf()
    }

    public func clearBackgroundColor() {
        self.view.backgroundColor = .clear
    }

    private func addChildVC(_ vc: UIViewController) {
        self.addChild(vc)
        self.containView.addSubview(vc.view)
        vc.view.layer.cornerRadius = 10
        vc.view.clipsToBounds = true
        self.childVCView = vc.view
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.hadShowAnimation {
            return
        }
        self.hadShowAnimation = true
        /// 添加弹出的动画
        self.containView.snp.remakeConstraints { (make) in
            make.leading.trailing.height.equalToSuperview()
            make.top.equalTo(self.view.snp.bottom)
        }
        self.view.layoutIfNeeded()
        self.containView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        }
    }

   public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        self.autoLayoutForView(self.childVCView, isLandscape: isLandscape)
    }

    private func autoLayoutForView(_ view: UIView?, isLandscape: Bool) {
        guard let view = view else {
            return
        }
        if self.view.bounds.width < 732 {
            view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }
        if isLandscape {
            self.layoutForLandscape(view)
        } else {
            self.layoutForPortrait(view)
        }
    }

    /// 这里的iPad的尺寸 参考UI的设计规范
    private func layoutForPortrait(_ view: UIView) {
        view.snp.remakeConstraints { (make) in
            make.width.equalTo(712)
            make.width.lessThanOrEqualToSuperview().priority(.required)
            if self.portraitHeight > 1024 {
                make.height.equalTo(1006)
            } else {
                make.height.equalTo(936)
            }
            make.center.equalToSuperview()
        }
    }

    private func layoutForLandscape(_ view: UIView) {
        view.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(44)
            make.bottom.equalToSuperview().offset(-44)
            make.width.equalTo(712)
            make.width.lessThanOrEqualToSuperview().priority(.required)
            make.centerX.equalToSuperview()
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let childVCView = childVCView,
           touch.view?.isDescendant(of: childVCView) == true {
            return false
        }
        return true
    }
}

public protocol PadLargeModalDelegate: UIViewController {
func padLargeModalViewControllerBackgroundClicked()
}
