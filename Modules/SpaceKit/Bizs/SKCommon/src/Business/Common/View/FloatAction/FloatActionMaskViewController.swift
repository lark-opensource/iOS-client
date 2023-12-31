//
//  FloatActionMaskViewController.swift
//  SKCommon
//
//  Created by zoujie on 2021/1/5.
//  


import Foundation
import SnapKit
import RxSwift
import SKUIKit
import LarkTraitCollection

extension FloatActionMaskViewController {
    enum Layout {
        static let actionTop: CGFloat = 50.0
        static let actionTrailing: CGFloat = 12.0
    }
}

public final class FloatActionMaskViewController: UIViewController {

    public let actionView: FloatActionView

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var actionLeading: Constraint?

    private let bag = DisposeBag()

    public init(actionView: FloatActionView) {
        self.actionView = actionView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0)

        view.addSubview(actionView)
        actionView.onItemClick = { [weak self] completion in
            self?.dismissAction(completion: completion)
        }

        actionView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.actionTop)
            actionLeading = make.leading.equalTo(view.snp.trailing).constraint
            make.trailing.equalToSuperview().offset(-Layout.actionTrailing).priority(.low)
        }

        actionLeading?.activate()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundHandler))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // 监听sizeClass
        guard SKDisplay.pad else { return }
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new {
                    self?.dismiss(animated: false)
                }
            }).disposed(by: bag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAnimation()
    }

    func showAnimation() {
        UIView.animate(withDuration: 0.45, delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1.0,
                       options: .curveEaseInOut,
                       animations: {
            self.actionLeading?.deactivate()
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }, completion: nil)
    }

    func hideAnimation(completion: @escaping () -> Void) {
        view.alpha = 1.0
        UIView.animate(withDuration: 0.45, delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.0,
                       options: .curveEaseInOut,
                       animations: {
            self.actionLeading?.activate()
            self.view.layoutIfNeeded()
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0)
        }, completion: { _ in
            completion()
        })
    }

    public func dismissAction(completion: (() -> Void)?) {
        hideAnimation { [weak self] in
            self?.dismiss(animated: false, completion: completion)
        }
    }

    @objc
    private func tapBackgroundHandler() {
        dismissAction(completion: nil)
    }
}

extension FloatActionMaskViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view?.isDescendant(of: actionView) ?? false)
    }
}
