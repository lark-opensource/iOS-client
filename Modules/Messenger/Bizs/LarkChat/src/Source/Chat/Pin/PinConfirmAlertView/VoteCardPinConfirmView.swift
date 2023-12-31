//
//  NewVoteCardPinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageCore

final class VotePinConfirmView: PinConfirmContainerView {
    let icon: UIImageView
    let title: UILabel
    let contentView: UIStackView

    override init(frame: CGRect) {
        self.icon = UIImageView(frame: .zero)
        self.title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor.ud.N900
        title.numberOfLines = 1
        self.contentView = UIStackView(frame: .zero)
        contentView.axis = .vertical
        contentView.spacing = 4
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(title)
        self.addSubview(contentView)
        icon.snp.makeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.width.height.equalTo(24)
        }
        title.snp.makeConstraints { (make) in
            make.top.equalTo(icon)
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(9)
            make.left.equalTo(title)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)
        guard let cardContentVM = contentVM as? VotePinConfirmViewModel else {
            return
        }
        self.title.text = cardContentVM.title
        self.icon.image = cardContentVM.icon
        let maxLine = 4
        for (index, item) in cardContentVM.rawItems.enumerated() {
            let itemLabel = UILabel(frame: .zero)
            itemLabel.text = index == (maxLine - 1) ? "..." : "\(item.optionCase). \(item.content)"
            itemLabel.font = UIFont.systemFont(ofSize: 16)
            itemLabel.numberOfLines = 1
            itemLabel.textColor = UIColor.ud.N900
            self.contentView.addArrangedSubview(itemLabel)
            if index == (maxLine - 1) {
                break
            }
        }
    }
}

final class VotePinConfirmViewModel: PinAlertViewModel {
    var content: CardContent!

    var title: String = ""

    var icon: UIImage {
        return Resources.pinVoteTip
    }

    // raw data
    var rawItems: [SelectProperty] = []

    init?(cardMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        super.init(message: cardMessage, getSenderName: getSenderName)

        guard let content = cardMessage.content as? CardContent, content.type == .vote else {
            return nil
        }
        self.content = content
        self.pharseRichText()
    }

    public func pharseRichText() {
        self.rawItems = []
        let elements = content.richText.elements
        let parentIDs = content.richText.elementIds
        guard parentIDs.count == 3 else { return }
        // header
        if let element = elements[parentIDs[0]] {
            guard element.childIds.count == 1,
                let text = elements[element.childIds[0]],
                text.tag == .text else { return }
            self.title = text.property.text.content
        }
        // content
        if let element = elements[parentIDs[1]] {
            guard element.childIds.count == 1,
                let select = elements[element.childIds[0]],
                select.tag == .select else { return }
            for childID in select.childIds where !childID.isEmpty {
                guard let progress = elements[childID], progress.property.hasProgress else { break }
                self.rawItems.append(progress.property.progress)
            }
        }
    }
}
