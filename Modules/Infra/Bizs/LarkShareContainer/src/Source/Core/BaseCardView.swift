//
//  BaseCardView.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2021/1/4.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import ByteWebImage

struct SuccessViewMaterial {
    let link: String
    let expireMsg: String?
    let tipMsg: String?
    init(
        link: String,
        expireMsg: String? = nil,
        tipMsg: String? = nil
    ) {
        self.link = link
        self.expireMsg = expireMsg
        self.tipMsg = tipMsg
    }
}

struct ErrorViewMaterial {
    let errorImage: UIImage
    let errorTipMsg: String
    init(
        errorImage: UIImage?,
        errorTipMsg: String
    ) {
        self.errorImage = errorImage ?? Resources.container_error
        self.errorTipMsg = errorTipMsg
    }
}

struct DisableViewMaterial {
    let disableTipImage: UIImage
    let disableTipMsg: String
    init(
        disableTipImage: UIImage?,
        disableTipMsg: String
    ) {
        self.disableTipImage = disableTipImage ?? Resources.container_disable
        self.disableTipMsg = disableTipMsg
    }
}

enum StatusViewMaterial {
    case success(SuccessViewMaterial)
    case error(ErrorViewMaterial)
    case disable(DisableViewMaterial)
}

private enum Layout {
    // common
    static let headerContainerHeight = 72
    static let avartarTop = 18
    static let avartarLeading = 18
    static let avartarSize = 44
    static let topBottomOffset = 2
    static let nameLeading = 8
    static let nameHeight = 24
    static let nameTrailing = 12
    static let descLeading = 8
    static let descHeight = 24
    static let descTrailing = 12
    static let lineTop = 18
    static let lineHeight = 0.5
    // success
    static let expireTop = 16
    static let expireMargin = 52
    static let tipTop = 18
    static let tipMargin = 42
    static let tipBottom = 18
    // error
    static let errorImageSize = 100
    static let errorMsgTop = 8
    static let errorMsgHeight = 22
    static let errorMsgMargin = 16
    static let retryButtonTop = 4
    static let retryButtonHeight = 22
    static let retryButtonWidth = 120
    // disable
    static let disableImageSize = 100
    static let disableMsgTop = 8
    static let disableMsgMargin = 16
}

class BaseCardView: UIView {
    let retryHandler: () -> Void
    private let circleAvatar: Bool
    private let needBaseSeparateLine: Bool

