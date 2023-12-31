//
//  DocFilterViewController.swift
//  LarkSearch
//
//  Created by SuPeng on 5/5/19.
//

import Foundation
import UIKit
import LarkUIKit
import LarkSearchFilter
import LarkModel
import LarkSDKInterface
import LarkSearchCore

final class DocFilterViewController: BaseUIViewController, UIGestureRecognizerDelegate {

    var didFinishChoosingFilter: ((UIViewController, DocFormatType) -> Void)?

    private let containerView = UIView()
    private let naviBar = DocFilterNaviBar()
    private let contentView: DocFilterContentView
    let isModeled: Bool

    init(enableMindnote: Bool, enableBitable: Bool, isModeled: Bool = false, enableNewSlides: Bool) {
        self.contentView = DocFilterContentView(enableMindnote: enableMindnote,
                                                enableBitable: enableBitable,
                                                enableNewSlides: enableNewSlides)
        self.isModeled = isModeled
        super.init(nibName: nil, bundle: nil)
        if !isModeled {
            modalPresentationStyle = .overCurrentContext
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = naviBar.titleLabel.text
        if isModeled {
            modeledDisplay()
        } else {
            unModeledDisplay()
        }
    }
    func modeledDisplay() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: naviBar.closeButton.image(for: .normal), style: UIBarButtonItem.Style.plain,
            target: self, action: #selector(cancelButtonDidClick))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.ud.iconN1
        self.view.addSubview(contentView)
        contentView.delegate = self
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(6).priority(900)
            $0.center.equalToSuperview()
        }
    }

    func unModeledDisplay() {
        view.backgroundColor = UIColor.ud.bgMask

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapDidInvoke))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        containerView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }

        naviBar.delegate = self
        containerView.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(64)
        }

        containerView.addSubview(contentView)
        contentView.delegate = self
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(naviBar.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(viewBottomConstraint).offset(-6)
        }
    }

    @objc
    private func backgroundTapDidInvoke() {
        dismiss(animated: isModeled, completion: nil)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        if containerView.frame.contains(location) {
            return false
        } else {
            return true
        }
    }

    @objc
    func cancelButtonDidClick() {
        dismiss(animated: isModeled, completion: nil)
    }
}

extension DocFilterViewController: DocFilterNaviBarDelegate {
    func naviBarDidClickCloseButton(_ naviBar: DocFilterNaviBar) {
        dismiss(animated: isModeled, completion: nil)
    }
}

extension DocFilterViewController: DocFilterContentViewDelegate {
    func contentView(_ contentView: DocFilterContentView, didClickFilter: DocFormatType) {
        didFinishChoosingFilter?(self, didClickFilter)
    }
}
