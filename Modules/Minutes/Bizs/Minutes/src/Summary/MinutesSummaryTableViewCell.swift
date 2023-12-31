//
//  MinutesSummaryTableViewCell.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/5/12.
//

import UIKit
import Foundation
import YYText
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import LarkEMM
import LarkContainer
import LarkAccountInterface

class MinutesSummaryTableViewCell: UITableViewCell {
    var onClickCheckboxClosure: ((_ isChecked: Bool, _ timeInterval: Int?) -> Void)?
    var onClickCheckboxLabel: ((_ timeInterval: Int?) -> Void)?
    var onClickUserProfile: ((_ userId: String) -> Void)?
    var onClickCopyBlock: (() -> Void)?
    var onClickSeeOriginText: ((_ contentId: String?) -> Void)?
    var didTextTappedBlock: ((Phrase?) -> Void)?

    static let fontSize: CGFloat = 16

    private lazy var contentYYTextView: YYTextView = {
        let textView: YYTextView = YYTextView(frame: CGRect.zero)
        textView.text = ""
        textView.isHidden = true
        textView.textAlignment = .left
        textView.textColor = UIColor.ud.textTitle
        textView.font = UIFont.systemFont(ofSize: Self.fontSize, weight: .regular)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.allowsCopyAttributedString = false
        textView.layer.masksToBounds = false
        textView.isUserInteractionEnabled = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.customMenu = normalMenu()
        textView.textContainerInset = containerInset
        textView.textTapEndAction = { [weak self] (_, _, range, _) in
            guard let self = self else { return }
            if self.cellData?.type == .checkbox {
                self.onClickCheckboxLabel?(self.cellData?.startTime)
            }

            let filter = self.cellData?.dPhrases.first(where: {$0.range.intersection(range) != nil })
            self.didTextTappedBlock?(filter)
        }
        return textView
    }()