    init(
        needBaseSeparateLine: Bool,
        circleAvatar: Bool = true,
        retryHandler: @escaping () -> Void
    ) {
        self.needBaseSeparateLine = needBaseSeparateLine
        self.circleAvatar = circleAvatar
        self.retryHandler = retryHandler
        super.init(frame: .zero)
        layer.cornerRadius = 4
        backgroundColor = UIColor.ud.bgBody
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.borderWidth = 0.5
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12.5
        layer.shadowOpacity = 0.05
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideHeaderView() {
        headerContainer.isHidden = true
    }
    
    func centreSuccessContainer() {
        successContainer.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func set(with commonInfo: CommonInfo) {
        nameLabel.text = commonInfo.name
        descLabel.text = commonInfo.description
        switch commonInfo.iconResource {
        case .key(let key):
            avartarView.bt.setLarkImage(with: .avatar(key: key,
                                                      entityID: "",
                                                      params: .init(sizeType: .size(CGFloat(Layout.avartarSize / 2)))),
                                        trackStart: {
                                            return TrackInfo(scene: .Share, fromType: .avatar)
                                        })
        case .url(let url):
            avartarView.bt.setLarkImage(with: .default(key: url.absoluteString))
        }
        updateLayout(with: commonInfo)
    }

    func bind(with statusMaterial: StatusViewMaterial) {
        switch statusMaterial {
        case .success(let m):
            if let expireMsg = m.expireMsg {
                expireLabel.setText(text: expireMsg, lineSpacing: 4)
            }
            if let tipMsg = m.tipMsg {
                tipLabel.setText(text: tipMsg, lineSpacing: 4)
            }
        case .error(let m):
            errorImageView.image = m.errorImage
            errorMsgLabel.text = m.errorTipMsg
        case .disable(let m):
            disableImageView.image = m.disableTipImage
            disableMsgLabel.setText(text: m.disableTipMsg, lineSpacing: 4)
        }
        switchDisplay(with: statusMaterial)
        updateLayout(with: statusMaterial)
    }

    // common
    private lazy var headerContainer: UIView = {
        let view = UIView()
        if needBaseSeparateLine {
            view.lu.addBottomBorder(color: UIColor.ud.lineDividerDefault)
        }
        return view
    }()
    private lazy var avartarView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = circleAvatar ? 22 : 6
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 1
        return label
    }()

    // success
    private var successContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    var contentView: UIView {
        let view = UIView()
        return view
    }
    private lazy var expireLabel: DisplayLabel = {
        let label = DisplayLabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textLinkNormal
        label.numberOfLines = 0
        return label
    }()
    private lazy var tipLabel: DisplayLabel = {
        let label = DisplayLabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        return label
    }()

    // error
    private var errorContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.isHidden = true
        return view
    }()
    private var errorWrapper: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var errorImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    private lazy var errorMsgLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        return label
    }()
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.titleLabel?.textAlignment = .center
        button.setTitle(BundleI18n.LarkShareContainer.Lark_Legacy_QrCodeLoadAgain, for: .normal)
        button.addTarget(self, action: #selector(retryClick), for: .touchUpInside)
        return button
    }()

    // disable
    private var disableContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.isHidden = true
        return view
    }()
    private var disableWrapper: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var disableImageView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    private lazy var disableMsgLabel: DisplayLabel = {
        let label = DisplayLabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.N600
        label.numberOfLines = 0
        return label
    }()

    @objc
    func retryClick() {
        retryHandler()
    }

    func addPageSubviews() {
        addSubview(headerContainer)
        headerContainer.addSubview(avartarView)
        headerContainer.addSubview(nameLabel)
        headerContainer.addSubview(descLabel)
        addSubview(successContainer)
        successContainer.addSubview(contentView)
        successContainer.addSubview(expireLabel)
        successContainer.addSubview(tipLabel)
        addSubview(errorContainer)
        errorContainer.addSubview(errorWrapper)
        errorWrapper.addSubview(errorImageView)
        errorWrapper.addSubview(errorMsgLabel)
        errorWrapper.addSubview(retryButton)
        addSubview(disableContainer)
        disableContainer.addSubview(disableWrapper)
        disableWrapper.addSubview(disableImageView)
        disableWrapper.addSubview(disableMsgLabel)

        // common
        headerContainer.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.headerContainerHeight)
        }
        avartarView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.avartarTop)
            make.leading.equalToSuperview().offset(Layout.avartarLeading)
            make.width.height.equalTo(Layout.avartarSize)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avartarView).offset(-Layout.topBottomOffset)
            make.leading.equalTo(avartarView.snp.trailing).offset(Layout.nameLeading)
            make.trailing.equalToSuperview().inset(Layout.nameTrailing)
            make.height.equalTo(Layout.nameHeight)
        }
        descLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(avartarView.snp.bottom).offset(Layout.topBottomOffset)
            make.leading.equalTo(avartarView.snp.trailing).offset(Layout.descLeading)
            make.trailing.equalToSuperview().inset(Layout.descTrailing)
            make.height.equalTo(Layout.descHeight)
        }
    }
}

private extension BaseCardView {
    func switchDisplay(with statusMaterial: StatusViewMaterial) {
        switch statusMaterial {
        case .success:
            successContainer.isHidden = false
            errorContainer.isHidden = true
            disableContainer.isHidden = true
        case .error:
            successContainer.isHidden = true
            errorContainer.isHidden = false
            disableContainer.isHidden = true
        case .disable:
            successContainer.isHidden = true
            errorContainer.isHidden = true
            disableContainer.isHidden = false
        }
    }

