//
//  DriveVideoActionSheet.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/11/22.
//

import UIKit
import SKUIKit
import SKCommon
import SKResource
import UniverseDesignColor
import LarkInteraction

class DriveVideoActionSheet: UIViewController {

    enum Style {
        case landscape
        case protrait
    }

    private let contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()

    private let itemStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.backgroundColor = UDColor.bgFloat
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.layer.cornerRadius = 5
        stackView.layer.masksToBounds = true
        return stackView
    }()

    private var cancelItem: TapView?
    private var style: Style = .landscape
    private let dimmingTransition = DimmingTransition()

    init(style: Style) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = dimmingTransition
        self.style = style
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        switch style {
        case .landscape:
            layoutLandscape()
        case .protrait:
            layoutPortrait()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    @objc
    private func close(_ sender: UITapGestureRecognizer) {
        guard contentView.frame.contains(sender.location(in: view)) == false else { return }
        dismiss(animated: true, completion: nil)
    }

    private func layoutLandscape() {
        if UIApplication.shared.statusBarOrientation.isPortrait && SKDisplay.phone {
            // 非自动横竖屏时，通过旋转展示横屏状态
            view.transform = CGAffineTransform(rotationAngle: .pi / 2)
            let rotatedSize = CGSize(width: view.bounds.height, height: view.bounds.width)
            view.bounds.size = rotatedSize
        }
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.width.equalTo(160)
            make.bottom.equalToSuperview().inset(50)
            make.right.equalToSuperview().inset(16)
        }

        contentView.addSubview(itemStackView)
        itemStackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func layoutPortrait() {
        contentView.addSubview(itemStackView)
        itemStackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        layoutCancelItem()
    }

    private func layoutCancelItem() {
        guard let cancelItem = cancelItem else { return }
        cancelItem.layer.cornerRadius = 5
        cancelItem.clipsToBounds = true
        contentView.addSubview(cancelItem)
        cancelItem.snp.makeConstraints { (make) in
            make.height.equalTo(56)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        itemStackView.snp.remakeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(cancelItem.snp.top).offset(-10)
        }
    }

    func addItemView(_ itemView: UIView, action: @escaping () -> Void) {
        if !itemStackView.arrangedSubviews.isEmpty {
            itemStackView.addArrangedSubview(Line())
        }
        itemStackView.addArrangedSubview(TapView(with: itemView, action: { [weak self] in
            self?.dismiss(animated: true, completion: action)
        }))
    }

    func addCancelItem() {
        cancelItem = TapView(title: BundleI18n.SKResource.Drive_Drive_Cancel) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - DriveVideoActionSheet CustomView
extension DriveVideoActionSheet {
    private class Line: UIView {
        init() {
            super.init(frame: .zero)
            self.backgroundColor = UDColor.lineBorderCard
        }

        override var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.height = 1.0
            return size
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    private class TapView: UIControl {
        private var defaultHeight: CGFloat = 56
        private let bgView = UIView()
        private let titleLabel = UILabel()
        private let action: () -> Void

        init(title: String, action: @escaping () -> Void) {
            self.action = action
            super.init(frame: .zero)
            setupView()
            setupTitle(title)
        }

        init(with view: UIView, action: @escaping () -> Void) {
            self.action = action
            super.init(frame: .zero)
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
            addSubview(view)
            view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            setupView()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public var intrinsicContentSize: CGSize {
            var size = super.intrinsicContentSize
            size.height = defaultHeight
            return size
        }

        @objc
        private func tapped() {
            action()
        }

        private func setupView() {
            addTarget(self, action: #selector(tapped), for: .touchUpInside)
            backgroundColor = UDColor.bgFloat
            if #available(iOS 13.4, *) {
                addLKInteraction(PointerInteraction(style: PointerStyle(effect: .hover())))
            }
            layoutBgView()
        }

        private func setupTitle(_ title: String) {
            titleLabel.numberOfLines = 1
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.textColor = UDColor.textTitle
            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualToSuperview().offset(-20)
            }
        }

        private func layoutBgView() {
            bgView.isUserInteractionEnabled = false
            insertSubview(bgView, at: 0)
            bgView.backgroundColor = UDColor.bgFloat
            bgView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }

        override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            bgView.backgroundColor = UDColor.fillPressed
        }

        override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            bgView.backgroundColor = UDColor.bgFloat
        }

        override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            bgView.backgroundColor = UDColor.bgFloat
        }
    }
}

// MARK: - Dimming Transitoin
private class PresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = UIColor.ud.bgMask
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}

private class DimmingTransition: NSObject, UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            return PresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
