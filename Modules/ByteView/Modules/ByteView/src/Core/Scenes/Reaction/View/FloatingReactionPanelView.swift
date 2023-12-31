//
//  FloatingReactionPanelView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewNetwork
import ByteViewSetting
import UniverseDesignIcon

protocol FloatingReactionPanelViewDelegate: AnyObject {
    func reactionPanelDidSelectReaction(reactionKey: String, isRecent: Bool)
    func reactionPanelDidLongPressReaction(reactionKey: String, isRecent: Bool)
    func reactionPanelDidFinishLongPress()
    func statusPanelDidSelectRaiseHand(isChangeSkin: Bool)
    func statusPanelDidSelectQuickLeave()
}

class FloatingReactionPanelView: UIView {
    private enum Layout {
        static let exclusiveViewHeight: CGFloat = 46
        static let statusReactionViewHeight: CGFloat = 38
        static let firstSectionHeaderHeight: CGFloat = 30
        static let sectionHeaderHeight: CGFloat = 18
        static let sectionInset = UIEdgeInsets(top: 6, left: 16, bottom: 16, right: 16)
        static let lastSectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        static let rowSpacing: CGFloat = 16
        static let defaultReactionSize = CGSize(width: 28, height: 28)
        static let bottomPadding: CGFloat = 12
        static let disableViewHorizontalInset: CGFloat = 12
        static let disableViewVerticalInset: CGFloat = 16
    }
    private let maxItemCount = 7
    private let reactionSize = CGSize(width: 28, height: 28)
    private static let column = 7
    private static let pressTriggleTime: TimeInterval = 0.3
    private static let exclusiveViewWidth: CGFloat = 306
    static let reactionPanelWidth: CGFloat = 330
    private var longPressTimer: Timer?
    private var isExpanded = false
    private var isUpward: Bool = true
    private var isLongPress = false

    weak var delegate: FloatingReactionPanelViewDelegate?

    private static let panelCellID = "FloatingReactionPanelCellID"
    private static let headerCellID = "FloatingReactionHeaderCellID"
    private lazy var layout = self.emotion.createLayout(.leftAlignedFlowLayout)
    private let panelGuide: UILayoutGuide = UILayoutGuide()

    private lazy var disableViewHeight: CGFloat = I18n.View_G_HostNotAllowEmoji.vc.boundingHeight(width: Self.reactionPanelWidth - Layout.disableViewHorizontalInset * 2, config: .tinyAssist) + Layout.disableViewVerticalInset * 2