    func updateLayout(with commonInfo: CommonInfo) {
        if commonInfo.description != nil {
            nameLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(avartarView).offset(-Layout.topBottomOffset)
                make.leading.equalTo(avartarView.snp.trailing).offset(Layout.nameLeading)
                make.trailing.equalToSuperview().inset(Layout.nameTrailing)
                make.height.equalTo(Layout.nameHeight)
            }
            descLabel.snp.remakeConstraints { (make) in
                make.bottom.equalTo(avartarView.snp.bottom).offset(Layout.topBottomOffset)
                make.leading.equalTo(avartarView.snp.trailing).offset(Layout.descLeading)
                make.trailing.equalToSuperview().inset(Layout.descTrailing)
                make.height.equalTo(Layout.descHeight)
            }
            descLabel.isHidden = false
        } else {
            nameLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(avartarView).offset(-Layout.topBottomOffset)
                make.leading.equalTo(avartarView.snp.trailing).offset(Layout.nameLeading)
                make.trailing.equalToSuperview().inset(Layout.nameTrailing)
                make.bottom.equalTo(avartarView).offset(Layout.topBottomOffset)
            }
            descLabel.isHidden = true
        }
    }

    func updateLayout(with statusMaterial: StatusViewMaterial) {
        switch statusMaterial {
        case .success(let successMaterial):
            errorContainer.removeAllConstraints()
            disableContainer.removeAllConstraints()
            successContainer.snp.remakeConstraints { (make) in
                make.top.equalTo(headerContainer.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview()
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(0)
            }
            if successMaterial.expireMsg == nil {
                expireLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(contentView.snp.bottom)
                    make.leading.trailing.equalToSuperview().inset(Layout.expireMargin)
                    make.height.equalTo(0)
                }
            } else {
                expireLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(contentView.snp.bottom).offset(Layout.expireTop)
                    make.leading.trailing.equalToSuperview().inset(Layout.expireMargin)
                }
            }
            if successMaterial.tipMsg == nil {
                tipLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(expireLabel.snp.bottom)
                    make.leading.trailing.equalToSuperview().inset(Layout.tipMargin)
                    make.bottom.equalToSuperview().inset(Layout.tipBottom)
                    make.height.equalTo(0)
                }
            } else {
                tipLabel.snp.remakeConstraints { (make) in
                    make.top.equalTo(expireLabel.snp.bottom).offset(Layout.tipTop)
                    make.leading.trailing.equalToSuperview().inset(Layout.tipMargin)
                    make.bottom.equalToSuperview().inset(Layout.tipBottom)
                }
            }
        case .error:
            successContainer.removeAllConstraints()
            disableContainer.removeAllConstraints()
            errorContainer.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            errorWrapper.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            errorImageView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview()
                make.width.height.equalTo(Layout.errorImageSize)
                make.centerX.equalToSuperview()
            }
            errorMsgLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(errorImageView.snp.bottom).offset(Layout.errorMsgTop)
                make.leading.trailing.equalToSuperview().inset(Layout.errorMsgMargin)
                make.height.equalTo(Layout.errorMsgHeight)
            }
            retryButton.snp.remakeConstraints { (make) in
                make.top.equalTo(errorMsgLabel.snp.bottom).offset(Layout.retryButtonTop)
                make.width.equalTo(Layout.retryButtonWidth)
                make.height.equalTo(Layout.retryButtonHeight)
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        case .disable:
            successContainer.removeAllConstraints()
            errorContainer.removeAllConstraints()
            disableContainer.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            disableWrapper.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview()
            }
            disableImageView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview()
                make.width.height.equalTo(Layout.errorImageSize)
                make.centerX.equalToSuperview()
            }
            disableMsgLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(disableImageView.snp.bottom).offset(Layout.disableMsgTop)
                make.leading.trailing.equalToSuperview().inset(Layout.disableMsgMargin)
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        }
    }
}

extension UIView {
    func removeAllConstraints() {
        var _superview = superview
        while let superview = _superview {
            for constraint in superview.constraints {
                if let first = constraint.firstItem as? UIView, first == self {
                    superview.removeConstraint(constraint)
                }
                if let second = constraint.secondItem as? UIView, second == self {
                    superview.removeConstraint(constraint)
                }
            }
            _superview = superview.superview
        }
        removeConstraints(constraints)
        translatesAutoresizingMaskIntoConstraints = true
    }
}
