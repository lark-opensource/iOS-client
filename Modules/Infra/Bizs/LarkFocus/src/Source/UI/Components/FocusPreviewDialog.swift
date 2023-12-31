//
//  FocusPreviewDialog.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/21.
//

import Foundation
import UIKit
import FigmaKit
import LarkFocusInterface

// MARK: - ViewController

public final class FocusPreviewDialog: UIViewController {

    private lazy var font = UIFont.systemFont(ofSize: 16)

    private lazy var transitionManager = FocusPreviewTransitionManager()

    public func setFocusStatus(_ status: ChatterFocusStatus) {
        // line spacing not work after adding attachment:
        // - https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel
        // - https://github.com/LinkedInAttic/LayoutKit/issues/184
        let lineHeight: CGFloat = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .baselineOffset: baselineOffset,
            .paragraphStyle: mutableParagraphStyle,
            .foregroundColor: UIColor.ud.textTitle
        ]
        let attributedString = NSMutableAttributedString(string: status.title, attributes: attributes)

        let iconSize = font.lineHeight
        if let icon = FocusManager.getFocusIcon(byKey: status.iconKey)?.ud.resized(to: CGSize(width: iconSize, height: iconSize)) {
            let iconAttachment = imageAttachment(image: icon, fontSize: font.pointSize)
            let spacingAttachment = NSTextAttachment()
            spacingAttachment.image = UIImage()
            spacingAttachment.bounds = CGRect(x: 0, y: 0, width: 6, height: 1)
            attributedString.insert(NSAttributedString(attachment: spacingAttachment), at: 0)
            attributedString.insert(NSAttributedString(attachment: iconAttachment), at: 0)
        }

        contentLabel.attributedText = attributedString
    }

    func imageAttachment(image: UIImage, fontSize: CGFloat) -> NSTextAttachment {
        let font = UIFont.systemFont(ofSize: fontSize)
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = image
        let mid = font.descender + font.capHeight
        imageAttachment.bounds = CGRect(x: 0, y: font.descender - image.size.height / 2 + mid + 2, width: image.size.width, height: image.size.height).integral
        return imageAttachment
    }

    lazy var contentView: UIView = {
        let view = SquircleView()
        view.cornerRadius = 10
        view.cornerSmoothness = .natural
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transitionManager
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(contentView)
        contentView.addSubview(contentLabel)
        contentView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(90)
            make.width.lessThanOrEqualTo(300)
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView)))
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
    }

    @objc
    private func didTapBackgroundView() {
        dismiss(animated: true)
    }
}

// MARK: - Transition Manager

public final class FocusPreviewTransitionManager: NSObject, UIViewControllerTransitioningDelegate {

    private let animator = FocusPreviewTransitionAnimator(transitionType: .present)

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .present
        return animator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.type = .dismiss
        return animator
    }

}

// MARK: - Transition Animator

final class FocusPreviewTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType

    init(transitionType: TransitionType) {
        type = transitionType
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        switch type {
        case .present:  return 0.25
        case .dismiss:  return 0.25
        }
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch type {
        case .present:  present(transitionContext)
        case .dismiss:  dismiss(transitionContext)
        }
    }

    private func present(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: .to) as? FocusPreviewDialog,
              let toView = transitionContext.view(forKey: .to) else { return }
        let contentView = toController.contentView
        toView.alpha = 0
        toView.frame = transitionContext.finalFrame(for: toController)
        contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        transitionContext.containerView.addSubview(toView)
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toView.alpha = 1
            contentView.transform = .identity
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }

    private func dismiss(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: .from) as? FocusPreviewDialog,
              let fromView = transitionContext.view(forKey: .from) else { return }
        let duration = transitionDuration(using: transitionContext)
        let contentView = fromController.contentView
        transitionContext.containerView.addSubview(fromView)
        UIView.animate(withDuration: duration, animations: {
            fromView.alpha = 0
            contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
