//
//  FaceToFaceApplicantFlowLayout.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/11.
//

import UIKit
import Foundation
import LarkBizAvatar
import SnapKit

final class FaceToFaceApplicantFlowLayout: UICollectionViewFlowLayout {

    private let edgeInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    private let cellSize = CGSize(width: 48, height: 75)
    private var itemAttributesDic: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var headerAttributesDic: [Int: UICollectionViewLayoutAttributes] = [:]
    private var itemNumberOneRow = 0

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collection = self.collectionView, let datasource = collection.dataSource else { return }

        if collection.frame.size.width < 352 {
            self.itemNumberOneRow = 4
        } else if collection.frame.size.width >= 352 && collection.frame.size.width <= 490 {
            self.itemNumberOneRow = 5
        } else {
            self.itemNumberOneRow = 8
        }

        self.itemAttributesDic = [:]
        self.headerAttributesDic = [:]

        let numberOfSections = collection.numberOfSections
        for index in 0..<numberOfSections {
            let headerAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                                                    with: IndexPath(index: index))
            headerAttributes.frame = CGRect(origin: .zero, size: CGSize(width: collection.frame.size.width, height: 44))
            self.headerAttributesDic[index] = headerAttributes
        }

        let numberOfItems = datasource.collectionView(collection, numberOfItemsInSection: 0)
        for index in 0..<numberOfItems {
            let itemAttributes = self.calculateAttributesInIndex(index)
            self.itemAttributesDic[IndexPath(row: index, section: 0)] = itemAttributes
        }
    }

    override var collectionViewContentSize: CGSize {
        if let collectionView = self.collectionView {
            let numberOfItems = collectionView.numberOfItems(inSection: 0)
            let rowCount: Int
            if numberOfItems % self.itemNumberOneRow == 0 {
                rowCount = numberOfItems / self.itemNumberOneRow
            } else {
                rowCount = numberOfItems / self.itemNumberOneRow + 1
            }
            let contentHeight: CGFloat = CGFloat(44) + self.edgeInset.top + self.edgeInset.bottom + CGFloat(rowCount) * CGFloat(75) + CGFloat(rowCount - 1) * CGFloat(20)
            return CGSize(width: collectionView.frame.size.width, height: contentHeight)
        }
        return CGSize.zero
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.itemAttributesDic[indexPath]
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributes: [UICollectionViewLayoutAttributes] = []
        self.itemAttributesDic.forEach { (_, attribute) in
            if rect.intersects(attribute.frame) {
                attributes.append(attribute)
            }
        }
        self.headerAttributesDic.forEach { (_, attribute) in
            if rect.intersects(attribute.frame) {
                attributes.append(attribute)
            }
        }
        return attributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        /// http://t.wtturl.cn/dPjcpNc/
        /// IndexPath.section.getter 会中断言引起 crash
        /// 具体原因正在排查，暂时前置判空避免 crash
        if indexPath.isEmpty { return nil }
        if elementKind == UICollectionView.elementKindSectionHeader {
            return self.headerAttributesDic[indexPath.section]
        }
        return nil
    }

    private func calculateAttributesInIndex(_ index: Int) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = self.collectionView else { return nil }

        let indexInRow = index % itemNumberOneRow
        let indexInColumn = index / itemNumberOneRow

        let spaceX: CGFloat = (collectionView.frame.size.width - self.edgeInset.left - self.edgeInset.right - CGFloat(itemNumberOneRow) * cellSize.width) / CGFloat(itemNumberOneRow - 1)
        let spaceY: CGFloat = 20

        let centerX = self.edgeInset.left + cellSize.width * (CGFloat(0.5) + CGFloat(indexInRow)) + CGFloat(indexInRow) * spaceX
        let centerY = CGFloat(44) + self.edgeInset.top + cellSize.height * (CGFloat(0.5) + CGFloat(indexInColumn)) + CGFloat(indexInColumn) * spaceY
        let attribute = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
        attribute.size = cellSize
        attribute.center = CGPoint(x: centerX, y: centerY)
        return attribute
    }
}

final class FaceToFaceApplicantViewCell: UICollectionViewCell {
    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 48
    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = UIColor.ud.textTitle
        return nameLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        self.contentView.addSubview(self.nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(avatarView)
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(avatarView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(_ avatarKey: String, userId: String, userName: String) {
        avatarView.setAvatarByIdentifier(userId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.nameLabel.text = userName
    }
}

final class FaceToFaceApplicantPlaceholderViewCell: UICollectionViewCell {
    private let placeholdeSize: CGFloat = 48
    private lazy var placeholderView: UIView = {
        let placeholderView = UIView()
        placeholderView.backgroundColor = UIColor.ud.bgFloatOverlay
        placeholderView.layer.cornerRadius = placeholdeSize / 2
        return placeholderView
    }()
    private lazy var borderView: UIView = {
        let borderView = UIView()
        borderView.backgroundColor = UIColor.ud.bgFloatOverlay
        borderView.layer.cornerRadius = placeholdeSize / 2
        borderView.layer.borderWidth = 1
        borderView.layer.ud.setBorderColor(UIColor.ud.N300)
        return borderView
    }()

    private lazy var placeholderLabel: UILabel = {
        let placeholderLabel = UILabel()
        placeholderLabel.lineBreakMode = .byTruncatingTail
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 1
        placeholderLabel.adjustsFontSizeToFitWidth = true
        placeholderLabel.minimumScaleFactor = 0.5
        placeholderLabel.font = UIFont.systemFont(ofSize: 12)
        placeholderLabel.textColor = UIColor.ud.N900
        return placeholderLabel
    }()
    private lazy var numberLabel: UILabel = {
        let numberLabel = UILabel()
        numberLabel.lineBreakMode = .byTruncatingTail
        numberLabel.textAlignment = .center
        numberLabel.numberOfLines = 1
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.minimumScaleFactor = 0.5
        numberLabel.font = UIFont.systemFont(ofSize: 14)
        numberLabel.textColor = UIColor.ud.textTitle
        return numberLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.borderView)
        borderView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(placeholdeSize)
        }

        self.contentView.addSubview(self.placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(placeholdeSize)
        }

        self.placeholderView.addSubview(self.numberLabel)
        numberLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }

        self.contentView.addSubview(self.placeholderLabel)
        placeholderLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(placeholderView)
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualTo(placeholderView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(number: Int) {
        if number <= 0 {
            self.borderView.isHidden = false
            self.placeholderView.isHidden = true
            self.placeholderLabel.text = ""
            return
        }
        self.borderView.isHidden = true
        self.placeholderView.isHidden = false
        self.numberLabel.text = "\(number)"
        self.placeholderLabel.text = BundleI18n.LarkContact.Lark_NearbyGroup_CountOthers(number)
    }
}

final class FaceToFaceApplicantCollectionHeader: UICollectionReusableView {
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.LarkContact.Lark_NearbyGroup_ContactReminder
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var numberLabel: UILabel = {
        let numberLabel = UILabel()
        numberLabel.font = UIFont.systemFont(ofSize: 17)
        numberLabel.textColor = UIColor.ud.textPlaceholder
        numberLabel.textAlignment = .natural
        return numberLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody

        self.addSubview(titleLabel)
        self.addSubview(numberLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        numberLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    func set(number: Int) {
        self.numberLabel.text = " (\(number))"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
