//
//  ChatPinListTipCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/11/7.
//

import Foundation
import UniverseDesignColor

class ChatPinListTipCell: UICollectionViewCell {

    static var reuseIdentifier: String { return String(describing: ChatPinListTipCell.self) }
    static var height: CGFloat = 34

    private lazy var leftLine: UIView = {
        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.ud.lineBorderCard
        return leftLine
    }()

    private lazy var rightLine: UIView = {
        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.ud.lineBorderCard
        return rightLine
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(leftLine)
        self.contentView.addSubview(rightLine)
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        leftLine.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
            make.right.equalTo(titleLabel.snp.left).offset(-16)
        }
        rightLine.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(1)
            make.left.equalTo(titleLabel.snp.right).offset(16)
        }
    }

    func update(_ title: String) {
        self.titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
