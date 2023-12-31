//
//  RecommendedAvatarView.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/10/13.
//

import Foundation
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignColor
import ByteWebImage
import LKCommonsLogging

struct RecommendLayoutInfo {
    static let avatarSize: CGSize = CGSize(width: 64, height: 64)
    static let checkedViewSize: CGSize = CGSize(width: 16, height: 16)
    static let checkedViewBorderSize: CGFloat = 2.0
    static let itemLineSpace: CGFloat = 16.0
    static let itemRowCount: Int = 4
}

final class RecommendedCollectionViewCell: UICollectionViewCell {
    private static let logger = Logger.log(RecommendedCollectionViewCell.self, category: "RecommendedCollectionViewCell")

    static let reuseKey = "RecommendedCollectionViewCell"

    private lazy var avatarView: GenericAvatarView = GenericAvatarView(avatarSize: RecommendLayoutInfo.avatarSize)
    let checkedWrapperView: UIView = UIView()
    let checkedView = UIImageView(image: UDIcon.getIconByKey(.checkOutlined, size: RecommendLayoutInfo.checkedViewSize).ud.withTintColor(UIColor.ud.staticWhite))

    var item: VariousAvatarType? {
        didSet {
            updateUI()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateCheckUI()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(avatarView)
        contentView.addSubview(checkedWrapperView)
        checkedWrapperView.addSubview(checkedView)
        checkedWrapperView.layer.masksToBounds = true
        checkedWrapperView.layer.borderWidth = RecommendLayoutInfo.checkedViewBorderSize
        checkedWrapperView.layer.ud.setBorderColor(UIColor.ud.bgBody)

        avatarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        checkedWrapperView.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom).offset(RecommendLayoutInfo.checkedViewBorderSize)
            make.trailing.equalTo(avatarView.snp.trailing).offset(RecommendLayoutInfo.checkedViewBorderSize)
        }

        checkedView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: RecommendLayoutInfo.checkedViewBorderSize))
        }
        checkedWrapperView.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        checkedWrapperView.layer.cornerRadius = RecommendLayoutInfo.checkedViewBorderSize + RecommendLayoutInfo.checkedViewSize.width / 2.0
        checkedView.backgroundColor = UIColor.ud.functionInfoContentDefault
    }

    func updateUI() {
        guard let item = self.item else {
            return
        }
        avatarView.setAvatar(item)
    }

    func updateCheckUI() {
        self.checkedWrapperView.isHidden = !self.isSelected
    }
}

protocol RecommendViewDelegate: AnyObject {
    func didSelectItem(item: VariousAvatarType)
}

/// 推荐头像
final class RecommendedAvatarView: UIView, UICollectionViewDelegate,
                       UICollectionViewDataSource,
                       UICollectionViewDelegateFlowLayout {

    private(set) var data: [VariousAvatarType] = []
    private(set) var currentSelectIndex: IndexPath?
    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    weak var delegate: RecommendViewDelegate?

    var itemSize: CGSize {
        return RecommendLayoutInfo.avatarSize
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(collectionView)
        backgroundColor = UIColor.ud.bgBody
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.register(RecommendedCollectionViewCell.self,
                                forCellWithReuseIdentifier: RecommendedCollectionViewCell.reuseKey)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setData(items: [VariousAvatarType]) {
        self.data = items
        self.collectionView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 展示两排推荐头像
        collectionView.snp.updateConstraints { make in
            make.height.equalTo(itemSize.height * 2 + RecommendLayoutInfo.itemLineSpace)
        }
    }

    func whetherInSelectedStaus() -> Bool {
        if let selectedItems = collectionView.indexPathsForSelectedItems, !selectedItems.isEmpty {
            // collectionView 有被选中的单元格
            return true
        } else {
            // collectionView 没有被选中的单元格
            return false
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.data[indexPath.row]
        let cell: UICollectionViewCell? = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendedCollectionViewCell.reuseKey, for: indexPath)
        (cell as? RecommendedCollectionViewCell)?.item = item
        return cell ?? UICollectionViewCell()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }
    /// -------
    /// minimumLineSpacingForSectionAt
    /// ------
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return RecommendLayoutInfo.itemLineSpace
    }
    /// |minimumInteritemSpacingForSectionAt|
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return floor((self.frame.width - itemSize.width * CGFloat(RecommendLayoutInfo.itemRowCount)) / CGFloat(RecommendLayoutInfo.itemRowCount - 1))
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < self.data.count else {
            return
        }
        currentSelectIndex = indexPath
        self.delegate?.didSelectItem(item: self.data[indexPath.row])

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.itemSize
    }

    // 清除所有选中态
    func clearSelectedState() {
        guard let currentSelectIndex = currentSelectIndex else { return }
        collectionView.deselectItem(at: currentSelectIndex, animated: false)
    }
}
