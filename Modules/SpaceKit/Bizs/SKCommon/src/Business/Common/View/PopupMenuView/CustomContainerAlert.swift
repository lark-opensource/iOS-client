//
//  AtUserInviteAlert.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/26.
//

import SKFoundation
import SKUIKit
import SKResource

public final class CustomContainerAlert: UIViewController {

    private var showView: UIView?
    private var arrowUp: Bool = false
    private var constraitHeight: CGFloat?

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func setupUI() {
        view.backgroundColor = UIColor.ud.bgFloat
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        view.addGestureRecognizer(singleTap)
    }

    public func setTipsView(_ tipsView: UIView, arrowUp: Bool, constraitHeight: CGFloat? = nil) {
        self.showView = tipsView
        self.arrowUp = arrowUp
        self.constraitHeight = constraitHeight

        guard let tipsView = showView else {
            skAssertionFailure()
            return
        }
        view.addSubview(tipsView)
        if arrowUp {
            tipsView.snp.makeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
                if let constraitHeight = constraitHeight {
                    make.height.equalTo(constraitHeight)
                }
            })
        } else {
            tipsView.snp.makeConstraints({ (make) in
                make.left.right.top.equalToSuperview()
                if let constraitHeight = constraitHeight {
                    make.height.equalTo(constraitHeight)
                }
            })
        }
    }


    @objc
    private func bgTap() {
//        self.dismiss(animated: self.isPopover ? true : false, completion: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}
