//
//  SubtitleHistoryDocCell.swift
//  ByteView
//
//  Created by kiri on 2020/6/11.
//

import UIKit
import RichLabel
import UniverseDesignIcon

class SubtitleHistoryDocCell: SubtitleHistoryCell {

    var gotoDocs: ((String) -> Void)?

    var linkTextAttributes: [NSAttributedString.Key: Any] {
        var attributes = normalTextAttributes
        attributes[.foregroundColor] = UIColor.ud.primaryContentDefault
        return attributes
    }

    override func setup() {
        super.setup()
    }

    override var contentText: NSMutableAttributedString? {
        guard let vm = viewModel,
              let title = vm.behaviorDocLinkTitle else {
            return nil
        }
        let behaviorText = viewModel?.behaviorDescText ?? ""
        let docString = NSMutableAttributedString(string: "(", attributes: normalTextAttributes)
        let frontPartString = NSMutableAttributedString(string: behaviorText, attributes: normalTextAttributes)
        docString.append(frontPartString)
        if let icon = vm.icon {
            let image = UDIcon.getIconByKey(icon, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
            if #available(iOS 13, *) {
                let iconText = NSTextAttachment(image: image)
                docString.append(NSAttributedString(attachment: iconText))
            } else {
                let iconText = NSTextAttachment()
                iconText.image = image
                docString.append(NSAttributedString(attachment: iconText))
            }
        }
        let titleString = NSMutableAttributedString(string: title, attributes: linkTextAttributes)
        docString.append(titleString)
        let afterPartString = NSMutableAttributedString(string: ")", attributes: normalTextAttributes)
        docString.append(afterPartString)
        return docString
    }

    override var matchedRanges: [NSRange]? {
        guard let vm = viewModel else { return nil }
        var ranges: [NSRange] = []
        for range in vm.ranges {
            let location = calculateLocation(range.location)
            ranges.append(NSRange(location: location, length: range.length))
        }
        return ranges
    }

    override var selectedRange: NSRange? {
        get {
            super.selectedRange
        }
        set {
            guard let range = newValue else {
                super.selectedRange = nil
                return
            }
            let location = calculateLocation(range.location)
            super.selectedRange = NSRange(location: location, length: range.length)
        }
    }

    override func updateViewModel(vm: SubtitleViewData) -> CGFloat {
        let cellHeight = super.updateViewModel(vm: vm)
        guard let behaviorTextLength = viewModel?.behaviorDescText?.count,
              let subtitleContentLength = contentLabel.attributedText?.length else {
            return cellHeight
        }
        let location = behaviorTextLength + 1
        let length = subtitleContentLength - behaviorTextLength - 2

        guard location >= 0, length > 0 else {
            return cellHeight
        }

        var link = LKTextLink(range: NSRange(location: location, length: length),
                              type: .link,
                              attributes: [.foregroundColor: UIColor.ud.primaryContentDefault],
                              activeAttributes: [:])
        link.linkTapBlock = { [weak self] (_, _) in
            if UIMenuController.shared.isMenuVisible {
                self?.becomeFirstResponder()
                return
            }
            if let url = self?.viewModel?.behaviorDocLinkUrl {
                self?.gotoDocs?(url)
            }
        }
        contentLabel.addLKTextLink(link: link)
        return cellHeight
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.removeLKTextLink()
    }

    override func copy(_ sender: Any?) {
        let copyMessage = viewModel?.behaviorDocLinkUrl ?? ""
        self.service?.security.copy(copyMessage, token: .subtitlePageCopyDocUrl)
        SubtitleTracksV2.trackCopySubtitle()
        Toast.show(I18n.View_G_CopiedSuccessfully)
    }

    private func calculateLocation(_ location: Int) -> Int {
        guard let behaviorTextCount = viewModel?.behaviorDescText?.count else {
            return location + 4
        }
        return behaviorTextCount + location + 4
    }
}
