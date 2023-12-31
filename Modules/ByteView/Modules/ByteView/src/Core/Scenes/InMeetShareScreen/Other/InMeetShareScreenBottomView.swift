//
//  InMeetShareScreenBottomView.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewCommon
import UniverseDesignIcon

class InMeetShareScreenBottomView: UIView {

    /// safeAreaLeft - infoLabel左侧
    private let leftSpacer = UILayoutGuide()
    /// annotateButton右侧 - safeAreaRight
    private let rightSpacer = UILayoutGuide()

    private var heightConstraint: NSLayoutConstraint?

    private enum Layout {
        /// 按钮圆角
        static let commonButtonCornerRadius: CGFloat = 6.0
        /// 按钮边框宽度
        static let commonButtonBorderWidth: CGFloat = 1.0
        /// 按钮高度
        static let commonButtonDimension: CGFloat = Display.phone ? 28.0 : 24.0
        /// 按钮文字大小
        static let commonButtonLabelFontSize: CGFloat = Display.phone ? 14.0 : 12.0
        /// 带文字按钮缩进
        static let commonTextButtonContentInsets: UIEdgeInsets = UIEdgeInsets(top: commonTextButtonContentInsetsVerticalSpacing,
                                                                              left: commonTextButtonContentInsetsHorizontalSpacing,
                                                                              bottom: commonTextButtonContentInsetsVerticalSpacing,
                                                                              right: commonTextButtonContentInsetsHorizontalSpacing)
        /// 带文字按钮竖直方向缩进距离
        static let commonTextButtonContentInsetsVerticalSpacing: CGFloat = 4.0
        /// 带文字按钮水平方向缩进距离
        static let commonTextButtonContentInsetsHorizontalSpacing: CGFloat = 8.0
        /// 标签文字大小
        static let commonLabelFontSize: CGFloat = 12.0
        /// 标注图片大小
        static let annotateImageSize: CGSize = Display.phone ? CGSize(width: 18.0, height: 18.0) : CGSize(width: 16.0, height: 16.0)
        /// 标签和标注按钮最小间距
        static let minInfoLabelRightOffset: CGFloat = Display.phone ? 12.0 : 20.0
        /// 标注和自由浏览按钮的间距
        static let freeToBrowseLeftOffset: CGFloat = 12.0
    }

