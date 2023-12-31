//
//  LinkCardView.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2021/1/4.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import UniverseDesignColor

private enum Layout {
    static let topMargin: CGFloat = 6
    static let sideMargin: CGFloat = 18
    static let innerMargin: CGFloat = 16
}

final class LinkCardView: BaseCardView {
    init(
        circleAvatar: Bool = true,
        retryHandler: @escaping () -> Void
    ) {
        super.init(
            needBaseSeparateLine: false,
            circleAvatar: circleAvatar,
            retryHandler: retryHandler
        )
        addPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var contentView: UIView {
        return linkLabel
    }

    override func bind(with statusMaterial: StatusViewMaterial) {
        super.bind(with: statusMaterial)
        if case .success(let m) = statusMaterial {
            linkLabel.setText(text: m.link, lineSpacing: 4)
            contentView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(Layout.topMargin)
                make.leading.trailing.equalToSuperview().inset(Layout.sideMargin)
            }
            contentView.superview?.layoutIfNeeded()
        }
    }

    private lazy var linkLabel: DisplayLabel = {
        let label = DisplayLabel(
            frame: .zero,
            insets: UIEdgeInsets(top: Layout.innerMargin,
                                 left: Layout.innerMargin,
                                 bottom: Layout.innerMargin,
                                 right: Layout.innerMargin)
        )
        label.backgroundColor = UIColor.ud.N200
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .left
        label.textColor = UIColor.ud.N900
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        return label
    }()
    
    func centreContentView() {
        centreSuccessContainer()
        contentView.snp.remakeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview().inset(Layout.sideMargin)
        }
    }
}
