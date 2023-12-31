//
//  NavigationBarParticipantsView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/13.
//

import UIKit

class NavigationBarParticipantsView: NavigationBarItemView {
    lazy var participantsNumLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()

    override func setupSubviews() {
        super.setupSubviews()
        addSubview(participantsNumLabel)
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

        participantsNumLabel.attributedText = NSAttributedString(string: "\(item.participantNumber)", config: .assist, textColor: UIColor.ud.textCaption)
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let item = item as? ToolBarParticipantsItem else { return }
        let newFrame = CGRect(x: button.frame.minX + 20, y: button.frame.minY - 2, width: 8 * CGFloat(item.badgeBitsCount), height: 18)
        if participantsNumLabel.frame != newFrame {
            participantsNumLabel.frame = newFrame
        }
    }
}
