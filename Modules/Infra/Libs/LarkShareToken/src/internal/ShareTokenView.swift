//
//  ShareTokenView.swift
//  LarkShareToken
//
//  Created by 赵冬 on 2020/4/14.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RichLabel
import LarkModel
import EEImageService

public class ShareTokenAlertViewModel {
    public var descImageSet: ImageItemSet?
    public var mainTitle: String?
    public var atUserIdRangeMap: [String: [NSRange]] = [:]
    public var userClickEnableMap: [String: Bool] = [:]
    public var tapableRangeList: [NSRange] = []
    public var subtitle: String?
    public var openButtonTitle: String?

    public var clickShutButtonHandler: ((UIButton) -> Void)?
    public var clickOpenButtonHandler: ((UIButton) -> Void)?
    public var openAtHandler: ((_ chatterId: String) -> Void)?

    public var template: Template

    public init(template: Template) {
        self.template = template
    }
}

/// doc: https://app.zeplin.io/project/5a9cb14722b49c7617030c40/screen/5e96d750d398507b5c000b3b
public enum Template {
    // 通用
    case normal
    // 无顶部图片
    case noTopImage
}

public class ShareTokenAlertView: UIView {
    // 顶部的image
    var topImageView: UIImageView = UIImageView()
    // 中间的容器
    var centerContainer: UIView = UIView()
    // 主标题
    var mainTitleLabel: UILabel = UILabel()
    // 副标题
    var subtitleTitleLabel: LKLabel = LKLabel()
    // 跳转的按钮
    var openButton: UIButton = UIButton()
    // 分享来源, 按钮
    var shareSourceButton: UIButton = UIButton()
    // 关闭按钮
    var shutButton: UIButton = UIButton()

    var vm: ShareTokenAlertViewModel

    private var atUserIdRangeMap: [String: [NSRange]] = [:]
    public var openAtHandler: ((_ chatterId: String) -> Void)?
    private var userClickEnableMap: [String: Bool] = [:]


    public init(viewModel: ShareTokenAlertViewModel) {
        vm = viewModel
        super.init(frame: .zero)
        switch viewModel.template {
        case .normal:
            self.configNormalTemplate(viewModel: viewModel)
        case .noTopImage:
            self.configNoImageTemplate(viewModel: viewModel)
        }
    }

    private func configNormalTemplate(viewModel: ShareTokenAlertViewModel) {
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.addSubview(topImageView)
        if let handler = viewModel.openAtHandler {
            self.openAtHandler = handler
        }
        topImageView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(270)
        }
        if let descImageSet = viewModel.descImageSet {
            topImageView.lk.setPostMessage(imageSet: descImageSet, placeholder: nil, completion: nil)
        }

        self.addSubview(centerContainer)
        centerContainer.snp.makeConstraints { (make) in
            make.top.equalTo(topImageView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
        }

        centerContainer.addSubview(subtitleTitleLabel)
        subtitleTitleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(270)
            make.height.equalTo(22)
        }
        if let text = viewModel.subtitle {
            let attributedString = NSMutableAttributedString(string: text,
                                                             attributes: [
                                                                 .font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.N600,
                                                                 .kern: 0.0])
            viewModel.atUserIdRangeMap.forEach { (arg0) -> Void in
                let (userId, ranges) = arg0
                ranges.forEach { (range) in
                    let color = (vm.userClickEnableMap[userId] ?? false) ? UIColor.ud.colorfulBlue : UIColor.ud.N900
                    attributedString.addAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
                }
            }
            subtitleTitleLabel.attributedText = attributedString
            subtitleTitleLabel.delegate = self
            self.atUserIdRangeMap = viewModel.atUserIdRangeMap
            self.userClickEnableMap = viewModel.userClickEnableMap
            subtitleTitleLabel.tapableRangeList = viewModel.tapableRangeList
            subtitleTitleLabel.backgroundColor = .clear
            subtitleTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            subtitleTitleLabel.textColor = UIColor.ud.N900
            subtitleTitleLabel.numberOfLines = 1
            subtitleTitleLabel.textAlignment = .center
            subtitleTitleLabel.lineBreakMode = .byTruncatingTail
            subtitleTitleLabel.preferredMaxLayoutWidth = 240
        }

