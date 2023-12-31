//
//  ImagePickerBottomView.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/31.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import UniverseDesignColor
import UniverseDesignButton

protocol ImagePickerBottomViewDelegate: AnyObject {
    func bottomViewOriginButtonDidClick(_ bottomView: ImagePickerBottomView)
    func bottomViewCenterButtonDidClick(_ bottomView: ImagePickerBottomView)
    func bottomViewSendButtonDidClick(_ bottomView: ImagePickerBottomView)
}

struct ImagePickerBottomViewConfig {
    enum Style {
        case light, dark
    }

    var style: Style

    var originButtonHidden: Bool
    var originButtonTitle: String
    var originButtonEnable: Bool
    var originButtonSelected: Bool

    var centerButtonTitle: String
    var centerButtonHidden: Bool

    var sendButtonTitle: String
    var sendButtonEnable: Bool

    var selectCount: Int

    var sendButtonFullTitle: String {
        if selectCount > 0 {
            return sendButtonTitle + "(\(selectCount))"
        } else {
            return sendButtonTitle
        }
    }

    init(style: Style,
         originButtonHidden: Bool,
         originButtonTitle: String,
         originButtonEnable: Bool,
         originButtonSelected: Bool,
         centerButtonTitle: String,
         centerButtonHidden: Bool,
         sendButtonTitle: String,
         sendButtonEnable: Bool,
         selectCount: Int) {
        self.style = style

        self.originButtonHidden = originButtonHidden
        self.originButtonTitle = originButtonTitle
        self.originButtonEnable = originButtonEnable
        self.originButtonSelected = originButtonSelected

        self.centerButtonTitle = centerButtonTitle
        self.centerButtonHidden = centerButtonHidden

        self.sendButtonTitle = sendButtonTitle
        self.sendButtonEnable = sendButtonEnable

        self.selectCount = selectCount
    }

    static var lightDefault: ImagePickerBottomViewConfig {
        return ImagePickerBottomViewConfig(style: .light,
                                           originButtonHidden: false,
                                           originButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_OriginPic,
                                           originButtonEnable: true,
                                           originButtonSelected: false,
                                           centerButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_ImagePreview,
                                           centerButtonHidden: true,
                                           sendButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Send,
                                           sendButtonEnable: false,
                                           selectCount: 0)
    }

    static var darkDefault: ImagePickerBottomViewConfig {
        return ImagePickerBottomViewConfig(style: .dark,
                                           originButtonHidden: false,
                                           originButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_OriginPic,
                                           originButtonEnable: true,
                                           originButtonSelected: false,
                                           centerButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Edit,
                                           centerButtonHidden: false,
                                           sendButtonTitle: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Send,
                                           sendButtonEnable: true,
                                           selectCount: 0)
    }
}

final class ImagePickerBottomView: UIView {
    weak var delegate: ImagePickerBottomViewDelegate?
    weak var toolBarDelegate: PhotoPickerBottomToolBarDelegate?
    var toolBar: PhotoPickerBottomToolBar?

    var config: ImagePickerBottomViewConfig {
        didSet {
            setupUIWithConfig(config)
        }
    }

    private let contentView = UIView()
    private let topSeperator = UIView()

    private let originalButton = OriginalButton()

    private lazy var centerButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.ud.body0(.fixed)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        if #available(iOS 15.0, *) {
            button.titleLabel?.showsExpansionTextWhenTruncated = true
        }
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_Legacy_ImagePreview, for: .normal)
        return button
    }()

    private lazy var sendButton: UDButton = {
        let button = UDButton(.primaryBlue.type(.small))
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.font = UIFont.ud.body0(.fixed)
        button.setTitle(config.sendButtonTitle, for: .normal)
        return button
    }()

    private let disposeBag = DisposeBag()

    init(config: ImagePickerBottomViewConfig) {
        self.config = config
        super.init(frame: .zero)

        setupSubviews()
        setupUIWithConfig(config)

        originalButton.lu.addTapGestureRecognizer(action: #selector(originButtonDidClick), target: self)

        centerButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.bottomViewCenterButtonDidClick(self)
        }).disposed(by: disposeBag)

        sendButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.bottomViewSendButtonDidClick(self)
        }).disposed(by: disposeBag)
    }

    private func setupSubviews() {
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.height.equalTo(44)
        }

        contentView.addSubview(originalButton)
        contentView.addSubview(centerButton)
        contentView.addSubview(sendButton)

        originalButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(32)
        }
        centerButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().priority(.low)
            make.left.greaterThanOrEqualTo(originalButton.snp.right).offset(8)
            make.right.lessThanOrEqualTo(sendButton.snp.left).offset(-8)
            // 设计不让留最小宽度，那就不留吧
            // make.width.greaterThanOrEqualToSuperview().multipliedBy(0.2)
        }
        sendButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        originalButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(topSeperator)
        topSeperator.backgroundColor = UIColor.ud.lineDividerDefault
        topSeperator.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    private func setupUIWithConfig(_ config: ImagePickerBottomViewConfig) {
        backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.9)

        originalButton.isHidden = config.originButtonHidden
        originalButton.set(isOrigin: config.originButtonSelected)
        originalButton.set(isOriginEnable: config.originButtonEnable)
        originalButton.textLabel.text = config.originButtonTitle

        centerButton.isHidden = config.centerButtonHidden
        centerButton.setTitle(config.centerButtonTitle, for: .normal)

        sendButton.setTitle(config.sendButtonFullTitle, for: .normal)
        sendButton.isEnabled = config.sendButtonEnable
        sendButton.accessibilityIdentifier = "lark.uikit.assetpicker.sendButton"

        if config.style == .dark {
            if #available(iOS 13.0, *) {
                overrideUserInterfaceStyle = .dark
            } else {
                backgroundColor = UIColor.ud.bgBody.alwaysDark.withAlphaComponent(0.9)
                topSeperator.backgroundColor = UIColor.ud.lineDividerDefault.alwaysDark
                originalButton.textLabel.textColor = UIColor.ud.textTitle.alwaysDark
                centerButton.setTitleColor(UIColor.ud.textTitle.alwaysDark, for: .normal)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func originButtonDidClick() {
        guard config.originButtonEnable else { return }
        self.delegate?.bottomViewOriginButtonDidClick(self)
        // 透传给上一层的 PickerView
        guard let toolBar = toolBar else { return }
        self.toolBarDelegate?.bottomToolBarDidClickOriginButton(toolBar)
    }
}
