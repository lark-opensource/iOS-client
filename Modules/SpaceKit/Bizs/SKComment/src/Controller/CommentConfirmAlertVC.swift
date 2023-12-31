//
//  CommentConfirmAlertVC.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/3/13.
//

import Foundation
import SKUIKit
import SKResource
import SpaceInterface

class CommentConfirmAlertVC: UIViewController, CommentConfirmAlertVCType {
    private var container: UIView?
    private var confirmTitle: String?
    private var confirmBtn: UIButton?
    private var cancelBtn: UIButton?
    private var confirmCallBack: (() -> Void)?
    private var lastHeight: CGFloat = 0
    private var isPopover: Bool = true
    private var fistTimeTrans: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = UIColor.clear
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(bgTap))
        view.addGestureRecognizer(singleTap)

        let containerTemp = UIView()
        view.addSubview(containerTemp)
        container = containerTemp
        containerTemp.layer.cornerRadius = 12
        containerTemp.layer.masksToBounds = true
        containerTemp.backgroundColor = UIColor.ud.N00
        containerTemp.snp.makeConstraints({ (make) in
            make.height.equalTo(112)
            make.left.right.bottom.equalToSuperview()
        })

        let cancel = UIButton()
        cancel.docs.addStandardHover()
        cancelBtn = cancel
        containerTemp.addSubview(cancel)

        cancel.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        cancel.setTitleColor(UIColor.ud.N900, for: .normal)
        cancel.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancel.addTarget(self, action: #selector(cancelHandler), for: .touchUpInside)
        cancelBtn?.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(56)
        }

        let confirm = UIButton()
        confirm.docs.addStandardHover()
        confirmBtn = confirm
        containerTemp.addSubview(confirm)
        confirm.setTitle(confirmTitle, for: .normal)
        confirm.setTitleColor(UIColor.ud.N900, for: .normal)
        confirm.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        confirm.addTarget(self, action: #selector(conformHandler), for: .touchUpInside)
        confirmBtn?.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
            make.bottom.equalTo(cancelBtn!.snp.top)
        }

        let line = UIView()
        self.view.addSubview(line)
        line.backgroundColor = UIColor.ud.N300
        line.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.top.left.right.equalTo(cancel)
        }
        updateLayout(isPopover: self.isPopover)
    }

    func setConfirmTitle(_ titile: String, confirmBlock: (() -> Void)?) {
        confirmTitle = titile
        confirmBtn?.setTitle(titile, for: .normal)
        confirmCallBack = confirmBlock
    }

    func updateLayout(isPopover: Bool) {
        guard confirmBtn?.superview != nil else {
            return
        }
        let arrowDirection = self.popoverPresentationController?.arrowDirection
        var arrowInBottomHeight: CGFloat = 0
        if arrowDirection == .up {
            arrowInBottomHeight = 13.0
        } else if arrowDirection == .down {
            arrowInBottomHeight = -13.0
        }
        container?.snp.remakeConstraints({ (make) in
            make.height.equalTo(112)
            make.bottom.equalToSuperview().offset(arrowInBottomHeight)
            make.left.right.bottom.equalToSuperview()

        })
    }

    @objc
    private func bgTap() {
        self.dismiss(animated: self.isPopover ? true : false, completion: nil)
    }

    @objc
    private func conformHandler() {
        confirmCallBack?()
        self.dismiss(animated: self.isPopover ? true : false, completion: nil)
    }

    @objc
    private func cancelHandler() {
        self.dismiss(animated: self.isPopover ? true : false, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let curHeight = self.view.frame.size.height
        if curHeight != lastHeight {
            let isFull = curHeight > (self.preferredContentSize.height + 20)
            self.isPopover = !isFull
            updateLayout(isPopover: self.isPopover)
            self.view.backgroundColor = isFull ? UIColor.ud.N900.withAlphaComponent(0.3) : UIColor.ud.N00
            lastHeight = curHeight
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}
