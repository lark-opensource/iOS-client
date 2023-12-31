//
//  TopicView.swift
//  LarkThread
//
//  Created by zoujiayi on 2019/9/27.
//

import Foundation
import LarkUIKit
import UIKit

protocol TopicViewDelegate: AnyObject {
    /// 点击左边x按钮
    func TopicViewOnClose(_ view: TopicView)
    /// 点击话题行，重新选择一个话题
    func TopicViewOnChangeTopic(_ view: TopicView)
    /// 点击左边取消按钮
    func TopicViewOnCancel(_ view: TopicView)
    /// 点击右边保存按钮
    func TopicViewOnSave(_ view: TopicView)
}

final class TopicView: UIView {
    // MARK: private
    private let heightOfNavigationBar = UIApplication.shared.statusBarFrame.height + 44
    private let isPadPageStyle: Bool
    weak var delegate: TopicViewDelegate?

    private lazy var normalNavigationBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.text = BundleI18n.LarkThread.Lark_Groups_NewPostTitle
        view.addSubview(titleLabel)
        let isPadPageStyle = self.isPadPageStyle
        titleLabel.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            if !isPadPageStyle {
                make.bottom.equalToSuperview().offset(-10)
            } else {
                make.centerY.equalToSuperview()
            }
        })

        let leftButton = LKBarButtonItem(image: Resources.new_topic_close).button
        leftButton.tintColor = UIColor.ud.iconN1
        leftButton.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
        view.addSubview(leftButton)
        leftButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
        }
        return view
    }()

    private var rightButton: UIButton?

    private lazy var saveButtonNavigationBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.text = BundleI18n.LarkThread.Lark_IM_EditTopic_Button
        view.addSubview(titleLabel)
        let isPadPageStyle = self.isPadPageStyle
        titleLabel.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            if !isPadPageStyle {
                make.bottom.equalToSuperview().offset(-10)
            } else {
                make.centerY.equalToSuperview()
            }
        })

        let rightButton = LKBarButtonItem(title: BundleI18n.LarkThread.Lark_IM_EditMessage_Save_Button).button
        rightButton.tintColor = UIColor.ud.textTitle
        rightButton.addTarget(self, action: #selector(saveBtnTapped), for: .touchUpInside)
        view.addSubview(rightButton)
        rightButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-16)
        }
        self.rightButton = rightButton

        let leftButton = LKBarButtonItem(title: BundleI18n.LarkThread.Lark_IM_EditMessage_Cancel_Button).button
        leftButton.tintColor = UIColor.ud.textTitle
        leftButton.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        view.addSubview(leftButton)
        leftButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.left.equalToSuperview().offset(16)
        }
        return view
    }()

    private var navigationBar: UIView {
        if showSaveAndCancelButton {
            return saveButtonNavigationBar
        } else {
            return normalNavigationBar
        }
    }

    let showSaveAndCancelButton: Bool

    init(showSaveAndCancelButton: Bool,
         isPadPageStyle: Bool) {
        self.isPadPageStyle = isPadPageStyle
        self.showSaveAndCancelButton = showSaveAndCancelButton
        super.init(frame: .zero)
        setupNavigationBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupNavigationBar() {
        self.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(heightOfNavigationBar)
            make.top.equalToSuperview()
        }
    }

    func addEditer(_ view: UIView) {
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    func setRightButtonEnable(_ enable: Bool) {
        rightButton?.isEnabled = enable
    }

    @objc
    func closeBtnTapped() {
        delegate?.TopicViewOnClose(self)
    }

    @objc
    func selectBtnTapped() {
        delegate?.TopicViewOnChangeTopic(self)
    }

    @objc
    func saveBtnTapped() {
        delegate?.TopicViewOnSave(self)
    }

    @objc
    func cancelBtnTapped() {
        delegate?.TopicViewOnCancel(self)
    }
}
