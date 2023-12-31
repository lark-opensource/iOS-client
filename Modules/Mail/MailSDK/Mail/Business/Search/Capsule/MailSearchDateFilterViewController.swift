//
//  MailSearchDateFilterViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/30.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignDatePicker
import LarkDatePickerView

final class MailSearchDateFilterViewController: BaseUIViewController, UIGestureRecognizerDelegate,
                                            UIPopoverPresentationControllerDelegate,
                                            UIViewControllerTransitioningDelegate, PresentWithFadeAnimatorVC {

    /// 回调参数: vc本身，开始时间，结束时间
    var finishChooseBlock: ((MailSearchDateFilterViewController, Date?, Date) -> Void)?

    private let startDate: Date?
    private let endDate: Date

    lazy var colorBgView = UIView()
    let contentView = UIView()
    private let naviBar = DateFilterNaviBar(style: .left)
    private let leftItemView = DateFilerItemView(style: .left)
    private let rightItemView = DateFilerItemView(style: .right)
    private let datePickerView: DatePickerView

    init(startDate: Date?, endDate: Date, fromView: UIView?) {
        self.startDate = startDate
        self.endDate = endDate
        datePickerView = DatePickerView(startDate: startDate, endDate: endDate, style: .left)
        super.init(nibName: nil, bundle: nil)

        if Display.pad {
            if let fromView = fromView {
                modalPresentationStyle = .popover
                self.popoverPresentationController?.sourceView = fromView
                self.popoverPresentationController?.sourceRect = fromView.bounds // 如果不设置，ios11会指向左上角
                self.popoverPresentationController?.delegate = self
            } else {
                modalPresentationStyle = .formSheet
            }
        } else {
            modalPresentationStyle = .overCurrentContext
            transitioningDelegate = self
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if Display.pad {
            modeledDisplay()
        } else {
            unModeledDisplay()
        }
    }
    func modeledDisplay() {
        view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        self.view.backgroundColor = naviBar.backgroundColor
        configureContentView()
    }
    func unModeledDisplay() {
        view.backgroundColor = nil
        colorBgView.backgroundColor = UIColor.ud.bgMask

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapDidInvoke))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        view.addSubview(colorBgView)
        view.addSubview(contentView)

        colorBgView.frame = view.bounds
        colorBgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }
        configureContentView()
    }

    func configureContentView() {
        naviBar.delegate = self
        contentView.addSubview(naviBar)
        naviBar.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        naviBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(64)
        }

        if let startDate = startDate {
            leftItemView.set(title: "\(startDate.year)-\(startDate.month)-\(startDate.day)")
        } else {
            leftItemView.set(title: BundleI18n.MailSDK.Mail_shared_FilterSearch_AnyTime_Mobile_Text)
        }
        leftItemView.set(selected: true)
        leftItemView.delegate = self
        contentView.addSubview(leftItemView)
        leftItemView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(68)
            make.top.equalTo(naviBar.snp.bottom)
            make.width.equalToSuperview().multipliedBy(0.5).offset(20)
        }

        rightItemView.set(title: "\(endDate.year)-\(endDate.month)-\(endDate.day)")
        rightItemView.set(selected: false)
        rightItemView.delegate = self
        contentView.addSubview(rightItemView)
        rightItemView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.height.equalTo(68)
            make.top.equalTo(naviBar.snp.bottom)
            make.width.equalToSuperview().multipliedBy(0.5).offset(20)
        }

        datePickerView.delegate = self
        contentView.addSubview(datePickerView)
        datePickerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(leftItemView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }

    @objc
    private func backgroundTapDidInvoke() {
        dismiss(animated: true, completion: nil)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        if contentView.frame.contains(location) {
            return false
        } else {
            return true
        }
    }
    // MARK: popover delegate
    func presentationController(
        _ presentationController: UIPresentationController,
        willPresentWithAdaptiveStyle style: UIModalPresentationStyle,
        transitionCoordinator: UIViewControllerTransitionCoordinator?
    ) {
        // style == none是不变，即用的popover, 否则是实际展示类型
        naviBar.closeButton.isHidden = style == .none // hidden when popup style. else show
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentWithFadeAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissWithFadeAnimator()
    }
}

extension MailSearchDateFilterViewController: DateFilterNaviBarDelegate {
    func naviBarDidClickCloseButton(_ naviBar: DateFilterNaviBar) {
        dismiss(animated: true, completion: nil)
    }

    func naviBarDidClickFinishButton(_ naviBar: DateFilterNaviBar) {
        let startDate = datePickerView.startDate.flatMap { $0.mail.beginDate }
        let endDate = datePickerView.endDate.mail.endDate
        finishChooseBlock?(self, startDate, endDate)
    }
}

extension MailSearchDateFilterViewController: DateFilerItemViewDelegate {
    func itemViewDidClick(_ itemView: DateFilerItemView) {
        if !itemView.selected {
            if itemView === leftItemView {
                naviBar.set(style: .left)
                leftItemView.set(selected: true)
                rightItemView.set(selected: false)
                datePickerView.set(style: .left)
            } else if itemView === rightItemView {
                naviBar.set(style: .right)
                leftItemView.set(selected: false)
                rightItemView.set(selected: true)
                datePickerView.set(style: .right)
            }
        }
    }
}

extension MailSearchDateFilterViewController: DatePickerViewDelegate {
    func pickerView(_ pickerView: DatePickerView, didSelectStart date: Date?) {
        if let date = date {
            leftItemView.set(title: "\(date.year)-\(date.month)-\(date.day)")
        } else {
            leftItemView.set(title: BundleI18n.MailSDK.Mail_shared_FilterSearch_AnyTime_Mobile_Text)
        }
    }

    func pickerView(_ pickerView: DatePickerView, didSelectEnd date: Date) {
        rightItemView.set(title: "\(date.year)-\(date.month)-\(date.day)")
    }
}
