//
//  MessageLeavingContentView.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/26/23.
//

import Foundation
import LarkUIKit
import RxSwift
import EditTextView
import LarkBizAvatar
import UniverseDesignDialog

typealias AvatarInfoTuple = (id: String, key: String)

class MessageLeavingContentView: UIView {

    private static let avartNumInOneLine = 5
    private var avatarInfos: [AvatarInfoTuple] = []

    private(set) var inputTextView = LarkEditTextView()
    private let tipLabel = UILabel()

    func setupContent(with message: String?, avatars: [AvatarInfoTuple], tip: String? = nil) {
        avatarInfos = avatars

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = Layout.avatarSize
        layout.minimumLineSpacing = Layout.lineSpacing
        layout.minimumInteritemSpacing = (Layout.collectViewWidth - CGFloat(Self.avartNumInOneLine) * Layout.avatarWidth) / CGFloat(Self.avartNumInOneLine) + 1

        let lines = Int(ceil(Double(avatars.count) / Double(Self.avartNumInOneLine)))
        let maxLinesOnePage = 2
        let collectHeight = Layout.containerHeight(with: min(maxLinesOnePage, lines))

        let avatarContainer = UICollectionView(frame: .zero, collectionViewLayout: layout)
        avatarContainer.backgroundColor = .ud.bgFloat
        avatarContainer.dataSource = self
        avatarContainer.register(AvatarCell.self, forCellWithReuseIdentifier: AvatarCell.reuseIdentifier)

        addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints { make in
            make.leading.trailing.top.centerX.equalToSuperview()
            make.height.equalTo(collectHeight)
        }

        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle
        ]
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.font = font
        inputTextView.autocapitalizationType = .none
        inputTextView.placeholder = I18n.Calendar_Setting_Message
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.cornerRadius = 6
        inputTextView.layer.ud.setBorderColor(.ud.lineBorderComponent)
        inputTextView.backgroundColor = .ud.bgFloat
        inputTextView.maxHeight = 55
        inputTextView.textContainerInset = UIEdgeInsets(top: 11, left: 10, bottom: 11, right: 10)

        if let message = message { inputTextView.text = message }

        addSubview(inputTextView)
        inputTextView.snp.makeConstraints { make in
            make.top.equalTo(avatarContainer.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.greaterThanOrEqualTo(36)
            make.height.lessThanOrEqualTo(55)
        }

        addSubview(tipLabel)
        tipLabel.text = tip
        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.textColor = .ud.textCaption
        tipLabel.numberOfLines = 0
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(inputTextView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
        tipLabel.isHidden = tip.isEmpty
    }
}

extension MessageLeavingContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        avatarInfos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AvatarCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? AvatarCell, let avatarInfo = avatarInfos[safeIndex: indexPath.row] {
            cell.setAvatar(identifier: avatarInfo.id, key: avatarInfo.key)
        }
        return cell
    }
}

extension MessageLeavingContentView {
    private class AvatarCell: UICollectionViewCell {
        static var reuseIdentifier: String { return String(describing: AvatarCell.self) }

        fileprivate var avatar = BizAvatar()
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(avatar)
            avatar.snp.makeConstraints { $0.edges.equalToSuperview() }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            avatar.image = nil
        }

        func setAvatar(identifier: String, key: String) {
            avatar.image = nil
            avatar.setAvatarByIdentifier(identifier, avatarKey: key, avatarViewParams: .defaultThumb)
        }
    }
}

extension MessageLeavingContentView {
    private enum Layout {
        static let avatarWidth: CGFloat = 40
        static let lineSpacing: CGFloat = 10
        static let collectViewWidth: CGFloat = UDDialog.Layout.dialogWidth - 40
        static let avatarSize: CGSize = CGSize(width: avatarWidth, height: avatarWidth)

        static func containerHeight(with lines: Int) -> CGFloat {
            avatarWidth * Double(lines) + lineSpacing * Double(lines - 1)
        }
    }
}