    private lazy var dictBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.N400
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = .dottedLine
        return border
    }()

    var containerInset: UIEdgeInsets {
        return .zero
    }

    private lazy var checkboxButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.isHidden = true
        button.addTarget(self, action: #selector(onClickCheckboxButton(_:)), for: .touchUpInside)
        return button
    }()

    private var cellData: MinutesSummaryViewModel.MinutesSummaryCellData?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(checkboxButton)
        contentView.addSubview(contentYYTextView)

        contentYYTextView.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.bottom.equalToSuperview()
        }

        backgroundColor = UIColor.clear

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleLongPressRects),
                                               name: NSNotification.Name(rawValue: YYTextViewIsInLongPressSelectionRects),
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(menuCopy(_:)) {
            return true
        }
        if action == #selector(menuSeeOrigin(_:)) {
            return true
        }
        return false
    }

    private func layoutSubviewsManually(with type: SummaryContentType) {
        checkboxButton.isHidden = type != .checkbox
        contentYYTextView.isHidden = false
    }

    func setData(data: MinutesSummaryViewModel.MinutesSummaryCellData, currentUserPermission: PermissionCode, isInTranslationMode: Bool, layoutWidth: CGFloat, passportUserService: PassportUserService?) {
        self.cellData = data

        contentYYTextView.removeMySelectionRects()
        layoutSubviewsManually(with: data.type)

        formatContentYYTextView(contentText: data.content, type: data.type, layoutWidth: layoutWidth, passportUserService: passportUserService)

        if data.type == .checkbox {
            if currentUserPermission.contains(.edit) || currentUserPermission.contains(.owner) {

                checkboxButton.setImage(BundleResources.Minutes.minutes_summary_unselected, for: .normal)
                checkboxButton.setImage(BundleResources.Minutes.minutes_summary_selected, for: .selected)
                checkboxButton.isUserInteractionEnabled = true
            } else {
                checkboxButton.setImage(BundleResources.Minutes.minutes_summary_unselected, for: .normal)
                checkboxButton.setImage(BundleResources.Minutes.minutes_summary_selected, for: .selected)
                checkboxButton.isUserInteractionEnabled = false
            }
            checkboxButton.isSelected = data.isChecked
        }

        contentYYTextView.selectionViewBackgroundColor = UIColor.ud.rgb(0xA7B7CB).withAlphaComponent(0.3)
        contentYYTextView.allowLongPressSelectionAlwaysAll = isInTranslationMode
        if isInTranslationMode {
            contentYYTextView.customMenu = translateMenu()
        } else {
            contentYYTextView.customMenu = normalMenu()
        }
        contentYYTextView.removeMySelectionRects()
        if !isInTranslationMode {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35, execute: {
                self.contentYYTextView.removeMySelectionRects()
                data.dPhrases.forEach { (phrase) in
                    self.contentYYTextView.setMySelectionRects(self.dictBorder, range: phrase.range)
                }
            })
        }
    }

    private func translateMenu() -> UIMenuController {
        let menuItems = [
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))),
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_SeeOriginal, action: #selector(menuSeeOrigin(_:)))]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    private func normalMenu() -> UIMenuController {
        var menuItems = [UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:)))]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    @objc
    private func menuCopy(_ menu: UIMenuController) {
        if let text = contentYYTextView.copiedString() as? String {
            Device.pasteboard(token: DeviceToken.pasteboardSummary, text: text)
            onClickCopyBlock?()
        }
    }

    @objc
    private func menuSeeOrigin(_ menu: UIMenuController) {
        if let someAttributedText = contentYYTextView.attributedText {
            onClickSeeOriginText?(cellData?.contentId)
        }
    }

    func hideMenu() {
        contentYYTextView.customMenu?.setMenuVisible(false, animated: true)
    }

    func hideSelectionDot() {
        contentYYTextView.hideSelectionDot()
    }

    @objc func handleLongPressRects(_ notification: Notification) {
        if let object = notification.object as? [Any], let textView = object.last as? YYTextView {
            if textView != contentYYTextView {
                hideMenu()
                hideSelectionDot()
            }
        }
    }

    private func formatContentYYTextView(contentText: String, type: SummaryContentType, layoutWidth: CGFloat, passportUserService: PassportUserService?) {
        let finalAttributedText = MinutesSummaryTableViewCell.getAttributedString(type, contentText: contentText, passportUserService: passportUserService, onClickNameAction: { [weak self] userId in
            guard let wSelf = self else { return }
            wSelf.onClickUserProfile?(userId)
        })

        contentYYTextView.textVerticalAlignment = .top
        contentYYTextView.textAlignment = .left
        contentYYTextView.attributedText = finalAttributedText
        if type == .text {
            let contentYYTextViewHeight: CGFloat = yyTextLayout(with: CGSize(width: layoutWidth - 32, height: 10000), attributedText: finalAttributedText)?.textBoundingSize.height ?? 0
            contentYYTextView.snp.remakeConstraints { maker in
                maker.top.equalToSuperview()
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-16)
                maker.bottom.equalToSuperview()
                maker.height.equalTo(contentYYTextViewHeight)
            }
        } else if type == .checkbox {
            let contentYYTextViewHeight: CGFloat = yyTextLayout(with: CGSize(width: layoutWidth - 62, height: 10000), attributedText: finalAttributedText)?.textBoundingSize.height ?? 0
            contentYYTextView.snp.remakeConstraints { maker in
                maker.top.equalToSuperview()
                maker.left.equalTo(checkboxButton.snp.right).offset(8)
                maker.right.equalToSuperview().offset(-16)
                maker.bottom.equalToSuperview().offset(-5)
                maker.height.equalTo(contentYYTextViewHeight)
            }
            checkboxButton.snp.remakeConstraints { maker in
                maker.top.equalTo(contentYYTextView)
                maker.left.equalToSuperview().offset(16)
                maker.width.height.equalTo(22)
            }
        }
    }

    @objc
    private func onClickCheckboxButton(_ sender: UIButton) {
        if !checkboxButton.isHidden, checkboxButton.isUserInteractionEnabled {
            checkboxButton.isSelected = !checkboxButton.isSelected
            onClickCheckboxClosure?(checkboxButton.isSelected, self.cellData?.startTime)
        }
    }

    private func yyTextLayout(with containerSize: CGSize, attributedText: NSAttributedString) -> YYTextLayout? {
        guard let text = attributedText.mutableCopy() as? NSMutableAttributedString else {
            return nil
        }
        let container = YYTextContainer(size: containerSize, insets: containerInset)
        text.replaceCharacters(in: NSRange(location: text.length, length: 0), with: "\r")
        let layout = YYTextLayout(container: container, text: text)
        return layout
    }

    public static func getAttributedString(_ type: SummaryContentType, contentText: String, passportUserService: PassportUserService?, onClickNameAction: ((_ userId: String) -> Void)?) -> NSAttributedString {
        var usersInfo = MinutesHTMLHelper.getUsersFrom(htmlString: contentText)
        var finalText = MinutesHTMLHelper.getResultsFromHTMLString(contentText)

        var lastNameRangeForBlank: NSRange?
        for userInfo in usersInfo {
            var traverseText: String = finalText
            let nameRange: NSRange
            if let someLastNameRange = lastNameRangeForBlank {
                traverseText = (traverseText as NSString).substring(from: someLastNameRange.location + someLastNameRange.length)
                let tempNameRange = (traverseText as NSString).range(of: userInfo.name)
                nameRange = NSRange(location: someLastNameRange.location + someLastNameRange.length + tempNameRange.location, length: tempNameRange.length)
            } else {
                nameRange = (finalText as NSString).range(of: userInfo.name)
            }
            finalText = (finalText as NSString).replacingOccurrences(of: userInfo.name, with: " \(userInfo.name) ", options: .caseInsensitive, range: nameRange)
            lastNameRangeForBlank = nameRange
        }

        var finalAttributedText = NSMutableAttributedString(string: finalText)
        if usersInfo.isEmpty {
            finalAttributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
                                               NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle],
                                              range: NSRange(location: 0, length: finalText.count))
        } else {
            finalAttributedText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
                                               NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle],
                                              range: NSRange(location: 0, length: finalText.count))
            var lastNameRange: NSRange?
            for userInfo in usersInfo {
                var traverseText: String = finalText
                let nameRange: NSRange
                if let someLastNameRange = lastNameRange {
                    traverseText = (traverseText as NSString).substring(from: someLastNameRange.location + someLastNameRange.length)
                    let tempNameRange = (traverseText as NSString).range(of: userInfo.name)
                    nameRange = NSRange(location: someLastNameRange.location + someLastNameRange.length + tempNameRange.location, length: tempNameRange.length)
                } else {
                    nameRange = (finalText as NSString).range(of: userInfo.name)
                }
                lastNameRange = nameRange

                if passportUserService?.user.userID == userInfo.userId {
                    let border: YYTextBorder = YYTextBorder(fill: UIColor.ud.primaryContentDefault.alwaysLight, cornerRadius: 10)
                    border.fillColor = UIColor.ud.primaryContentDefault.alwaysLight
                    border.insets = UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4)
                    border.lineJoin = .round
                    finalAttributedText.yy_setTextBackgroundBorder(border, range: nameRange)
                    finalAttributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.primaryOnPrimaryFill.alwaysLight], range: nameRange)
                } else {
                    finalAttributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal], range: nameRange)
                }
                finalAttributedText.yy_setTextHighlight(nameRange, color: nil, backgroundColor: nil) { (_, _, tapRange, _) in
                    if NSEqualRanges(nameRange, tapRange) {
                        onClickNameAction?(userInfo.userId)
                    }
                }
            }
        }
        finalAttributedText.yy_minimumLineHeight = type == .checkbox ? 24 : 28
        return finalAttributedText
    }
}
