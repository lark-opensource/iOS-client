//
//  ChatWidgetCardTableViewCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/14.
//

import UIKit
import Foundation

final class ChatWidgetCardTableViewCell: UITableViewCell {

    var cellId: Int64 = -1
    var longPressHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(ChatWidgetsContainerView.UIConfig.cardPaddingTop)
            make.left.bottom.right.equalToSuperview()
        }
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true

        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
        self.contentView.addGestureRecognizer(longPressGes)
    }

    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        return containerView
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func longPressed(gesture: UILongPressGestureRecognizer) {
        self.longPressHandler?()
    }
}
