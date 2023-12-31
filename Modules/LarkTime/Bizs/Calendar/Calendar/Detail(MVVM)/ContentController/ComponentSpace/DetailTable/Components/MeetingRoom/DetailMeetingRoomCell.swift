//
//  MeetingRoomCombo.swift
//  Calendar
//
//  Created by jiayi zou on 2018/2/2.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import RustPB
import CalendarFoundation
import LarkEMM
import UniverseDesignToast
import LarkSensitivityControl

protocol DetailMeetingRoomItemContent {
    var statusTitle: String? { get }
    var title: String { get }
    var isAvailable: Bool { get }
    var isDisabled: Bool { get }
    var appLink: String? { get }
    var calendarID: String { get }
}

protocol DetailMeetingRoomCellContent {
    var items: [DetailMeetingRoomItemContent] { get }
}

final class DetailMeetingRoomCell: DetailCell {

    private let stackView = UIStackView()
    private var copyText: String = ""
    private let FoldingLimitCount = 10
    private var viewData: DetailMeetingRoomCellContent? {
        didSet {
            guard let viewData = viewData else { return }
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            let shownItems: [DetailMeetingRoomItemContent]
            let showAll: Bool

            if viewData.items.count > FoldingLimitCount {
                // 支持会议室多选，大于10个要折叠
                shownItems = Array(viewData.items[0..<FoldingLimitCount])
                showAll = true
            } else {
                shownItems = viewData.items
                showAll = false
            }
            copyText = ""
            for (index, item) in shownItems.enumerated() {
                let itemView = Self.makeItemView(with: item, of: index) { [weak self] button in
                    self?.didClickTrailingView(button)
                }
                itemView.tag = index
                let tagGesture = UITapGestureRecognizer(target: self, action: #selector(didClickItemView(_:)))
                itemView.addGestureRecognizer(tagGesture)
                stackView.addArrangedSubview(itemView)

                // 复制的时候只包含会议室信息(title)，不包含status信息(statusTitle)
                copyText = appendTitleText(copyText: copyText, title: item.title)
            }
            if showAll {
                let showAll = makeShowAllView()
                stackView.addArrangedSubview(showAll)
            }
        }
    }

    var selectedAction: ((_ index: Int, _ clickIcon: Bool) -> Void)?
    var showAllAction: (() -> Void)?

    init(selectedAction: @escaping (Int, Bool) -> Void,
         showAllAction: (() -> Void)?) {
        self.selectedAction = selectedAction
        self.showAllAction = showAllAction
        super.init(frame: .zero)
        self.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(42)
        }
        self.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.roomOutlined).renderColor(with: .n3))
        self.layoutStackView(stackView)
        self.attachLongHandle()
    }

    func updateContent(_ content: DetailMeetingRoomCellContent?) {
        viewData = content
    }

    @objc
    private func didClickItemView(_ tap: UITapGestureRecognizer) {
        selectedAction?(tap.view?.tag ?? 0, false)
    }

    @objc
    private func didClickTrailingView(_ sender: UIButton) {
        selectedAction?(sender.tag ?? 0, true)
    }

    private func makeShowAllView() -> EventBasicCellLikeView {
        let itemView = EventBasicCellLikeView()
        itemView.icon = .none
        itemView.backgroundColors = (UIColor.clear, UIColor.ud.fillHover)
        let titleContent = EventBasicCellLikeView.ContentTitle(
            text: BundleI18n.Calendar.Calendar_Edit_ViewAll,
            color: UIColor.ud.B700,
            font: UIFont.ud.body0(.fixed)
        )
        itemView.content = .title(titleContent)
        itemView.snp.makeConstraints {
            $0.height.equalTo(22)
        }

        itemView.onClick = { [weak self] in
            guard let self = self else { return }
            self.showAllAction?()
        }
        return itemView
    }

    private func appendTitleText(copyText: String, title: String) -> String {
        if copyText.isEmpty {
            return title
        }
        return copyText + "\n\(title)"
    }

    private func layoutStackView(_ stackView: UIStackView) {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        let wrapper = UIView()
        wrapper.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.bottom.equalToSuperview()
        }
        self.addCustomView(wrapper)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var canBecomeFirstResponder: Bool {
        return true
    }

    private func attachLongHandle() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuControllerWillHide),
                                               name: UIMenuController.willHideMenuNotification,
                                               object: nil)
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(showMenu(sender:))
        ))
    }

    @objc
    func menuControllerWillHide() {
        self.backgroundColor = UIColor.clear
    }

    func menuControllerWillShow() {
        self.backgroundColor = UIColor.ud.N800.withAlphaComponent(0.05)
    }

    @objc
    func copyText(_ sender: Any?) {
        do {
            let config = PasteboardConfig(token: LarkSensitivityControl.Token(SCPasteboardUtils.getSceneKey(.eventDetailMeetingRoomInfoCopy)))
            try SCPasteboard.generalUnsafe(config).string = copyText
        } catch {
            SCPasteboardUtils.logCopyFailed()
            if let window = self.window {
                UDToast.showTips(with: I18n.Calendar_Share_UnableToCopy, on: window)
            }
        }
        UIMenuController.shared.setMenuVisible(false, animated: true)
        self.backgroundColor = UIColor.clear
    }

    @objc
    func showMenu(sender: UIGestureRecognizer) {
        becomeFirstResponder()
        CalendarTracer.shareInstance.calDetailCopy(elementType: .mtgroom)
        let menu = UIMenuController.shared
        menu.menuItems = [UIMenuItem(title: BundleI18n.Calendar.Calendar_Common_Copy, action: #selector(copyText(_:)))]
        if !menu.isMenuVisible {
            self.menuControllerWillShow()
            let point = sender.location(in: self)
            let rect = CGRect(x: point.x, y: 0, width: 1, height: self.bounds.height)
            menu.setTargetRect(rect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(copyText(_:)))
    }

    deinit {
        self.resignFirstResponder()
        NotificationCenter.default.removeObserver(self)
    }
}

extension DetailMeetingRoomCell {
    // 与二级已选会议室页面公用UI
    static func makeItemView(with item: DetailMeetingRoomItemContent, of itemIndex: Int, didClickTrailingButton: ((UIButton) -> Void)? = nil) -> UIView {
        let containerView = UIView()

        let font = UIFont.ud.body0(.fixed)
        let style = NSMutableParagraphStyle()
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        style.minimumLineHeight = fontFigmaHeight
        style.maximumLineHeight = fontFigmaHeight
        let normalAttributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font: font,
                                NSAttributedString.Key.baselineOffset: baselineOffset,
                                NSAttributedString.Key.paragraphStyle: style]
        let strikethroughAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder,
            NSAttributedString.Key.strikethroughStyle: NSNumber(value: 1),
            NSAttributedString.Key.strikethroughColor: UIColor.ud.textPlaceholder,
            NSAttributedString.Key.baselineOffset: baselineOffset,
            NSAttributedString.Key.paragraphStyle: style,
        ]
        let statusAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.baselineOffset: baselineOffset,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.foregroundColor: item.appLink.isEmpty ? UIColor.ud.textPlaceholder : UIColor.ud.primaryContentPressed
        ]
        let text = NSMutableAttributedString()
        if let statusTitle = item.statusTitle {
            let statusText = NSAttributedString(string: statusTitle, attributes: statusAttributes)
            text.append(statusText)
        }
        text.append(NSAttributedString(string: item.title,
                                       attributes: item.isAvailable ? normalAttributes : strikethroughAttributes))

        let contentView = TopAlignView(tailingView: TagViewProvider.inactivate())
        contentView.label.attributedText = text
        contentView.isUserInteractionEnabled = false
        contentView.showTailingView(item.isDisabled)

        let tailingBtn = UIButton()
        tailingBtn.setImage(UDIcon.getIconByKeyNoLimitSize(.infoOutlined).renderColor(with: .n2).withRenderingMode(.alwaysOriginal), for: .normal)
        tailingBtn.increaseClickableArea(top: -16, left: -16, bottom: -16, right: -16)
        tailingBtn.tag = itemIndex
        tailingBtn.rx.controlEvent(.touchUpInside).subscribe(onNext: {[weak tailingBtn] in
            guard let button = tailingBtn else { return }
            didClickTrailingButton?(button)
        })
        containerView.addSubview(tailingBtn)
        tailingBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(3) // offset 是为了跟第一行的文本垂直居中对齐
            make.right.equalToSuperview()
            make.width.height.equalTo(16)
        }

        containerView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(tailingBtn.snp.left).offset(-16)
        }
        return containerView
    }
}