    /// 自由浏览按钮渐变色
    let freeToBrowseButtonGradientColor: UIColor = {
        let width = NSAttributedString(string: I18n.View_SPM_ViewBySelf,
                                       config: VCFontConfig(fontSize: Layout.commonButtonLabelFontSize,
                                                            lineHeight: Layout.commonButtonLabelFontSize,
                                                            fontWeight: .regular))
            .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT),
                                       height: Layout.commonButtonDimension),
                          context: nil)
            .width + Layout.commonTextButtonContentInsetsHorizontalSpacing * 2
        let ceiledWidth = ceil(width) // 不ceil的话可能四舍五入导致差1个pt，右侧会有一小块空白
        let gradientImage = UIImage.vc.obliqueGradientImage(bounds: CGRect(origin: .zero,
                                                                           size: CGSize(width: ceiledWidth,
                                                                                        height: Layout.commonButtonDimension)),
                                                            colors: [UIColor.ud.colorfulViolet,
                                                                     UIColor.ud.R400,
                                                                     UIColor.ud.colorfulYellow])
        return UIColor(patternImage: gradientImage)
    }()

    /// 提示标签
    lazy var infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.systemFont(ofSize: Layout.commonLabelFontSize)
        lbl.textColor = UIColor.ud.textTitle
        lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return lbl
    }()

    static let annotateNormalImage: UIImage = UDIcon.getIconByKey(.editOutlined, iconColor: .ud.iconN2, size: Layout.annotateImageSize)
    static let annotateDisabledImage: UIImage = UDIcon.getIconByKey(.editOutlined, iconColor: .ud.iconDisabled, size: Layout.annotateImageSize)
    static let annotateHighlightedImage: UIImage = UDIcon.getIconByKey(.editOutlined, iconColor: .ud.iconN2, size: Layout.annotateImageSize)

    /// 标注按钮
    lazy var annotateButton: LoadingButton = {
        let btn = LoadingButton(type: .custom)
        btn.setImage(Self.annotateNormalImage, for: .normal)
        btn.setImage(Self.annotateDisabledImage, for: .disabled)
        btn.setImage(Self.annotateHighlightedImage, for: .highlighted)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .disabled)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .vertical)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = Layout.commonButtonCornerRadius
        btn.layer.borderWidth = Layout.commonButtonBorderWidth
        btn.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        btn.addInteraction(type: .lift)
        btn.isLoading = false
        return btn
    }()

    /// 背景色视图
    lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = bgColor
        return view
    }()

    /// 自由浏览按钮（投屏转妙享）
    lazy var freeToBrowseButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(I18n.View_SPM_ViewBySelf, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: Layout.commonButtonLabelFontSize)
        btn.setTitleColor(.ud.textDisabled, for: .normal)
        btn.setTitleColor(.ud.textDisabled, for: .highlighted)
        btn.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        btn.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .highlighted)
        btn.contentEdgeInsets = Layout.commonTextButtonContentInsets
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .vertical)
        btn.clipsToBounds = true
        btn.layer.cornerRadius = Layout.commonButtonCornerRadius
        btn.layer.borderWidth = Layout.commonButtonBorderWidth
        btn.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        btn.addInteraction(type: .lift)
        btn.addTarget(self, action: #selector(didTapFreeToBrowse), for: .touchUpInside)
        return btn
    }()

    /// 点击“自由浏览”按钮的操作
    var freeToBrowseAction: ((ClickFreeToBrowseButtonSwitchReason) -> Void)?

    var blockTapFreeToBrowseButtonAction: (() -> Bool)?

    var freeToBrowseButtonDisplayStyle: ShareScreenFreeToBrowseViewDisplayStyle = .hidden {
        didSet {
            updateLayout()
        }
    }

    lazy var isPortrait: Bool = self.isPhonePortrait {
        didSet {
            guard oldValue != isPortrait else {
                return
            }
            updateLayout()
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard oldValue != meetingLayoutStyle else {
                return
            }
            updateLayout()
        }
    }

    lazy var isPadCompact: Bool = Display.pad && traitCollection.isCompact {
        didSet {
            guard oldValue != isPadCompact else {
                return
            }
            updateLayout()
        }
    }

    /// 被共享屏幕操作栏背景色
    private var bgColor: UIColor {
        let color = UIColor.ud.vcTokenMeetingBgVideoOff
        return (isPhoneLandscape || meetingLayoutStyle != .tiled) ? color.withAlphaComponent(0.92) : color
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonBackgroundColor()
    }

    let service: MeetingBasicService
    init(service: MeetingBasicService) {
        self.service = service
        super.init(frame: .zero)

        self.addSubview(backgroundView)
        self.addSubview(infoLabel)
        self.addSubview(annotateButton)
        self.addLayoutGuide(leftSpacer)
        self.addLayoutGuide(rightSpacer)
        self.addSubview(freeToBrowseButton)

        self.heightConstraint = self.heightAnchor.constraint(equalToConstant: 40.0)
        self.heightConstraint?.priority = .defaultHigh
        self.heightConstraint?.isActive = true

        leftSpacer.snp.makeConstraints { make in
            make.left.equalTo(self.safeAreaLayoutGuide)
            make.width.equalTo(rightSpacer)
        }
        rightSpacer.snp.makeConstraints { make in
            make.right.equalTo(self.safeAreaLayoutGuide)
        }

        backgroundView.frame = self.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.isPortrait = isPhonePortrait
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateLayout() {
        Util.runInMainThread { [weak self] in
            self?.updateLayoutOnMainThread()
        }
    }

    private func updateLayoutOnMainThread() {
        backgroundView.backgroundColor = bgColor
        freeToBrowseButton.isHidden = freeToBrowseButtonDisplayStyle.isFreeToBrowseButtonHidden
        if isPhonePortrait {
            remakePortraitConstraints()
        } else {
            remakeLandscapeConstraints()
        }
        updateButtonBackgroundColor()
    }

    private func remakePortraitConstraints() {
        self.heightConstraint?.constant = 40.0
        let leftOffset: CGFloat = Display.phone ? 12.0 : 16.0
        let rightOffset: CGFloat = Display.phone ? -20.0 : -16.0
        let isFreeToBrowseHidden: Bool = freeToBrowseButtonDisplayStyle.isFreeToBrowseButtonHidden
        infoLabel.snp.remakeConstraints {
            $0.left.equalTo(self.safeAreaLayoutGuide).offset(leftOffset)
            $0.right.lessThanOrEqualTo(annotateButton.snp.left).offset(rightOffset)
            $0.centerY.equalToSuperview()
        }
        annotateButton.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.size.equalTo(Layout.commonButtonDimension)
            if isFreeToBrowseHidden {
                $0.right.equalTo(self.safeAreaLayoutGuide).offset(-leftOffset)
            }
        }
        if !isFreeToBrowseHidden {
            freeToBrowseButton.snp.remakeConstraints {
                $0.left.equalTo(annotateButton.snp.right).offset(Layout.freeToBrowseLeftOffset)
                $0.right.equalTo(self.safeAreaLayoutGuide).offset(-leftOffset)
                $0.centerY.equalTo(annotateButton)
                $0.height.equalTo(Layout.commonButtonDimension)
            }
        }
    }

    private func remakeLandscapeConstraints() {
        self.heightConstraint?.constant = Display.phone ? 36 : 32
        let minOffset: CGFloat = Layout.minInfoLabelRightOffset
        let isFreeToBrowseHidden: Bool = freeToBrowseButtonDisplayStyle.isFreeToBrowseButtonHidden
        let isPadCompact = self.isPadCompact
        infoLabel.snp.remakeConstraints {
            $0.left.equalTo(leftSpacer.snp.right)
            $0.centerY.equalToSuperview()
        }
        switch (isFreeToBrowseHidden, isPadCompact) {
        case (true, _):
            annotateButton.snp.remakeConstraints {
                $0.right.equalTo(rightSpacer.snp.left)
                $0.left.equalTo(infoLabel.snp.right).offset(minOffset)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(Layout.commonButtonDimension)
            }
            freeToBrowseButton.snp.removeConstraints()
        case (false, true):
            annotateButton.snp.remakeConstraints {
                $0.left.equalTo(infoLabel.snp.right).offset(minOffset)
                $0.left.greaterThanOrEqualToSuperview().offset(16.0)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(Layout.commonButtonDimension)
            }
            freeToBrowseButton.snp.remakeConstraints {
                $0.left.equalTo(annotateButton.snp.right).offset(Layout.freeToBrowseLeftOffset)
                $0.right.equalTo(rightSpacer.snp.left)
                $0.right.lessThanOrEqualToSuperview().offset(-16.0)
                $0.centerY.equalTo(annotateButton)
                $0.height.equalTo(Layout.commonButtonDimension)
            }
        case (false, false):
            annotateButton.snp.remakeConstraints {
                $0.left.equalTo(infoLabel.snp.right).offset(minOffset)
                $0.centerY.equalToSuperview()
                $0.size.equalTo(Layout.commonButtonDimension)
            }
            freeToBrowseButton.snp.remakeConstraints {
                $0.left.equalTo(annotateButton.snp.right).offset(Layout.freeToBrowseLeftOffset)
                $0.centerY.equalTo(annotateButton)
                $0.height.equalTo(Layout.commonButtonDimension)
                $0.right.equalTo(rightSpacer.snp.left)
            }
        }
    }

    private func updateButtonBackgroundColor() {
        let isLandscapeStyle: Bool = isPhoneLandscape
        let isFreeToBrowseButtonOperable: Bool = freeToBrowseButtonDisplayStyle == .operable
        let gradientColor = self.freeToBrowseButtonGradientColor
        switch (isLandscapeStyle, isFreeToBrowseButtonOperable) {
        case (true, true): // 手机横屏，可开启自由浏览
            freeToBrowseButton.setTitleColor(gradientColor, for: .normal)
            freeToBrowseButton.setTitleColor(gradientColor, for: .highlighted)
            freeToBrowseButton.vc.setBackgroundColor(.ud.bgBody, for: .normal)
            freeToBrowseButton.vc.setBackgroundColor(gradientColor.withAlphaComponent(0.16), for: .highlighted)
            freeToBrowseButton.layer.ud.setBorderColor(gradientColor)
            annotateButton.vc.setBackgroundColor(.ud.bgBody, for: .normal)
            annotateButton.vc.setBackgroundColor(.ud.bgBody, for: .disabled)
        case (true, false): // 手机横屏，不可开启自由浏览
            freeToBrowseButton.setTitleColor(.ud.textDisabled, for: .normal)
            freeToBrowseButton.setTitleColor(.ud.textDisabled, for: .highlighted)
            freeToBrowseButton.vc.setBackgroundColor(.ud.bgBody, for: .normal)
            freeToBrowseButton.vc.setBackgroundColor(.ud.bgBody, for: .highlighted)
            freeToBrowseButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            annotateButton.vc.setBackgroundColor(.ud.bgBody, for: .normal)
            annotateButton.vc.setBackgroundColor(.ud.bgBody, for: .disabled)
        case (false, true): // 非手机横屏，可开启自由浏览
            freeToBrowseButton.setTitleColor(gradientColor, for: .normal)
            freeToBrowseButton.setTitleColor(gradientColor, for: .highlighted)
            freeToBrowseButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
            freeToBrowseButton.vc.setBackgroundColor(gradientColor.withAlphaComponent(0.16), for: .highlighted)
            freeToBrowseButton.layer.ud.setBorderColor(gradientColor)
            annotateButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
            annotateButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .disabled)
        case (false, false): // 非手机横屏，不可开启自由浏览
            freeToBrowseButton.setTitleColor(.ud.textDisabled, for: .normal)
            freeToBrowseButton.setTitleColor(.ud.textDisabled, for: .highlighted)
            freeToBrowseButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
            freeToBrowseButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .highlighted)
            freeToBrowseButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
            annotateButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
            annotateButton.vc.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .disabled)
        }
    }

    @objc
    func didTapFreeToBrowse() {
        Logger.ui.debug("did tap free to browse button")
        if blockTapFreeToBrowseButtonAction?() != true {
            freeToBrowse(with: .barIcon)
        }
    }

    func freeToBrowse(with switchReason: ClickFreeToBrowseButtonSwitchReason) {
        switch freeToBrowseButtonDisplayStyle {
        case .operable:
            service.storage.set(true, forKey: .presenterAllowFree)
            freeToBrowseAction?(switchReason)
        case .disabled:
            Toast.showOnVCScene(I18n.View_G_PresenterOffVOMO)
        default:
            break
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return backgroundView.point(inside: backgroundView.convert(point, from: self), with: event)
    }
}
