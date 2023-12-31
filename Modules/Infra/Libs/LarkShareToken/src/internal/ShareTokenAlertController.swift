//
//  ShareTokenAlertController.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/26.
//

import UIKit
import Foundation
import LarkAlertController

class ShareTokenAlertVC: UIViewController {

    var shareTokenAlertViewModel: ShareTokenAlertViewModel?

    init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let vm = shareTokenAlertViewModel {
            let view = ShareTokenAlertView(viewModel: vm)
            view.backgroundColor = .white
            self.view.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.width.equalTo(300)
                make.centerX.centerY.equalToSuperview()
            }
        }
    }
}

extension ShareTokenAlertVC: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController)
        -> UIPresentationController? {
            return LarkAlertPresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return LarkAlertAnimator(isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
        return LarkAlertAnimator(isPresenting: false)
    }
}
