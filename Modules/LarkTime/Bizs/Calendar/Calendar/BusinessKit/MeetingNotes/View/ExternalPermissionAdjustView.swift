//
//  ExternalPermissionAdjustView.swift
//  Calendar
//
//  Created by huoyunjie on 2023/10/7.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon

class PermissionPromptView: UIView {
    typealias Tag = MeetingNotesTag

    private lazy var icon: UIImage = UDIcon.warningColorful

    var warningIcon: UIView {
        trailClickableView.iconImageView
    }

    private lazy var trailClickableView = TrailClickableView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(trailClickableView)
        trailClickableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTrailClickableViewContent(prompt: String, trailingText: String) {
        let promptConfig = TrailClickableView.UIConfig(
            text: prompt,
            style: .init()
                .padding(right: .point(8), left: .point(0))
                .lineHeight(.point(20))
                .color(UDColor.textTitle)
                .fontSize(.point(14))
        )

        let trailView: UILabel = {
            let label = UILabel()
            label.textColor = UDColor.primaryContentDefault
            label.text = trailingText
            label.font = UIFont.systemFont(ofSize: 14)
            label.sizeToFit()
            return label
        }()

        let trailViewSize = CGSize(
            width: trailView.bounds.width,
            height: 22
        )

        trailClickableView.updateContent(
            icon: icon,
            promptConfig: promptConfig,
            trailView: trailView,
            trailViewSize: trailViewSize
        )
    }

    var clickAction: (() -> Void)? {
        didSet {
            trailClickableView.clickAction = clickAction
        }
    }
}