    private lazy var reminderView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = .ud.bgFloatOverlay
        bgView.layer.cornerRadius = 6

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: I18n.View_G_ReactionBursts_Desc, config: .tinyAssist, textColor: .ud.textCaption)

        let closeBtn = UIButton()
        let image = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN2, size: CGSize(width: 16, height: 16))
        closeBtn.setImage(image, for: .normal)
        closeBtn.setImage(image, for: .highlighted)
        closeBtn.addTarget(self, action: #selector(closeTip), for: .touchUpInside)
        closeBtn.vc.setBackgroundColor(.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        closeBtn.layer.cornerRadius = 6
        closeBtn.layer.masksToBounds = true
        closeBtn.addInteraction(type: .highlight)

        bgView.addSubview(label)
        bgView.addSubview(closeBtn)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.left.equalToSuperview().offset(12)
        }
        closeBtn.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(5)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
            make.right.equalToSuperview().inset(5)
        }
        return bgView
    }()
    private lazy var guideTip: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(reminderView)
        reminderView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        view.isHidden = !shouldShowGuideTip
        return view
    }()

    private lazy var allReactionsView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = true
        collectionView.register(ReactionCell.self, forCellWithReuseIdentifier: Self.panelCellID)
        collectionView.register(ReactionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Self.headerCellID)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private lazy var disableView: UIView = {
        let view = UIView()
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: I18n.View_G_HostNotAllowEmoji, config: .tinyAssist, textColor: .ud.textPlaceholder)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.disableViewVerticalInset)
            make.width.lessThanOrEqualToSuperview().inset(Layout.disableViewHorizontalInset)
            make.center.equalToSuperview()
        }
        view.backgroundColor = .ud.bgFloat
        return view
    }()

    private lazy var exclusiveReactionsView: ExclusiveReactionsView = {
        let view = ExclusiveReactionsView(emotion: self.emotion)
        view.delegate = self
        view.longPressDelegate = self
        return view
    }()
    lazy var statusContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgFloat
        view.addSubview(statusReactionsView)
        statusReactionsView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(Layout.bottomPadding)
            make.height.equalTo(Layout.statusReactionViewHeight)
        }
        return view
    }()

    lazy var statusReactionsView: StatusReactionsView = {
        let view = StatusReactionsView(setting: setting)
        view.delegate = self
        view.backgroundColor = .clear
        return view
    }()

    let recentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    var tipView: ReactionTipView?

    var recentReactions: [ReactionEntity] = [] {
        didSet {
            updateDataSource()
            if !isLongPress {
                allReactionsView.reloadData()
            }
        }
    }
    private var reactions: [Emojis] = []
    var allReactions: [Emojis] = [] {
        didSet {
            updateDataSource()
            if !isLongPress {
                allReactionsView.reloadData()
            }
        }
    }

    var allowSendReaction: Bool = true {
        didSet {
            updateSendReactionView()
        }
    }
    private var allReactionsWithSize: [[CGSize]] = []
    private let hasStatusReactions: Bool
    private let hasExclusiveReaction: Bool
    private let service: MeetingBasicService
    private var setting: MeetingSettingManager { service.setting }
    private var emotion: EmotionDependency { service.emotion }
    private var shouldShowGuideTip: Bool { service.shouldShowGuide(.reactionPressOnboarding) }

    init(service: MeetingBasicService) {
        self.service = service
        self.hasStatusReactions = service.setting.showsStatusReaction
        self.hasExclusiveReaction = service.setting.isExclusiveReactionEnabled
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        layer.ud.setShadow(type: .s4Down)
        statusContainerView.isHidden = !hasStatusReactions
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgFloat
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 12
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(allReactionsView)
        containerView.addSubview(guideTip)
        containerView.addSubview(recentContainerView)

        recentContainerView.addSubview(exclusiveReactionsView)
        recentContainerView.addSubview(disableView)
        recentContainerView.addSubview(statusContainerView)

        updateRecentContainerLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var recentViewIntrinsicHeight: CGFloat {
        if allowSendReaction {
            if hasStatusReactions && hasExclusiveReaction {
                return Layout.exclusiveViewHeight + Layout.statusReactionViewHeight + Layout.bottomPadding
            } else if hasExclusiveReaction {
                return Layout.exclusiveViewHeight
            } else {
                return Layout.statusReactionViewHeight + Layout.bottomPadding * 2
            }
        } else {
            if hasStatusReactions {
                return disableViewHeight + Layout.statusReactionViewHeight + Layout.bottomPadding * 2
            } else {
                return disableViewHeight
            }
        }
    }

    func resetScrollPosition() {
        allReactionsView.setContentOffset(.zero, animated: false)
        exclusiveReactionsView.resetScrollPosition()
    }

    func updateExpandDirection(isUpward: Bool) {
        self.isUpward = isUpward
        let isShowGuideTip = shouldShowGuideTip && allowSendReaction
        if isShowGuideTip {
            guideTip.snp.remakeConstraints { make in
                if isUpward {
                    make.top.equalToSuperview()
                } else {
                    make.top.equalTo(recentContainerView.snp.bottom)
                }
                make.left.right.equalToSuperview()
            }
        } else {
            guideTip.snp.removeConstraints()
        }
        if isUpward {
            setShadow(recentContainerView, isUp: true)
            allReactionsView.snp.remakeConstraints { (make) in
                if isShowGuideTip {
                    make.top.equalTo(reminderView.snp.bottom)
                    make.left.right.equalToSuperview()
                } else {
                    make.left.right.top.equalToSuperview()
                }
            }
            recentContainerView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(allReactionsView.snp.bottom)
                make.height.equalTo(0).priority(.low)
            }
        } else {
            setShadow(recentContainerView, isUp: false)
            recentContainerView.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(0).priority(.low)
            }
            allReactionsView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                if isShowGuideTip {
                    make.top.equalTo(reminderView.snp.bottom)
                } else {
                    make.top.equalTo(recentContainerView.snp.bottom)
                }
            }
        }
    }

    // MARK: - Private
    private func updateSendReactionView() {
        exclusiveReactionsView.isHidden = !allowSendReaction
        disableView.isHidden = allowSendReaction
        if shouldShowGuideTip {
            updateExpandDirection(isUpward: isUpward)
        }
        updateRecentContainerLayout()
    }

    private func updateRecentContainerLayout() {
        statusContainerView.layer.ud.setShadowColor(.clear)

        exclusiveReactionsView.snp.removeConstraints()
        statusContainerView.snp.removeConstraints()
        disableView.snp.removeConstraints()

        if allowSendReaction {
            if hasStatusReactions && hasExclusiveReaction {
                exclusiveReactionsView.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.left.equalToSuperview().inset(12)
                    make.width.greaterThanOrEqualTo(Self.exclusiveViewWidth)
                    make.right.equalToSuperview().inset(12).priority(.high)
                    make.height.equalTo(Layout.exclusiveViewHeight)
                }
                statusContainerView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(exclusiveReactionsView.snp.bottom)
                    make.bottom.equalToSuperview()
                }
                statusReactionsView.snp.remakeConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(Layout.bottomPadding)
                    make.height.equalTo(Layout.statusReactionViewHeight)
                }
            } else if hasExclusiveReaction {
                exclusiveReactionsView.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.left.equalToSuperview().inset(12)
                    make.width.greaterThanOrEqualTo(Self.exclusiveViewWidth)
                    make.right.equalToSuperview().inset(12).priority(.high)
                    make.height.equalTo(Layout.exclusiveViewHeight)
                    make.bottom.equalToSuperview()
                }
            } else if hasStatusReactions {
                statusContainerView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
                statusReactionsView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.bottom.equalToSuperview().inset(Layout.bottomPadding)
                    make.height.equalTo(Layout.statusReactionViewHeight)
                }
            }
        } else {
            if hasStatusReactions {
                setShadow(statusContainerView, isUp: true)
                disableView.snp.remakeConstraints { make in
                    make.top.left.right.equalToSuperview()
                }
                statusContainerView.snp.remakeConstraints { make in
                    make.top.equalTo(disableView.snp.bottom)
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
                statusReactionsView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.bottom.equalToSuperview().inset(Layout.bottomPadding)
                    make.height.equalTo(Layout.statusReactionViewHeight)
                }
            } else {
                disableView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }

    private func setShadow(_ view: UIView, isUp: Bool) {
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        view.layer.shadowRadius = 3
        view.layer.shadowOffset = CGSize(width: 0, height: isUp ? -2 : 2)
        view.layer.shadowOpacity = 1
    }

    private func stopLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private var minimumInteritemSpacing: CGFloat {
        let size = Layout.defaultReactionSize
        let number = 7
        let insets = Layout.lastSectionInset.left + Layout.lastSectionInset.right

        let space = (allReactionsView.bounds.width - size.width * CGFloat(number) - insets) / CGFloat(number - 1)
        return space
    }

    private func updateDataSource() {
        let section = Emojis(type: .default, iconKey: "", title: I18n.View_G_Recently_Desc, source: "", keys: recentReactions.map { .init(key: $0.key, selectedSkinKey: $0.selectSkinKey) })
        reactions = [section] + allReactions
        allReactionsWithSize = reactions.map {
            $0.keys.map {
                emotion.sizeBy($0.key) ?? Layout.defaultReactionSize
            }
        }
    }

    private var numberOfItemsToShow: Int {
        guard allReactionsView.bounds.width > 0 else { return 0 }

        // 计算出最长的显示宽度，需要去掉更多按钮的宽度
        let panelWidth = allReactionsView.bounds.width - Layout.sectionInset.right - Layout.sectionInset.left
        // 根据是否需要显示更多按钮决定最后一个显示的item是否要右对齐
        // 计算实际需要显示的reaction个数
        let minSpace: CGFloat = minimumInteritemSpacing
        var width: CGFloat = 0
        var count: Int = 0
        for item in recentReactions {
            // 高度固定等于默认高度
            let displayHeight = reactionSize.height
            // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
            var displayWidth = reactionSize.width
            // 取出图片的实际 size
            let size = item.size
            // 主端产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
            // 根据上面的规则在28的高度限制下，宽度应该限制在28~39.08之间
            if size.height != 0 {
                // 如果宽度大于39（对39.08向下取整），说明是企业自定义表情，容器宽度有自己的计算规则
                if size.width > 39 {
                    // 宽度等比缩放
                    displayWidth = displayHeight * size.width / size.height
                } else {
                    // 默认表情（28高度下，宽度限制在28~39.08之间）容器的大小是等宽等高的
                    displayWidth = displayHeight
                }
            }
            if width + displayWidth > (panelWidth + 3) {
                break
            }
            count += 1
            width += (displayWidth + minSpace)
        }
        let recentReactionsCount = min(maxItemCount, count)

        // 经过计算后发现实际显示的Reaction要比数据源里面的少
        if recentReactionsCount < recentReactions.count {
            let start = recentReactionsCount
            let end = recentReactions.count
            // 数据源里面去掉不要显示的
            recentReactions.removeSubrange(start..<end)
        }
        return recentReactionsCount
    }

    @objc
    private func closeTip() {
        service.didShowGuide(.reactionPressOnboarding)
        guideTip.isHidden = true
        updateExpandDirection(isUpward: isUpward)
    }

    private func assureTipView() {
        switch service.setting.reactionDisplayMode {
        case .floating:
            if !(tipView is FloatReactionTipView) {
                tipView = FloatReactionTipView(emotion: service.emotion)
            }
        case .bubble:
            if !(tipView is BubbleReactionTipView) {
                tipView = BubbleReactionTipView(emotion: service.emotion)
            }
        }
    }
}

