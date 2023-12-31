// longweiwei

import Foundation
import UIKit
import EENavigator
import RxSwift

class WidgetViewController: UIViewController {

    var isPopover: Bool {
        return modalPresentationStyle == .popover
    }

    var contentHeight: CGFloat
    var contentViewAppear: Bool = false
    var needAnimated = true
    let notiDisposeBag = DisposeBag()
    var maskResponse: Bool = true

    lazy var contentView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.mail.rgb("fff0f0f0")
        return view
    }()

    lazy var backgroundMaskView: UIControl = {
        let mask = UIControl()
        mask.addTarget(self, action: #selector(onMaskClick), for: .touchUpInside)
        mask.backgroundColor = UIColor.ud.bgMask
        mask.alpha = 0.0
        return mask
    }()

    init(contentHeight: CGFloat) {
        self.contentHeight = contentHeight
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
    }

    func resetHeight(_ height: CGFloat) {
        self.contentHeight = height
        var bottomOffset: CGFloat = 0
        if !contentViewAppear && needAnimated && !isPopover {
            bottomOffset = contentHeight + Display.bottomSafeAreaHeight
        }
        if navigationController != nil {
            contentView.snp.remakeConstraints { (make) in
                make.left.right.top.bottom.equalToSuperview()
            }
        } else {
            if isPopover {
                contentView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(contentHeight)
                }
            } else {
                contentView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(contentHeight + Display.bottomSafeAreaHeight)
                    make.bottom.equalTo(view.snp.bottom).offset(bottomOffset)
                }
            }
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        if modalPresentationStyle != .popover {
            setupMaskView()
        }
        setupContentView()

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .shareAccountChange(let change) = push {
                    if change.isCurrent && !change.isBind {
                        self?.mailCurrentAccountUnbind()
                    }
                }
            }).disposed(by: notiDisposeBag)
    }

    @objc
    func mailCurrentAccountUnbind() {
        self.animatedView(isShow: false) {}
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatedView(isShow: true) { [weak self] in
            self?.firstShowAnimationComplete()
        }
    }

    func firstShowAnimationComplete() {

    }

    func setupMaskView() {
        view.addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func setupContentView() {
        view.addSubview(contentView)
        if navigationController != nil {
            contentView.snp.makeConstraints { (make) in
                make.left.right.top.bottom.equalToSuperview()
            }
        } else {
            contentView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(contentHeight + Display.bottomSafeAreaHeight)
                make.bottom.equalTo(view.snp.bottom).offset(contentHeight + Display.bottomSafeAreaHeight)
            }
        }
    }

    @objc
    func onMaskClick() {
        guard maskResponse else { return }
        animatedView(isShow: false) {}
    }

    func animatedView(isShow: Bool, completion: (() -> Void)? = nil) {
        if isShow {
            contentViewWillAppear()
            contentViewAppear = true
        } else {
            contentViewWillDisappear()
            contentViewAppear = false
        }

        let alpha: CGFloat = isPopover ? 0 : (isShow ? 1.0 : 0)
        let bottomOffset = isShow ? 0 : contentHeight + Display.bottomSafeAreaHeight
        let maskAnimationDelay = isShow ? 0 : 0.12
        let contentAnimationDelay = isShow ? 0.12: 0
        let animationDuration = needAnimated ? 0.25 : 0

        let dismissCallback: () -> Void = {
            if isShow == false {
                if self.isPopover {
                    completion?()
                    self.dismiss(animated: false)
                } else {
                    let animated = Display.pad
                    self.dismiss(animated: animated) {
                        completion?()
                    }
                }
            } else {
                completion?()
            }
        }

        /// show or dismiss contentView animation
        if needAnimated {
            contentView.snp.updateConstraints { (make) in
                make.bottom.equalTo(view.snp.bottom).offset(bottomOffset)
            }
        }
        /// show or dismiss backgroud mask view animation
        UIView.animate(withDuration: animationDuration,
                       delay: maskAnimationDelay,
                       animations: {
                        self.backgroundMaskView.alpha = alpha
        }, completion: { [weak self](_) in
            guard let `self` = self else { return }
            if !isShow {
                self.contentViewDidDisappear()
                self.dismiss(animated: false, completion: nil)
            }
        })
        UIView.animate(withDuration: animationDuration,
                       delay: contentAnimationDelay,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 10.0,
                       options: [],
                       animations: {
                        self.view.layoutIfNeeded()
        }, completion: { [weak self] (_) in
            guard let `self` = self else { return }
            if isShow {
                self.contentViewDidAppear()
            }
            dismissCallback()
        })
    }

    /// life cycle of content view
    func contentViewWillAppear() { }
    func contentViewDidAppear() { }
    func contentViewWillDisappear() { }
    func contentViewDidDisappear() { }
}
