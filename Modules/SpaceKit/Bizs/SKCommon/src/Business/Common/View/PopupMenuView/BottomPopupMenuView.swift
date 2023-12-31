//
//  BottomPopupViewController+Views.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/30.
// swiftlint:disable line_length

import SKUIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignIcon

public protocol BottomPopupVCMenuDelegate: AnyObject {
    func menuDidConfirm(_ menu: BottomPopupMenuView)
    func menuClosed(_ menu: BottomPopupMenuView)
    func menuDidClickSendLark(_ menu: BottomPopupMenuView)
    func menuOnClick(_ menu: BottomPopupMenuView, at url: URL) -> Bool
}

extension BottomPopupVCMenuDelegate {
    public func menuClosed(_ menu: BottomPopupMenuView) {}
    public func menuDidClickSendLark(_ menu: BottomPopupMenuView) {}
}

public struct PopupMenuConfig {
    let title: String?
    let content: NSAttributedString?
    let confirmBtn: String?
    let sendLarkText: String?
    public var sendLark: Bool = true
    public var isPopover: Bool = false
    public var extraInfo: Any?
    public var actionSource: BottomPopupModel.ActionSource?

    let confirmBtnColor: UIColor = UIColor.ud.colorfulBlue
    let confirmTitleColor: UIColor = UIColor.ud.N00

    public init(title: String?, content: NSAttributedString?, confirmBtn: String?, sendLarkText: String?, sendLark: Bool = true, isPopover: Bool = false, actionSource: BottomPopupModel.ActionSource? = nil) {
        self.title = title
        self.content = content
        self.confirmBtn = confirmBtn
        self.sendLarkText = sendLarkText
        self.sendLark = sendLark
        self.isPopover = isPopover
        self.actionSource = actionSource
    }
}

public final class BottomPopupMenuView: UIView {
    public var config: PopupMenuConfig

    weak var delegate: BottomPopupVCMenuDelegate?

    public var permStatistics: PermissionStatistics?

    private lazy var content: UITextView = setupContentTextView()

    private(set) lazy var titleView: UIView = setupTitleView()
    private lazy var titleLabel: UILabel = setupTitleLabel()
    private lazy var titleLine: UIView = setupLine()
    private lazy var closeBtn: UIButton = setupCloseButton()
    private lazy var grayButton: UIView = setupGrayButton()

    private lazy var bottomView: UIView = setupBottomView()
    private lazy var bottomLine: UIView = setupLine()
    private lazy var rightBtn: UIButton = setupConfirmButton()
    private lazy var sendBtn: SKCheckBoxButton = setupSendLark()

    private(set) var sendLark: Bool = true

    init(config: PopupMenuConfig) {
        self.config = config
        super.init(frame: .zero)
        self.backgroundColor = UDColor.bgBody
        addSubview(titleView)
        addSubview(titleLine)
        addSubview(content)
        addSubview(bottomLine)
        addSubview(bottomView)
        let lineHeight: CGFloat = 1.0

        // Title
        titleView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(49)
        }
        if config.isPopover {
            titleView.addSubview(titleLabel)

            titleLabel.textAlignment = .center
            titleLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            titleLine.snp.makeConstraints { (make) in
                make.left.width.equalToSuperview()
                make.height.height.equalTo(lineHeight)
                make.top.equalTo(titleView.snp.bottom)
            }
        } else {
            titleView.addSubview(titleLabel)
            titleView.addSubview(closeBtn)
            titleView.addSubview(grayButton)

            closeBtn.snp.makeConstraints { (make) in
                make.width.height.equalTo(24)
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.right.equalTo(closeBtn.snp.left)
            }
            titleLine.snp.makeConstraints { (make) in
                make.left.width.equalToSuperview()
                make.height.height.equalTo(lineHeight)
                make.top.equalTo(titleView.snp.bottom)
            }
            grayButton.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(8.5)
                make.height.equalTo(4)
                make.width.equalTo(40)
            }
        }

        // Content
        content.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom).offset(lineHeight)
            make.bottom.equalTo(bottomView.snp.top).offset(-lineHeight)
            make.left.equalToSuperview().offset(11)
            make.right.equalToSuperview().offset(-11)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.left.width.equalToSuperview()
            make.height.height.equalTo(lineHeight)
            make.top.equalTo(content.snp.bottom)
        }

        // Bottom
        bottomView.addSubview(rightBtn)
        bottomView.addSubview(sendBtn)
        bottomView.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.left.right.bottom.equalToSuperview()
        }
        rightBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(28)
            make.right.equalToSuperview().offset(-16)
        }
        sendBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.right.equalTo(rightBtn.snp.left)
            make.height.equalTo(28)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Views and Actions
extension BottomPopupMenuView {
    private func setupTitleView() -> UIView {
        let view = UIView()
        return view
    }

    private func setupTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = config.title
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }

    private func setupCloseButton() -> UIButton {
        let btn = UIButton()
        btn.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        return btn
    }

    private func setupGrayButton() -> UIView {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 3
        return view
    }

    private func setupContentTextView() -> UITextView {
        let view = UITextView()
        view.backgroundColor = UDColor.bgBody
        view.isScrollEnabled = false
        view.isSelectable = true
        view.isEditable = false
        view.attributedText = config.content
        view.textColor = UDColor.textTitle
        view.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UDColor.primaryContentDefault,
                                   NSAttributedString.Key.underlineColor: UIColor.clear]
        view.delegate = self
        return view
    }

    private func setupSendLark() -> SKCheckBoxButton {
        let button = SKCheckBoxButton(config: SKCheckBoxButton.Config(text: config.sendLarkText,
                                                                      textColor: UIColor.ud.N1000,
                                                                      font: UIFont.systemFont(ofSize: 16),
                                                                      margin: 8,
                                                                      edgeLength: 20,
                                                                      type: .single))
        button.isSelected = sendLark
        button.addTarget(self, action: #selector(sendLarkAction), for: .touchUpInside)
        return button
    }

    private func setupBottomView() -> UIView {
        let view = UIView()
        return view
    }

    private func setupConfirmButton() -> UIButton {
        let btn = UIButton()
        btn.backgroundColor = config.confirmBtnColor
        btn.setTitle(config.confirmBtn, for: .normal)
        btn.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.layer.cornerRadius = 4
        btn.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        return btn
    }

    private func setupLine() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N1000
        line.alpha = 0.1
        return line
    }

    @objc
    private func closeAction() {
        delegate?.menuClosed(self)
        self.permStatistics?.reportPermissionShareAtPeopleClick(click: .close, target: .noneTargetView)
    }
    @objc
    private func confirmAction() {
        delegate?.menuDidConfirm(self)
        self.permStatistics?.reportPermissionShareAtPeopleClick(click: .confirm,
                                                                target: .noneTargetView,
                                                                isSendNotice: config.sendLark)
    }

    @objc
    private func sendLarkAction() {
        sendLark = !sendLark
        sendBtn.isSelected = sendLark
        config.sendLark = sendLark
        delegate?.menuDidClickSendLark(self)
    }
}

extension BottomPopupMenuView: UITextViewDelegate {
    public func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        return delegate?.menuOnClick(self, at: URL) ?? false
    }
}
