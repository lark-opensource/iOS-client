//
//  LarkNCExtensionEmotionKeyboardView.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/20.
//

import Foundation
import UIKit

final class LarkNCExtensionEmotionKeyboardView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    fileprivate var itemWidth: CGFloat = 0
    fileprivate var layout: LarkNCExtensionEmotionLeftAlignedFlowLayout = LarkNCExtensionEmotionLeftAlignedFlowLayout()
    fileprivate lazy var emotionCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)

    private lazy var keyboardIcon: UIButton = UIButton()
    private lazy var titleView: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = BundleI18n.LarkNotificationContentExtensionSDK.Lark_Core_QuickReply_EmojiReaction_Title
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()

    var pressCell: UICollectionViewCell?
    var pressCellIndexPatch: IndexPath?

    var didSelectItemCallback: ((String) -> Void)?
    var switchKeyboardCallback: (() -> Void)?

    var bottomBarHeight: CGFloat = 0 {
        didSet {
            if bottomBarHeight != oldValue {
                self.emotionCollection.reloadData()
            }
        }
    }

    var emojiGroups: [LarkNCExtensionEmotionGroup] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.emojiGroups = LarkNCExtensionEmotionHelper.getAllLocalReactions()
        self.updateCollectionView()
        self.backgroundColor = UIColor(named: "emoji_keyboardbg_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width != self.itemWidth {
            self.itemWidth = self.bounds.width
            self.layout.invalidateLayout()
            self.emotionCollection.reloadData()
        }
    }

    func updateCollectionView() {
        layout.scrollDirection = .vertical
        emotionCollection.backgroundColor = UIColor.clear
        emotionCollection.showsVerticalScrollIndicator = false
        emotionCollection.showsHorizontalScrollIndicator = false
        emotionCollection.dataSource = self
        emotionCollection.delegate = self
        emotionCollection.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(emotionCollection)
        NSLayoutConstraint.activate([
            emotionCollection.leadingAnchor.constraint(equalTo: leadingAnchor),
            emotionCollection.trailingAnchor.constraint(equalTo: trailingAnchor),
            emotionCollection.topAnchor.constraint(equalTo: topAnchor, constant: 62),
            emotionCollection.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -34),
        ])

        self.setupCollectionView()

        let wrapperView = UIView()
        self.addSubview(wrapperView)
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.backgroundColor = UIColor(named: "emoji_titlebg_color", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        NSLayoutConstraint.activate([
            wrapperView.leadingAnchor.constraint(equalTo: leadingAnchor),
            wrapperView.topAnchor.constraint(equalTo: topAnchor),
            wrapperView.bottomAnchor.constraint(equalTo: emotionCollection.topAnchor),
            wrapperView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        keyboardIcon.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "emotion", in: BundleConfig.LarkNotificationContentExtensionSDKBundle, compatibleWith: nil)
        keyboardIcon.setImage(image, for: .normal)
        keyboardIcon.setImage(image, for: .highlighted)
        keyboardIcon.addTarget(self, action: #selector(switchKeyboardView), for: .touchUpInside)
        wrapperView.addSubview(keyboardIcon)
        NSLayoutConstraint.activate([
            keyboardIcon.leadingAnchor.constraint(equalTo: wrapperView.leadingAnchor, constant: 8),
            keyboardIcon.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 15),
            keyboardIcon.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -15),
            keyboardIcon.widthAnchor.constraint(equalToConstant: 32),
            keyboardIcon.heightAnchor.constraint(equalToConstant: 32)
        ])

        titleView.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.addSubview(titleView)
        NSLayoutConstraint.activate([
            titleView.leadingAnchor.constraint(equalTo: keyboardIcon.trailingAnchor, constant: 8),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: wrapperView.trailingAnchor, constant: -8),
            titleView.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor),
            titleView.topAnchor.constraint(equalTo: wrapperView.topAnchor, constant: 19),
            titleView.bottomAnchor.constraint(equalTo: wrapperView.bottomAnchor, constant: -19),
        ])
    }

    @objc
    private func switchKeyboardView() {
        switchKeyboardCallback?()
    }

    private func setupCollectionView() {
        emotionCollection.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        var name = String(describing: LarkNCExtensionEmotionCell.self)
        emotionCollection.register(LarkNCExtensionEmotionCell.self, forCellWithReuseIdentifier: name)
        name = String(describing: LarkNCExtensionEmotionHeaderView.self)
        emotionCollection.register(LarkNCExtensionEmotionHeaderView.self,
                                   forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                   withReuseIdentifier: name)
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.emojiGroups.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard indexPath.section < self.emojiGroups.count else {
            return UICollectionReusableView()
        }

        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: LarkNCExtensionEmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: name,
                                                                       for: indexPath)
            if let emotionHeaderView = cell as? LarkNCExtensionEmotionHeaderView {
                let xOffset: CGFloat = 14
                emotionHeaderView.setData(title: emojiGroups[indexPath.section].title, xOffset: xOffset)
            }
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < self.emojiGroups.count else {
            return 0
        }
        return self.emojiGroups[section].entities.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.section < self.emojiGroups.count, indexPath.row < self.emojiGroups[indexPath.section].entities.count else {
            return LarkNCExtensionEmotionCell()
        }

        let row = indexPath.row

        let name = String(describing: LarkNCExtensionEmotionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? LarkNCExtensionEmotionCell {
            collectionCell.setCellContnet(self.emojiGroups[indexPath.section].entities[row].image)
        }
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard indexPath.section < self.emojiGroups.count, indexPath.row < self.emojiGroups[indexPath.section].entities.count else {
            return self.emotionItemDefaultSize()
        }
        let emojiEntity = self.emojiGroups[indexPath.section].entities[indexPath.row]
        // 高度固定等于默认高度
        let displayHeight = self.emotionItemDefaultSize().height
        // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
        var displayWidth = self.emotionItemDefaultSize().width
        // 容器里面实际图片的大小
        let iconHeight: CGFloat = 32.0
        // 如果图片大小和服务端给的不一致，以实际图片大小为准
        let image = emojiEntity.image
        let size = image.size

        // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
        // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
        if size.height != 0 {
            // 如果宽度大于45，说明是企业自定义表情，容器宽度有自己的计算规则
            if size.width / UIScreen.main.scale > 45 {
                let iconWidth = iconHeight * size.width / size.height
                // 企业自定义表情的话容器间距固定
                displayWidth = iconWidth + (2 * 6)
            } else {
                // 默认表情（32高度下，宽度限制在32~44.6之间）容器的大小是等宽等高的
                displayWidth = displayHeight
            }
            return CGSize(width: displayWidth, height: displayHeight)
        }
        return self.emotionItemDefaultSize()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if section == self.numberOfSections(in: collectionView) - 1 {
            // 最后一行下边距要宽一点
            var edgeInsets = self.emotionInsets()
            edgeInsets.bottom += bottomBarHeight
            return edgeInsets
        }
        return self.emotionInsets()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 8
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        // 手机端最小间距
        var minSpace: CGFloat = 4.5
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad端最小间距
            minSpace = 16.0
        }

        let size = self.emotionItemDefaultSize()
        // 计算出一行最多能放多少个元素
        let panelWidth = collectionView.bounds.width - self.emotionInsets().left - self.emotionInsets().right
        let count = Int((panelWidth + minSpace) / (size.width + minSpace))
        // 元素个数一定要大于等于2
        guard count > 1 else {
            return minSpace
        }
        // 根据一行实际显示的元素计算出真实的间距
        let space = CGFloat((panelWidth - size.width * CGFloat(count)) / CGFloat(count - 1))
        return space
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return CGSize(width: 0.1, height: 26)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section < self.emojiGroups.count, indexPath.row < self.emojiGroups[indexPath.section].entities.count else {
            return
        }
        let key = self.emojiGroups[indexPath.section].entities[indexPath.row].key
        didSelectItemCallback?(key)
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? LarkNCExtensionEmotionHighlightCollectionCell else {
            return
        }
        cell.showHighlightedBackgroundView()
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? LarkNCExtensionEmotionHighlightCollectionCell else {
            return
        }
        cell.hideHighlightedBackgroundView()
    }

    private func emotionItemDefaultSize() -> CGSize {
        return CGSize(width: 48, height: 48)
    }

    // 表情键盘的上下左右边距
    private func emotionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }
}
