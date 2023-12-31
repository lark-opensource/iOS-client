//
//  PhoneToolBarParticipantsView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/10.
//

import UIKit

class PhoneToolBarParticipantsView: PhoneToolBarItemView {
    lazy var participantsNumLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        button.addSubview(participantsNumLabel)
    }

    override func bind(item: ToolBarItem) {
        super.bind(item: item)
        guard let item = item as? ToolBarParticipantsItem else { return }

        if case .dot = item.badgeType {
            participantsNumLabel.isHidden = true
            badgeView.isHidden = false
        } else {
            participantsNumLabel.isHidden = false
            badgeView.isHidden = true
        }

        participantsNumLabel.text = "\(item.participantNumber)"
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = item as? ToolBarParticipantsItem else { return }
        participantsNumLabel.frame = CGRect(x: iconView.frame.minX + 17.5, y: -3, width: 8 * CGFloat(item.badgeBitsCount), height: 18)
    }
}