        centerContainer.addSubview(mainTitleLabel)
        mainTitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleTitleLabel.snp.bottom).offset(10)
            make.width.lessThanOrEqualTo(270)
            make.height.greaterThanOrEqualTo(22)
            make.height.lessThanOrEqualTo(80)
            make.bottom.equalToSuperview()
        }
        if let text = viewModel.mainTitle {
            mainTitleLabel.text = text
            mainTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            mainTitleLabel.textColor = UIColor.ud.N900
            mainTitleLabel.numberOfLines = 0
            mainTitleLabel.backgroundColor = .clear
            mainTitleLabel.lineBreakMode = .byTruncatingTail
        }

        self.addSubview(openButton)
        openButton.snp.makeConstraints { (make) in
            make.top.equalTo(centerContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(260)
            make.height.equalTo(40)
            make.bottom.equalTo(-20)
        }
        openButton.titleLabel?.snp.makeConstraints({ (make) in
            make.width.lessThanOrEqualTo(240)
        })
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        openButton.backgroundColor = UIColor.ud.colorfulBlue
        openButton.layer.cornerRadius = 4
        openButton.addTarget(self, action: #selector(clickOpenButton(button:)), for: .touchUpInside)
        if let title = vm.openButtonTitle {
            openButton.setTitle(title, for: .normal)
            openButton.setTitle(title, for: .selected)
            openButton.setTitleColor(.white, for: .normal)
            openButton.setTitleColor(.white, for: .selected)
        }

        self.addSubview(shutButton)
        shutButton.setImage(Resources.shut_menu, for: .normal)
        shutButton.setImage(Resources.shut_menu, for: .selected)
        shutButton.backgroundColor = .clear
        shutButton.adjustsImageWhenHighlighted = false
        shutButton.snp.makeConstraints { (make) in
            make.top.equalTo(13.5)
            make.right.equalTo(-13.5)
            make.width.height.equalTo(30)
        }
        shutButton.addTarget(self, action: #selector(clickShutButton(button:)), for: .touchUpInside)
    }

    private func configNoImageTemplate(viewModel: ShareTokenAlertViewModel) {
        self.addSubview(mainTitleLabel)
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        if let handler = viewModel.openAtHandler {
            self.openAtHandler = handler
        }
        mainTitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(24)
            make.width.lessThanOrEqualTo(240)
            make.height.equalTo(22)
        }
        if let text = viewModel.mainTitle {
            mainTitleLabel.text = text
            mainTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            mainTitleLabel.textColor = UIColor.ud.N900
            mainTitleLabel.textAlignment = .center
            mainTitleLabel.backgroundColor = .clear
        }

        self.addSubview(centerContainer)
        centerContainer.layer.cornerRadius = 4
        centerContainer.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
            make.width.equalTo(260)
        }
        centerContainer.backgroundColor = UIColor.ud.N100

        if let text = viewModel.subtitle {
            centerContainer.addSubview(subtitleTitleLabel)
            subtitleTitleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(12)
                make.width.equalTo(240)
                make.height.greaterThanOrEqualTo(22)
                make.height.lessThanOrEqualTo(UIScreen.main.bounds.height)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-12)
            }
            let attributedString = NSMutableAttributedString(string: text,
                                                             attributes: [
                                                                 .font: UIFont.systemFont(ofSize: 14),
                                                                 .foregroundColor: UIColor.ud.N600,
                                                                 .kern: 0.0])
            viewModel.atUserIdRangeMap.forEach { (arg0) -> Void in
                let (userId, ranges) = arg0
                ranges.forEach { (range) in
                    let color = (vm.userClickEnableMap[userId] ?? false) ? UIColor.ud.colorfulBlue : UIColor.ud.N900
                    attributedString.addAttributes([NSAttributedString.Key.foregroundColor: color], range: range)
                }
            }
            subtitleTitleLabel.attributedText = attributedString
            subtitleTitleLabel.delegate = self
            subtitleTitleLabel.tapableRangeList = viewModel.tapableRangeList
            self.atUserIdRangeMap = viewModel.atUserIdRangeMap
            self.userClickEnableMap = viewModel.userClickEnableMap
            subtitleTitleLabel.numberOfLines = 0
            subtitleTitleLabel.backgroundColor = .clear
            subtitleTitleLabel.textAlignment = .left
            subtitleTitleLabel.preferredMaxLayoutWidth = 240
        }

        self.addSubview(openButton)
        openButton.addTarget(self, action: #selector(clickOpenButton(button:)), for: .touchUpInside)
        openButton.backgroundColor = UIColor.ud.colorfulBlue
        openButton.layer.cornerRadius = 4
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        openButton.titleLabel?.textColor = .white
        openButton.snp.makeConstraints { (make) in
            make.top.equalTo(centerContainer.snp.bottom).offset(36)
            make.centerX.equalToSuperview()
            make.width.equalTo(260)
            make.height.equalTo(40)
            make.bottom.equalTo(-19.5)
        }
        openButton.titleLabel?.snp.makeConstraints({ (make) in
            make.width.lessThanOrEqualTo(240)
        })
        if let title = vm.openButtonTitle {
            openButton.setTitle(title, for: .normal)
            openButton.setTitle(title, for: .selected)
        }

        self.addSubview(shutButton)
        shutButton.setImage(Resources.shut_icon, for: .normal)
        shutButton.setImage(Resources.shut_icon, for: .selected)
        shutButton.adjustsImageWhenHighlighted = false
        shutButton.backgroundColor = .clear
        shutButton.snp.makeConstraints { (make) in
            make.top.equalTo(14)
            make.right.equalTo(-14)
            make.width.height.equalTo(20)
        }
        shutButton.addTarget(self, action: #selector(clickShutButton(button:)), for: .touchUpInside)
    }

    @objc
    private func clickShutButton(button: UIButton) {
        if let handler = self.vm.clickShutButtonHandler {
            handler(button)
        }
    }

    @objc
    private func clickOpenButton(button: UIButton) {
        if let handler = self.vm.clickOpenButtonHandler {
            handler(button)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ShareTokenAlertView: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        for (userId, ranges) in self.atUserIdRangeMap where ranges.contains(range) {
            if let handler = self.openAtHandler, self.userClickEnableMap[userId] ?? false {
                handler(userId)
            }
            return false
        }
        return true
    }
}
