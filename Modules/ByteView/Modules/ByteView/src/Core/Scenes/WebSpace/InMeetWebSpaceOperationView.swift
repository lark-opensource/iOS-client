//
//  InMeetWebSpaceOperationView.swift
//  ByteView
//
//  Created by fakegourmet on 2022/12/7.
//

import Foundation
import UniverseDesignIcon
import ByteViewUI

class InMeetWebSpaceOperationView: UIView {

    private enum Layout {

        // common
        static let commonButtonCornerRadius: CGFloat = 6.0
        static let commonButtonBorderWidth: CGFloat = 1.0
        static let commonButtonContentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 8.0)
        static let commonInteractionWidth: CGFloat = 24.0
        static let commonInteractionHeight: CGFloat = 10.0

        // specified
        static let copyAndRefreshButtonImageDimension: CGFloat = 18.0
    }

    /// 布局样式(沉浸态/堆叠态/平铺态)
    lazy var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            updateLayout()
        }
    }

    /// 操作栏整体，控制高度
    private let contentView = UIView()

    /// 显示正在共享的内容
    private(set) var fileNameLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999), for: .horizontal)
        return label
    }()

    /// 刷新按钮
    private(set) lazy var refreshButton: VisualButton = {
        let button = VisualButton()
        button.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)),
                        for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.addInteraction(type: .highlight,
                              shape: .roundedRect(CGSize(width: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionWidth,
                                                         height: Layout.copyAndRefreshButtonImageDimension + Layout.commonInteractionHeight), 6.0))
        return button
    }()

    /// 停止共享
    private(set) lazy var stopSharingButton: VisualButton = {
        let button = VisualButton()
        button.contentEdgeInsets = Layout.commonButtonContentEdgeInsets
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.setAttributedTitle(.init(string: I18n.View_G_HideBackgroundPage_Button, config: .bodyAssist, alignment: .center, textColor: UIColor.ud.textTitle), for: .normal)
        button.layer.masksToBounds = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setBorderColor(UIColor.ud.lineBorderComponent, for: .normal)
        button.layer.borderWidth = Layout.commonButtonBorderWidth
        button.layer.cornerRadius = Layout.commonButtonCornerRadius
        button.addInteraction(type: .lift)
        if Display.pad {
            button.extendEdge = UIEdgeInsets(top: -2, left: 0, bottom: -2, right: 0)
        }
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        updateBackgroundColor()

        setupSubviews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBackgroundColor() {
        if isPhonePortrait {
            backgroundColor = UIColor.ud.vcTokenMeetingBgMobileShareBar
        } else if Display.pad, meetingLayoutStyle != .tiled {
            backgroundColor = UIColor.ud.vcTokenMeetingBgShareBarImmersiveMode
        } else {
            backgroundColor = UIColor.ud.bgBody
        }
    }

    private func setupSubviews() {
        // add subviews
        addSubview(contentView)
        contentView.addSubview(fileNameLabel)
        contentView.addSubview(refreshButton)
        contentView.addSubview(stopSharingButton)

        updateLayout()

        fileNameLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(11.0)
            $0.left.equalToSuperview()
        }
        refreshButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(6.0)
            $0.left.equalTo(fileNameLabel.snp.right).offset(8.0)
            $0.width.height.equalTo(28.0)
        }
        stopSharingButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(6.0)
            $0.left.equalTo(refreshButton.snp.right).offset(12.0)
            $0.right.equalToSuperview()
        }

        fileNameLabel.setNeedsLayout()
        fileNameLabel.layoutIfNeeded()
    }

    func updateFileName(_ name: String) {
        fileNameLabel.attributedText = .init(string: name, config: .tinyAssist, textColor: UIColor.ud.textTitle)
        updateLayout()
        fileNameLabel.setNeedsLayout()
        fileNameLabel.layoutIfNeeded()
    }

    func updateLayout() {
        if VCScene.rootTraitCollection?.isRegular == true {
            fileNameLabel.setContentHuggingPriority(.required, for: .horizontal)
            let contentWidth = calculateContentWidth()
            contentView.snp.remakeConstraints {
                $0.center.equalToSuperview()
                $0.height.equalToSuperview()
                $0.width.equalTo(contentWidth)
            }
        } else {
            fileNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            contentView.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.center.equalToSuperview()
                $0.left.right.lessThanOrEqualToSuperview().inset(12.0)
            }
        }
    }

    private func calculateContentWidth() -> CGFloat {
        fileNameLabel.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: contentView.frame.height)).width +
        stopSharingButton.sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: contentView.frame.height)).width +
        48.0
    }
}