extension FloatingReactionPanelView: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        reactions.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? numberOfItemsToShow : reactions[section].keys.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.panelCellID, for: indexPath) as? ReactionCell else { return UICollectionViewCell() }
        cell.emotion = self.emotion
        cell.delegate = self
        let selectedSkinKey = reactions[indexPath.section].keys[indexPath.row].selectedSkinKey
        cell.reactionKey = selectedSkinKey.isEmpty ? reactions[indexPath.section].keys[indexPath.row].key : selectedSkinKey
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: Self.headerCellID,
                                                                             for: indexPath) as? ReactionHeaderView else {
                    return UICollectionReusableView()
                }

        let emoji = reactions[indexPath.section]
        header.update(icon: emoji.iconKey, title: emoji.title)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedSkinKey = reactions[indexPath.section].keys[indexPath.row].selectedSkinKey
        let reactionKey = selectedSkinKey.isEmpty ? reactions[indexPath.section].keys[indexPath.row].key : selectedSkinKey
        // handle click reaction
        delegate?.reactionPanelDidSelectReaction(reactionKey: reactionKey, isRecent: false)
        ChatTracks.trackReaction(key: reactionKey)
    }
}

extension FloatingReactionPanelView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let reaction = reactions[indexPath.section]
        if indexPath.section == 0 {
            let size = allReactionsWithSize[safeAccess: indexPath.section]?[safeAccess: indexPath.row] ?? Layout.defaultReactionSize
            let height = Layout.defaultReactionSize.height
            let width = size.width > 39 ? height * size.width / size.height : height
            return CGSize(width: width, height: height)
        } else if reaction.type == .default {
            // 默认类型表情返回固定大小就行
            return Layout.defaultReactionSize
        } else {
            // 只有企业自定义表情才需要每个元素分别计算大小
            // 高度固定
            let height = Layout.defaultReactionSize.height
            let size = allReactionsWithSize[safeAccess: indexPath.section]?[safeAccess: indexPath.row] ?? Layout.defaultReactionSize
            let width = height * size.width / size.height
            return CGSize(width: width, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == reactions.count - 1 {
            // 最后一行下边距要宽一点
            return Layout.lastSectionInset
        }
        return Layout.sectionInset
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Layout.rowSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        minimumInteritemSpacing
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0.1, height: section == 0 ? Layout.firstSectionHeaderHeight : Layout.sectionHeaderHeight)
    }
}

