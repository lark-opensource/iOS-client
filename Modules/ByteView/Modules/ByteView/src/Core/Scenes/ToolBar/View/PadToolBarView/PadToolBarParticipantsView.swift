//
//  PadToolBarParticipantView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import UIKit

class PadToolBarParticipantsView: PadToolBarItemView {
    // badgeBitsCount对应的布局参数
    static let iconMinX: [CGFloat] = [10, 10, 10, 8, 8]
    static let numberLabelMinX: [CGFloat] = [24, 22, 20, 20, 18]
    static let numberLabelHeight: [CGFloat] = [18, 18, 13, 13, 13]
    static let numberLabelFontSize: [CGFloat] = [12, 12, 10, 10, 9]

    lazy var participantsNumLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.lineBreakMode = .byClipping
        return label
    }()

    override var itemWidth: CGFloat {
        guard let item = item as? ToolBarParticipantsItem else { return 40 }
        if item.badgeBitsCount > 3 {
            return 48
        }
        return 40
    }

    override func setupSubviews() {
        super.setupSubviews()
        button.addSubview(participantsNumLabel)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarParticipantsItem else { return }
        badgeView.isHidden = item.badgeType != .dot
        participantsNumLabel.text = "\(item.participantNumber)"
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = item as? ToolBarParticipantsItem, item.badgeBitsCount < 6 else { return }
        let iconMinX = Self.iconMinX[item.badgeBitsCount - 1]
        let numberLabelMinX = Self.numberLabelMinX[item.badgeBitsCount - 1]
        let numberLabelHeight = Self.numberLabelHeight[item.badgeBitsCount - 1]
        let font = UIFont.systemFont(ofSize: Self.numberLabelFontSize[item.badgeBitsCount - 1], weight: .medium)

        iconView.frame = CGRect(origin: CGPoint(x: iconMinX, y: 10), size: Self.iconSize)
        participantsNumLabel.frame = CGRect(x: numberLabelMinX, y: 2, width: itemWidth - numberLabelMinX, height: numberLabelHeight)
        participantsNumLabel.font = font
    }
}
