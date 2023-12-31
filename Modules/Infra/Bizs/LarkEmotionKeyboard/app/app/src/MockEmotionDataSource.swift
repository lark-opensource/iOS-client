//
//  MockEmotionDataSource.swift
//  LarkEmotionKeyboardDev
//
//  Created by 王元洵 on 2021/2/26.
//

import UIKit
import Foundation
import SnapKit
import LarkEmotion
import LarkContainer
import LarkEmotionKeyboard

/*
public class MockEmotionDataSource: EmotionItemDataSource {
    //if user longpress single cell and release at last, the callstask as below:
    //    ->didHighlightItemAt
    //    ->didUnHighlightItemAt
    //    ->longPressedAt
    //    ->longPressedEnd;

    //if user longpress cell1 than move to cell2 ,and release at last,the callstask as below:
    //    ->didHighlightItemAt(cell1)
    //    ->didUnHighlightItemAt(cell1)
    //    ->longPressedAt(cell1)
    //    ->longPressedEnd(cell1)
    //    ->longPressedAt(cell2)
    //    ->longPressedEnd(cell2);

    //avoid cell background flicker by using property "pressCell"
    var longPressingCell: EmotionHighlightCollectionCell?
    public func longPressedAt(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? EmotionHighlightCollectionCell else {
            return
        }
        self.longPressingCell = cell
        cell.showHighlightedBackgroundView()
    }

    public func longPressedEnd(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? EmotionHighlightCollectionCell else {
            return
        }
        self.longPressingCell = nil
        cell.hideHighlightedBackgroundView()
    }

    public func didHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {
        guard let cell = cell as? EmotionHighlightCollectionCell else {
            return
        }
        cell.showHighlightedBackgroundView()
    }

    public func didUnHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {
        guard let cell = cell as? EmotionHighlightCollectionCell else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //when longpressing, do not hide highlighted background view
            guard self.longPressingCell == nil else {
                return
            }
            cell.hideHighlightedBackgroundView()
        }
    }

    private var deleteContainerHeight = 66

    public var identifier: String {
        return "emoji"
    }

    public func emotionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }

    public func emotionLineSpacing() -> CGFloat {
        return 16
    }

    public func setupSourceIconImage(_ callback: @escaping (UIImage) -> Void) {
        callback(LarkEmotionKeyboard.Resources.emoji)
    }

    public weak var collection: UICollectionView?

    open weak var delegate: EmojiEmotionItemDelegate?

    /// 是否使用新Reaction & Emoji顺序
    private let clientChatEmojiOrder = true
    /// 是否使用新Emoji面板：新增最近使用Emoji
    private let clientChatInputEmojiUpdate = true
    /// 是否显示2021春节Reaction
    private let emojiSpringfestival = true
    /// 最近常用的表情
    private var recentEmojis: [(String, String)] = []
    /// 支持发送的表情
    private var emojis: [(String, String)] = []
    /// 是否是iPad
    private let displayInPad: Bool
    /// 展示高度
    private let displayHeight: CGFloat
    /// reaction注入服务
    private let dependency: EmojiDataSourceDependency?

    public var actionView: UIView = UIView()

    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(Resources.keyboardDeleteIcon, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return deleteButton
    }()

    lazy var deleteContainer: UIImageView = {
        let deleteContainer = UIImageView(image: Resources.keyboardDeleteButtonContainer)
        deleteContainer.isUserInteractionEnabled = true
        return deleteContainer
    }()

    lazy var sendButton: UIButton = {
        let sendButton = UIButton()
        sendButton.backgroundColor = UIColor.ud.colorfulBlue
        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return sendButton
    }()

    public init(dependency: EmojiDataSourceDependency? = EmojiImageService.default,
                displayInPad: Bool,
                displayHeight: CGFloat) {
        assert(dependency != nil, "EmojiDataSourceDependency不能为空！若采用默认实现，请引入ReactionDependency这个subspec")
        self.dependency = dependency
        self.displayInPad = displayInPad
        self.displayHeight = displayHeight
        self.setUpRecentEmojis()
        self.setUpEmojis()
    }

    private func setUpRecentEmojis() {
        guard self.clientChatInputEmojiUpdate,
              var reactionKeys = self.dependency?.getRecentReactions() else { return }

        // 得到最近使用的ReactionKeys
        if reactionKeys.isEmpty { reactionKeys = EmotionHelper.recentReactions(newOrder: self.clientChatEmojiOrder) }
        // 如果不显示2021春节Reaction，则需要去掉
        if !self.emojiSpringfestival {
            reactionKeys = reactionKeys.filter({ !EmotionHelper.newYearReactionKeys.contains($0) })
            for key in EmotionHelper.recentReactions(newOrder: self.clientChatEmojiOrder) {
                if reactionKeys.contains(key) { continue }
                reactionKeys.append(key)
            }
        }

        // 转换为本地存在的Emoji信息
        var recentEmojis: [(String, String)] = []
        let numberOfOneRow = self.numberOfOneRow()
        reactionKeys.forEach { (key) in
            if let emojiInfo = EmotionHelper.reactionsDic[key] {
                recentEmojis.append(emojiInfo)
            }
        }
        // 只取前numberOfOneRow个，只展示一行
        if recentEmojis.count > numberOfOneRow {
            recentEmojis = Array(recentEmojis.prefix(numberOfOneRow))
        }

        // 是否需要刷新表格视图
        var collectionNeedReloadSection: Bool = false
        if recentEmojis.count != self.recentEmojis.count {
            collectionNeedReloadSection = true
        } else {
            // 判断新旧keys顺序是否相同
            collectionNeedReloadSection = !recentEmojis.map({ $0.0 }).elementsEqual(self.recentEmojis.map({ $0.0 }))
        }

        guard collectionNeedReloadSection else { return }

        self.recentEmojis = recentEmojis
        self.collection?.reloadSections([0])
    }

    private func setUpEmojis() {
        // 是否使用新Reaction & Emoji顺序
        if self.clientChatEmojiOrder {
            guard var reactionKeys = self.dependency?.getUsedReactions() else { return }
            // 服务端下发ReactionKey，这些Key决定顺序，我们找到这些Key本地对应的EmojiKey，得到Emoji顺序
            if reactionKeys.isEmpty {
                reactionKeys = EmotionHelper.usedReactions(
                    newOrder: self.clientChatEmojiOrder,
                    containNewYear: self.emojiSpringfestival
                )
            }
            // 通过ReactionKeys找到本地已存在的EmojiKey
            var customizeEmojiKeys: [EmotionKey] = []
            reactionKeys.forEach { (key) in
                if let emojiInfo = EmotionHelper.reactionsDic[key] {
                    customizeEmojiKeys.append(emojiInfo.key)
                }
            }
            self.emojis = EmotionHelper.sendEmotions(sort: .customize(customizeEmojiKeys),
                                                     containNewYear: self.emojiSpringfestival)
        } else {
            self.emojis = EmotionHelper.sendEmotions(sort: .default, containNewYear: self.emojiSpringfestival)
        }
    }

    public func numberOfOneRow() -> Int {
        if !self.displayInPad { return 7 }
        let minNumber: Int = 7
        let maxNumber: Int = 18
        let minSpace: CGFloat = 12
        let itemSize = emotionItemSize()
        guard let collectionView = self.collection,
            collectionView.bounds.width > 0 else {
                return minNumber
        }
        let width = collectionView.bounds.width
        var number: Int = Int((width - minSpace) / (itemSize.width + minSpace))
        number = min(max(minNumber, number), maxNumber)
        return number
    }

    public func emotionItemSize() -> CGSize {
        return CGSize(width: 48, height: 48)
    }

    public func headerReferenceSize() -> CGSize {
        if self.clientChatInputEmojiUpdate {
            // 宽度只需要设置一个0.1，系统会默认拉长为所在视图的宽度
            return CGSize(width: 0.1, height: 26)
        }
        return .zero
    }

    public func needAddEmptyView() -> Bool {
        if self.clientChatInputEmojiUpdate {
            return self.emojis.isEmpty && self.recentEmojis.isEmpty
        }
        return self.emojis.isEmpty
    }

    public func didSelect() {
        self.setUpRecentEmojis()
    }

    public func numberOfSections() -> Int {
        return self.clientChatInputEmojiUpdate ? 2 : 1
    }

    public func numberOfEmotions(section: Int) -> Int {
        if self.clientChatInputEmojiUpdate {
            return section == 1 ? self.emojis.count : self.recentEmojis.count
        }
        return self.emojis.count
    }

    public func didSelectEmotion(indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row < self.emojis.count {
                self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: self.emojis[indexPath.row].0)
            }
            return
        }

        if self.clientChatInputEmojiUpdate {
            if indexPath.row < self.recentEmojis.count {
                self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: self.recentEmojis[indexPath.row].0)
            }
        } else {
            if indexPath.row < self.emojis.count {
                self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: self.emojis[indexPath.row].0)
            }
        }
    }

    public func collectionView(collectionView: UICollectionView,
                               insetForSectionAt section: Int,
                               bottomBarHeight: CGFloat) -> UIEdgeInsets {
        if self.clientChatInputEmojiUpdate {
            if section == 1 {
                var edgeInsets = self.emotionInsets()
                edgeInsets.bottom += bottomBarHeight
                return edgeInsets
            }
            return self.emotionInsets()
        }
        var edgeInsets = self.emotionInsets()
        edgeInsets.bottom += bottomBarHeight
        return edgeInsets
    }

    public func collectionView(collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: EmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: name,
                                                                       for: indexPath)
            if let emotionHeaderView = cell as? EmotionHeaderView {
                let str = indexPath.section == 1
                    ? "全部"
                    : "最近使用"
                emotionHeaderView.setTitle(title: str)
            }
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionCell(collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: EmotionCell.self)
        let cell = collection.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? EmotionCell {
            let imageName = self.emoticonForIndexPath(indexPath)
            if !imageName.isEmpty {
                collectionCell.setCellContnet(EmotionResources.emotion(named: imageName))
            } else {
                collectionCell.setCellContnet(nil)
            }
        }
        return cell
    }

    public func setupCollectionView(containerView: EmotionKeyboardItemView, collection: UICollectionView) {
        self.collection = collection
        // 最后一行内容距离视图的底部由三个距离决定：collectionView(...insetForSectionAt...).bottom  +
        // collection.contentInset.bottom + collection.adjustContentInset.bottom
        // adjustContentInset.bottom：默认为安全距离底部
        // contentInset.bottom：默认为0，用户可以主动设置
        // collectionView(...insetForSectionAt...).bottom：默认为0，用户在代理处复写
        if self.isNewKeyboardStyleEnable() {
            collection.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        } else {
            collection.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 56, right: 0)
        }
        var name = String(describing: EmotionCell.self)
        collection.register(EmotionCell.self, forCellWithReuseIdentifier: name)
        name = String(describing: EmotionHeaderView.self)
        collection.register(EmotionHeaderView.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: name)

        if !self.isNewKeyboardStyleEnable() {
            containerView.addSubview(deleteContainer)
            deleteContainer.addSubview(deleteButton)
            deleteContainer.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                let height = self.deleteContainerHeight
                make.top.equalTo((self.displayHeight >= 812 ? 262 : 220) - height)
                make.width.equalTo(64)
                make.height.equalTo(self.deleteContainerHeight)
            }
            actionView.addSubview(sendButton)
            sendButton.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            actionView.addSubview(deleteButton)
        }

        deleteButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    public func updateActionBtnIfNeeded() {
        let enable = actionBtnEnable()
        self.deleteButton.isEnabled = enable
    }

    public func emotionActionViewWidth() -> CGFloat {
        return self.isNewKeyboardStyleEnable() ? 64 : 56
    }

    public func emotionActionView() -> UIView? {
        return self.actionView
    }

    public func emotionEmptyView() -> UIView? {
        return nil
    }

    public func actionBtnEnable() -> Bool {
        if let delegate = self.delegate {
            return delegate.emojiEmotionActionEnable()
        }

        return true
    }

    fileprivate func emoticonForIndexPath(_ indexPath: IndexPath) -> String {
        if self.clientChatInputEmojiUpdate {
            return indexPath.section == 1 ? self.emojis[indexPath.row].1 : self.recentEmojis[indexPath.row].1
        }
        return self.emojis[indexPath.row].1
    }

    func isNewKeyboardStyleEnable() -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.isKeyboardNewStyleEnable()
    }

    // MARK: - 点击事件
    @objc
    fileprivate func deleteButtonTapped() {
        self.delegate?.emojiEmotionInputViewDidTapBackspace()
    }

    @objc
    fileprivate func sendButtonTapped() {
        self.delegate?.emojiEmotionInputViewDidTapSend()
    }
}
*/