extension FloatingReactionPanelView: ReactionCellDelegate {
    func reactionCell(_ cell: UIView, didBeginLongPress gestureRecognizer: UILongPressGestureRecognizer, with reactionKey: String) {
        assureTipView()
        assert(tipView != nil)
        guard let tipView = tipView else { return }
        if gestureRecognizer.state == .began {
            isLongPress = true
            stopLongPressTimer()
            // 因为长按手势的识别时延，响应时我们就设置 count 从 2 起，下面也会调用两次发送表情接口
            tipView.show(cell, reactionKey: reactionKey, with: 2)
            let isRecent = cell.accessibilityIdentifier == ExclusiveReactionsView.cellID
            delegate?.reactionPanelDidLongPressReaction(reactionKey: reactionKey, isRecent: isRecent)
            delegate?.reactionPanelDidLongPressReaction(reactionKey: reactionKey, isRecent: isRecent)
            longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.pressTriggleTime, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                self.tipView?.count += 1
                self.delegate?.reactionPanelDidLongPressReaction(reactionKey: reactionKey, isRecent: isRecent)
            })
        } else if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled || gestureRecognizer.state == .failed {
            isLongPress = false
            tipView.dismiss(animate: false)
            delegate?.reactionPanelDidFinishLongPress()
            ChatTracks.trackReaction(key: reactionKey, comboCount: tipView.count)
            stopLongPressTimer()
        }
    }
}

extension FloatingReactionPanelView: ExclusiveReactionsViewDelegate {
    func exclusiveReactionsView(_ view: ExclusiveReactionsView, didClickItemAt index: Int) {
        let reactionKey = view.items[index]
        // handle click reaction
        delegate?.reactionPanelDidSelectReaction(reactionKey: reactionKey, isRecent: true)
        ChatTracks.trackReaction(key: reactionKey)
    }
}

extension FloatingReactionPanelView: StatusReactionsViewDelegate {

    func didSelectRaiseHand(isChangeSkin: Bool) {
        delegate?.statusPanelDidSelectRaiseHand(isChangeSkin: isChangeSkin)
    }

    func didSelectQuickLeave() {
        delegate?.statusPanelDidSelectQuickLeave()
    }
}
