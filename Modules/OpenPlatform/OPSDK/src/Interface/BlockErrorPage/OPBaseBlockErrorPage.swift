//
//  OPBaseBlockErrorPage.swift
//  OPBlockInterface
//
//  Created by doujian on 2022/8/2.
//

import UIKit
import SwiftUI
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignButton
import LKCommonsLogging

private let logger = Logger.oplog(OPBaseBlockErrorPage.self)

/// 按钮点击事件代理
@objc public protocol OPBlockErrorPageButtonClickDelegate: AnyObject {
    func onBlockErrorPageButtonClicked()
}

/// 错误页 creator
public typealias OPBlockErrorPageCreator = (OPBlockErrorPageButtonClickDelegate) -> OPBaseBlockErrorPage

/// 错误页基类
/// 宿主需要自定义错误页时，继承+重写此类
@objc open class OPBaseBlockErrorPage: UIView {

    // 展示模式
    enum Mode {
        // 有图
        case normal
        // 无图
        case simple
        // 极简
        case light
        // 根据高度判断 mode
        static func mode(height: CGFloat) -> Mode {
            if height < 124 {
                return .light
            } else if height < 220 {
                return .simple
            } else {
                return .normal
            }
        }
    }

    var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    // 内容视图
    var contentView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    // 错误页 icon
    var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDEmptyType.noPreview.defaultImage()
        return imageView
    }()

    // 错误信息展示label
    var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.body2
        label.textColor = .ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.sizeToFit()
        return label
    }()

    // 错误页按钮
    var button: UDButton = UDButton()

    // 业务提示 icon
    var tipIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.memberFilled, iconColor: .ud.iconDisabled)
        return imageView
    }()

    // 事件通知代理
    weak var delegate: OPBlockErrorPageButtonClickDelegate?

    public init(delegate: OPBlockErrorPageButtonClickDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        logger.info("OPBaseBlockErrorPage init")
        addSubview(backgroundView)
        backgroundView.addSubview(contentView)
        backgroundView.addSubview(tipIcon)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func clearContentView() {
        for view in contentView.arrangedSubviews {
            contentView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        logger.info("OPBaseBlockErrorPage clearContentView done")
    }
    private func buttonName(with buttonName: String?) -> String? {
        guard let buttonStr = buttonName, !buttonStr.isEmpty else {
            return nil
        }
        // 16字符截断，无省略号，汉字认定为两个字符
        var length: Int = 0
        var resultStr: String = ""
        for char in buttonStr {
            // 判断是否中文，是中文+2 ，不是+1
            length += "\(char)".lengthOfBytes(using: .utf8) == 3 ? 2 : 1
            if length > 16 {
                return resultStr
            }
            resultStr += String(char)
        }
        return resultStr
    }

    public func refreshViews(contentHight: CGFloat, errorMessage: String, buttonName: String?) {
        logger.info("OPBaseBlockErrorPage refreshViews", additionalData: [
            "contentHight": "\(contentHight)",
            "errorMessage": String(describing: errorMessage),
            "buttonName": String(describing: buttonName)
        ])
        // 清空内容布局
        clearContentView()
        icon.isHidden = true
        // 获取 错误文案
        errorMessageLabel.text = errorMessage
        // refreshViews 时，确定 superview 不为空
        snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
            make.height.lessThanOrEqualTo(188)
            make.width.greaterThanOrEqualTo(120)
            make.width.lessThanOrEqualTo(400)
            make.leading.lessThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
            make.center.equalToSuperview()
        }
        tipIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(16)
            make.trailing.bottom.equalToSuperview().offset(-8)
        }
        var lebalTraillingSpace: CGFloat = 16
        var buttonHeight: CGFloat = 32
        // 按高度适配展示模式
        switch Mode.mode(height: contentHight) {
        case .normal:
            contentView.addArrangedSubview(icon)
            contentView.setCustomSpacing(22, after: icon)
            icon.isHidden = false
            icon.snp.makeConstraints { make in
                make.width.height.equalTo(80)
            }
            fallthrough
        case .simple:
            lebalTraillingSpace = 16
            errorMessageLabel.numberOfLines = 2
            buttonHeight = 32
            button = UDButton(UDButtonUIConifg.primaryBlue)
        case .light:
            // 待确认
            lebalTraillingSpace = 0
            errorMessageLabel.numberOfLines = 1
            buttonHeight = 16
            button = UDButton(UDButtonUIConifg.textBlue)
        }
        contentView.addArrangedSubview(errorMessageLabel)
        errorMessageLabel.snp.remakeConstraints { make in
            make.height.lessThanOrEqualTo(44)
            make.leading.trailing.lessThanOrEqualToSuperview()
        }
        // 获取 按钮文案
        let buttonNameText = self.buttonName(with: buttonName)
        if buttonNameText != nil {
            button.addTarget(
                self,
                action: #selector(onclick),
                for: .touchUpInside
            )
            button.config.type = .small
            button.setTitle(buttonNameText, for: .normal)
            button.titleLabel?.font = .ud.body2
            contentView.addArrangedSubview(button)
            contentView.setCustomSpacing(lebalTraillingSpace, after: errorMessageLabel)
            button.snp.remakeConstraints { make in
                make.height.equalTo(buttonHeight)
                make.width.greaterThanOrEqualTo(80)
                make.width.lessThanOrEqualToSuperview()
            }
        }
    }

    // 按钮点击事件，ovrride 时，需注意向 bridge 发送事件可能会失效
    @objc func onclick() {
        logger.info("OPBaseBlockErrorPage onclick")
        // 点击后Loading，不取消
        button.showLoading()
        delegate?.onBlockErrorPageButtonClicked()
    }
}
