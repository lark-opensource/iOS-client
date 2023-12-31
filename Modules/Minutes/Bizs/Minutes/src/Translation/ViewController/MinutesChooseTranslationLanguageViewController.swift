//
//  MinutesChooseTranslationLanguageViewController.swift
//  Minutes
//
//  Created by yangyao on 2021/2/23.
//

import UIKit
import MinutesFoundation
import UniverseDesignToast
import MinutesNetwork

struct MinutesTranslationLanguageModel {
    var language: String
    var code: String
    var isHighlighted: Bool = false
}

class MinutesChooseTranslationLanguageViewController: UIViewController {
    let dataSource: [MinutesTranslationLanguageModel]
    var selectBlock: ((Language) -> Void)?

    init(items: [MinutesTranslationLanguageModel]) {
        self.dataSource = items
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var commentActionPanel: MinutesChooseTranslationLanguageView = {
        let viewHeight: CGFloat = CGFloat(64 + self.dataSource.count * 52 + (ScreenUtils.hasTopNotch ? 34 : 0))
        // 必须提前设置frame
        let view = MinutesChooseTranslationLanguageView(items: self.dataSource,
                                                        frame: CGRect(x: 0, y: self.view.bounds.height - viewHeight, width: self.view.bounds.width, height: viewHeight))
        view.selectBlock = { [weak self] vm in
            self?.selectBlock?(Language(name: vm.language, code: vm.code))
            self?.dismiss(animated: true, completion: nil)
        }
        return view
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(commentActionPanel)
        view.addGestureRecognizer(tapGestureRecognizer)
        commentActionPanel.cancelBlock = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

extension MinutesChooseTranslationLanguageViewController: UIGestureRecognizerDelegate {
    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if !commentActionPanel.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !self.commentActionPanel.frame.contains(touch.location(in: self.view))
    }
}

extension MinutesChooseTranslationLanguageViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
            return MinutesChooseTranslationLanguagePresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class MinutesChooseTranslationLanguagePresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
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
