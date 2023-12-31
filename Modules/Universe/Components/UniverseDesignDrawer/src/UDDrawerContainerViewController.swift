//
//  UDDrawerContainerViewController.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import UIKit
import Foundation
import SnapKit

public final class UDDrawerContainerViewController: UIViewController {
    private let subView: UDDrawerContainerLifecycle?
    private let subVC: UIViewController?
    var contentWidth: CGFloat
    private lazy var container: UIView = UIView()
    private let direction: UDDrawerDirection
    public var transitionManager: UDDrawerTransitionManager? {
        didSet {
            self.transitioningDelegate = transitionManager
            // 反向注入，因为业务方关心的是UDDrawerTransitionManager
            transitionManager?.drawer = self
        }
    }

    private lazy var maskView: UIControl = {
        let maskView = UIControl()
        maskView.backgroundColor = UDDrawerValues.maskColor
        maskView.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        maskView.alpha = 0
        return maskView
    }()

    public init(subView: UDDrawerContainerLifecycle? = nil,
                subVC: UIViewController? = nil,
                contentWidth: CGFloat = UDDrawerValues.contentDefaultWidth,
                direction: UDDrawerDirection) {
        self.subView = subView
        self.subVC = subVC
        self.contentWidth = min(UDDrawerValues.contentMaxWidth, contentWidth)
        self.direction = direction
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGestureRecognizer()
        subView?.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subView?.viewWillAppear(animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        subView?.viewDidAppear(animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subView?.viewWillDisappear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        subView?.viewDidDisappear(animated)
    }

    private func setupViews() {
        self.view.clipsToBounds = true
        self.view.addSubview(container)
        container.clipsToBounds = true
        container.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            if direction == .left {
                make.leading.equalToSuperview().offset(-contentWidth)
            } else {
                make.trailing.equalToSuperview().offset(contentWidth)
            }
            make.width.equalTo(contentWidth)
        }

        if let subView = self.subView {
            container.addSubview(subView)
            subView.snp.makeConstraints { (make) in
                if direction == .left {
                    make.leading.top.bottom.equalToSuperview()
                } else {
                    make.trailing.top.bottom.equalToSuperview()
                }
                make.width.equalTo(subView.contentWidth)
            }
        }

        if let subVC = self.subVC {
            container.addSubview(subVC.view)
            subVC.view.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                if direction == .left {
                    make.trailing.equalToSuperview()
                    make.leading.equalTo(self.subView?.snp.trailing ?? container.snp.leading)
                } else {
                    make.leading.equalToSuperview()
                    make.trailing.equalTo(self.subView?.snp.leading ?? container.snp.trailing)
                }
            }
            self.addChild(subVC)
            subVC.didMove(toParent: self)
        }

        container.layer.shadowColor = UDDrawerValues.shadowColor.cgColor
        container.layer.shadowOffset = UDDrawerValues.shadowOffset
        container.layer.shadowRadius = UDDrawerValues.shadowRadius
        container.layer.shadowOpacity = UDDrawerValues.shadowOpacity

        view.insertSubview(maskView, at: 0)
        maskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func updateContentXPosition(to xPosition: CGFloat) {
        container.snp.updateConstraints { (make) in
            if direction == .left {
                make.leading.equalToSuperview().offset(xPosition)
            } else {
                make.trailing.equalToSuperview().offset(-xPosition)
            }
        }
        maskView.alpha = min(1, abs((contentWidth + xPosition) / contentWidth))
    }

    func updateDrawerWidth(contentWidth: CGFloat) {
        self.contentWidth = min(UDDrawerValues.contentMaxWidth, contentWidth)
        container.snp.updateConstraints { (make) in
            make.width.equalTo(self.contentWidth)
        }
    }
}

extension UDDrawerContainerViewController {
    private func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(pan:)))
        view.addGestureRecognizer(panGesture)
    }

    @objc
    private func handlePanGesture(pan: UIPanGestureRecognizer) {
        var offset = pan.translation(in: view).x
        var velocity = pan.velocity(in: view).x
        if direction == .left {
            offset = max(-contentWidth, min(0, offset))
        } else {
            offset = -max(0, min(offset, contentWidth))
            velocity = -velocity
        }

        switch pan.state {
        case .began:
            transitionManager?.state = .hidding
            break
        case .changed:
            updateContentXPosition(to: offset)
        case .ended, .cancelled, .failed:
            let offsetWorks = -offset > contentWidth * UDDrawerValues.offsetThreshold
            let velocityWorks = -velocity > UDDrawerValues.velocityThreshold
            (offsetWorks || velocityWorks) ? dismissSelf() : cancelDismiss()
        default: break
        }
    }

    @objc
    private func dismissSelf() {
        self.transitionManager?.state = .hidden
        UIView.animate(withDuration: UDDrawerValues.transitionDuration, delay: 0, options: [.curveEaseOut]) {
            self.updateContentXPosition(to: -self.contentWidth)
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }
    }

    private func cancelDismiss() {
        self.transitionManager?.state = .shown
        UIView.animate(withDuration: UDDrawerValues.transitionDuration, delay: 0, options: [.curveEaseOut]) {
            self.updateContentXPosition(to: 0)
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
        }
    }
}
