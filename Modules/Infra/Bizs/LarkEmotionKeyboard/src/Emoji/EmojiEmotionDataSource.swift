//
//  EmojiEmotionDataSource.swift
//  LarkCore
//
//  Created by 李晨 on 2019/8/14.
//

import UIKit
import Foundation
import SnapKit
import LarkEmotion
import LarkFeatureGating
import LarkContainer
import LKCommonsLogging
import RxSwift
import LarkFloatPicker
import UniverseDesignColor
import RustPB
import LarkSetting

public protocol EmojiEmotionItemDelegate: AnyObject {
    /**
     点击表情 Cell

     - parameter cell: 表情 cell
     */
    func emojiEmotionInputViewDidTapCell(emojiKey: String)

    /**
     点击表情退后键

     - parameter cell: 退后的 cell
     */
    func emojiEmotionInputViewDidTapBackspace()

    /**
     点击发送键
     */
    func emojiEmotionInputViewDidTapSend()

    /**
     是否可以点击发送键
     */
    func emojiEmotionActionEnable() -> Bool

    func isKeyboardNewStyleEnable() -> Bool

    /**
     成功切换到当前视图
     */
    func switchEmojiSuccess()

    /**
     是否支持长按表情出现表情换肤：默认支持
     */
    func supportSkinTones() -> Bool
    /**
     是否支持多肤色表情：默认支持
     */
    func supportMultiSkin() -> Bool
    /**
     是否支持最近使用表情：默认支持
     */
    func supportRecentUsed() -> Bool
    /**
     是否支持最常使用表情：默认支持
     */
    func supportMRU() -> Bool
}

public extension EmojiEmotionItemDelegate {

    func switchEmojiSuccess() {}
    /**
     是否支持表情长按换肤：默认支持
     */
    func supportSkinTones() -> Bool {
        return true
    }
    /**
     是否支持多肤色表情：默认支持
     */
    func supportMultiSkin() -> Bool {
        return true
    }
    /**
     是否支持最近使用表情：默认支持
     */
    func supportRecentUsed() -> Bool {
        return true
    }
    /**
     是否支持最常使用表情：默认支持
     */
    func supportMRU() -> Bool {
        return true
    }
}

// 服务端给的是ReactionEntity，需要把他映射成EmojiEntity
typealias EmojiEntity = ReactionEntity
// 服务端给的是ReactionGroup，需要把他映射成EmojiGroup
typealias EmojiGroup = ReactionGroup

public final class EmojiEmotionDataSource: EmotionItemDataSource {

    private static let logger = Logger.log(EmojiEmotionDataSource.self, category: "Module.LarkEmotionKeyboard.EmojiEmotionDataSource")

    public var isCommonlyUsedABTestEnable: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "im.emoji.commonly_used_abtest")
    }

    // if user longpress single cell and release at last, the callstask as below:
    //    ->didHighlightItemAt
    //    ->didUnHighlightItemAt
    //    ->longPressedAt
    //    ->longPressedEnd;

    // if user longpress cell1 than move to cell2 ,and release at last,the callstask as below:
    //    ->didHighlightItemAt(cell1)
    //    ->didUnHighlightItemAt(cell1)
    //    ->longPressedAt(cell1)
    //    ->longPressedEnd(cell1)
    //    ->longPressedAt(cell2)
    //    ->longPressedEnd(cell2);

    // avoid cell background flicker by using property "pressCell"
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Const.delayTimeInterval) {
            // when longpressing, do not hide highlighted background view
            guard self.longPressingCell == nil else {
                return
            }
            cell.hideHighlightedBackgroundView()
        }
    }

    public private(set) var deleteContainerHeight = 66

    // 用户最常 or 喜欢使用reaction的数量，打底是7个，需要根据实际的图片宽度计算最终值
    public private(set) var userReactionsCount: Int = 7

    public var identifier: String {
        return "emoji"
    }
    
    private var isSupportMRU: Bool {
        // 是否支持最近使用表情：默认支持
        return self.delegate?.supportMRU() ?? true
    }

    // 表情键盘的上下左右边距
    public func emotionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
    }

    // 每一行表情的行间距
    public func emotionLineSpacing() -> CGFloat {
        return 8
    }

    // 每一列表情的列间距
    public func emotionMinimumInteritemSpacing(section: Int) -> CGFloat {
        // 手机端最小间距
        var minSpace: CGFloat = Const.minSpaceOniPhone
        if self.displayInPad {
            // iPad端最小间距
            minSpace = Const.minSpaceOniPad
        }
        // 需要兜底一下还没上屏的情况，因为数据可以在显示之前就拉，会走到这边
        guard let collectionView = self.collection else {
            return minSpace
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

    public func setupSourceIconImage(_ callback: @escaping (UIImage) -> Void) {
        callback(Resources.emoji)
    }

    public weak var collection: UICollectionView?

    public weak var delegate: EmojiEmotionItemDelegate?

    /// 用户最常 or 最喜欢使用的EmojiKeys
    private var userEmojiKeys: [String] = []
    /// 所有的表情分类，每个分类里面的reactionEntity会自动转化成emojiEntity
    private var emojiGroups: [EmojiGroup] = []
    /// 是否是iPad
    private let displayInPad: Bool
    /// 展示高度
    private let displayHeight: CGFloat
    /// reaction注入服务
    private let dependency: EmojiDataSourceDependency?
    /// 依赖LarkKeyboardView用户态改造完修改，TODO：@qujieye
    @InjectedLazy var skinApi: ReactionSkinTonesAPI

    let disposeBag = DisposeBag()

    public var actionView: UIView = UIView()

    // 所有分类表情更新回调，需要更新数据源同时刷新collectionView
    public lazy var reactionlistener: ReactionListener = {
        let listener = ReactionListener()
        listener.allReactionChangeHandler = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { [weak self] in
                self?.setupDefaultEmojis()
            }
        }
        return listener
    }()

    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(Resources.keyboardDeleteIcon.ud.withTintColor(UIColor.ud.iconN3),
                              for: .normal)
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
        sendButton.setTitle(BundleI18n.LarkEmotionKeyboard.Lark_Legacy_Send, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return sendButton
    }()

    private let scene: EmotionKeyboardScene
    private let chatId: String?

    public init(dependency: EmojiDataSourceDependency? = EmojiImageService.default,
                scene: EmotionKeyboardScene,
                chatId: String? = nil,
                displayInPad: Bool,
                displayHeight: CGFloat) {
        assert(dependency != nil, "EmojiDataSourceDependency不能为空！若采用默认实现，请引入ReactionDependency这个subspec")
        self.scene = scene
        self.chatId = chatId
        self.dependency = dependency
        self.displayInPad = displayInPad
        self.displayHeight = displayHeight
        self.setupUserEmojis()
        self.setupDefaultEmojis()
        /// 监听自定义表情图片下载
        self.addCustomEmojiObserver()
        /// 监听肤色的变更
        dependency?.registReactionListener(reactionlistener)
    }
    
    // 获取用户最近、常用的reaction，同时会计算一行显示几个
    private func setupUserEmojis() {
        // 记录下当前用户喜欢的表情类型：最常使用 or 最近使用
        guard let reactions = self.dependency?.getMRUReactions() else { return }
        // 把reactionKey转换为emojiKey，存在对应的 emoji_key & 未下线 & 本地有图
        var emojiKeys = reactions.compactMap({ EmotionResouce.shared.emotionKeyBy(reactionKey: $0.key) })
            .filter({ !EmotionResouce.shared.isDeletedBy(key: $0) })
            .filter({ EmotionResouce.shared.imageBy(key: $0) != nil })
        // 非iPad设备默认等于屏幕宽度
        var containerWidth = UIScreen.main.bounds.width
        // 非iPad设备最多显示7个
        var maxNumber: Int = Const.maxNumberOnFGUnable
        var maxLine: Int = 1
        if isCommonlyUsedABTestEnable {
            // FG打开的时候需要显示两行，也就是最多14个
            maxNumber = Const.maxNumberOnFGEnable
            maxLine = 2
        }
        // 实际显示个数，需要动态计算
        var count: Int = 0
        // 左边距
        let leftSpace: CGFloat = self.emotionInsets().left
        // 右边距
        let rightSpace: CGFloat = self.emotionInsets().right
        // iPad设备需要特殊处理
        if self.displayInPad {
            // iPad设备默认是屏幕的一半（打底值）
            containerWidth = UIScreen.main.bounds.width / 2
            // iPad设备最多显示18个
            maxNumber = Const.maxNumberOniPad
            // 初始化完成collectionView有值后以collectionView的宽度为准
            if let collectionView = self.collection, collectionView.bounds.width > 0 {
                containerWidth = collectionView.bounds.width
            }
        }
        // 日志上报
        var extraInfo: [(key: String, index: Int, displayWidth: CGFloat, displayHeight: CGFloat, entityWidth: CGFloat, entityHeight: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat)] = []
        // 计算出panel的宽度
        let panelWidth = containerWidth - rightSpace - leftSpace
        // 列间距
        let minSpace = self.emotionMinimumInteritemSpacing(section: 0)
        var width: CGFloat = 0
        // 从一行开始算
        var line: Int = 1
        // 计算一行实际显示的个数
        for emojiKey in emojiKeys {
            if let emojiEntity = self.getUserEmojiEntity(emojiKey: emojiKey) {
                // 高度固定等于默认高度
                let displayHeight = self.emotionItemDefaultSize().height
                // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
                var displayWidth = self.emotionItemDefaultSize().width
                // 容器里面实际图片的大小
                let iconHeight: CGFloat = 32.0
                // 取出服务端返回的实际size
                let entitySize = emojiEntity.size
                var size = entitySize
                var imageSize = CGSize(width: 0, height: 0)
                // 如果图片大小和服务端给的不一致，以实际图片大小为准
                if let image = EmotionResouce.shared.imageBy(key: emojiEntity.key) {
                    imageSize = image.size
                    // 这样比较是为了忽略1像素的误差
                    if abs(imageSize.width - entitySize.width) > 1 || abs(imageSize.height - entitySize.height) > 1 {
                        size = image.size
                    }
                }
                // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
                // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
                if size.height != 0 {
                    // 把高度统一成32，算出同等比例下的宽度
                    var regularWidth = Const.regularWidth32 * size.width / size.height
                    // 如果宽度大于45（对44.6向下取整），说明是企业自定义表情，容器宽度有自己的计算规则
                    if regularWidth > Const.emojiWithThreshold {
                        let iconWidth = iconHeight * size.width / size.height
                        // 企业自定义表情的话容器间距固定
                        displayWidth = iconWidth + (2 * 6)
                    } else {
                        // 默认表情（32高度下，宽度限制在32~44.6之间）容器的大小是等宽等高的
                        displayWidth = displayHeight
                    }
                }
                width += (displayWidth + minSpace)
                // 这样写是为了能过CI检测：会限制每行最多的字符
                let k = emojiKey
                let dw = displayWidth
                let dh = displayHeight
                let ew = entitySize.width
                let eh = entitySize.height
                let iw = imageSize.width
                let ih = imageSize.height
                // 给个4像素的误差
                if width > (panelWidth + minSpace + 4) {
                    let tuples = (key: k, index: count + 1, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
                    extraInfo.append(tuples)
                    // 到这边说明该行已经布局不下，需要换行了，换行后累计宽度要重置
                    width = 0
                    // 如果已经达到最大行数，那就直接跳出循环
                    if line == maxLine {
                        break
                    } else {
                        // 还没到最大行数，那么正常换行
                        line += 1
                        // 换行以后的累计宽度
                        width += (displayWidth + minSpace)
                    }
                }
                count += 1
                let tuples = (key: k, index: count, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
                extraInfo.append(tuples)
            }
        }
        self.userReactionsCount = min(maxNumber, count)
        var number = self.userReactionsCount
        // 只取前number个，刚好够显示一行或者两行（由FG控制）
        emojiKeys = Array(emojiKeys.prefix(number))

        // 日志上报
        var params: [String: String] = [:]
        params["panelWidth"] = "\(panelWidth)"
        params["minSpace"] = "\(minSpace)"
        params["number"] = "\(number)"
        params["items"] = "\(extraInfo)"
        Self.logger.info("emotion keyboard: keyboard emojis info", additionalData: params)

        // 判断是否需要刷新表情面板
        var collectionNeedReloadSection: Bool = false
        if emojiKeys.count != self.userEmojiKeys.count {
            collectionNeedReloadSection = true
        } else {
            // 判断新旧keys顺序是否相同
            collectionNeedReloadSection = !emojiKeys.elementsEqual(self.userEmojiKeys)
        }
        guard collectionNeedReloadSection else { return }
        // 更新最近/最常使用表情数据
        self.userEmojiKeys = emojiKeys
        // 无脑全部刷新，因为有最常使用fg的原因，没必要再判断刷新第几个Section
        self.collection?.reloadData()
    }

    // 获取所有分类表情，包括：默认+企业自定义+LarkValues
    private func setupDefaultEmojis() {
        guard var groups = self.dependency?.getAllReactions() else { return }
        // 日志上报
        var params: [String: String] = [:]
        var extraInfo: [(title: String, entitiesCount: Int)] = []
        for group in groups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(groups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("emotion keyboard: allReactionGroups from ReactionServiceImpl", additionalData: params)
        // 兜底一下，防止一个表情都没有
        if groups.isEmpty {
            Self.logger.error("emotion keyboard: allReactionGroups isEmpty")
            let reactionEntitys = EmotionResouce.reactions.map({ ReactionEntity(key: $0, selectSkinKey: $0, skinKeys: [], size: EmotionResouce.shared.sizeBy(key: $0)) })
            groups = [ReactionGroup(type: .default, iconKey: "", title: BundleI18n.LarkEmotionKeyboard.Lark_IM_DefaultEmojis_Title, source: "", entities: reactionEntitys)]
        }
        // 把reactionEntity转换为EmojiEntity：存在对应的 emoji_key & 未下线 & 本地有图
        let shareEmotionResouce = EmotionResouce.shared
        // 需要先更新数据源，再刷新collectionView，因为有可能和上次拉到的分类不一样了，如果只刷新控件的话前后两次数据不一致会Crash
        self.emojiGroups.removeAll()
        for group in groups {
            // 先把ReactionEntity无脑转化成EmojiEntity（历史原因reactionKey和emojiKey可能不一样）
            let entitys: [EmojiEntity] = group.entities.compactMap { entity in
                var key = shareEmotionResouce.emotionKeyBy(reactionKey: entity.key) ?? ""
                var selectSkinKey = shareEmotionResouce.emotionKeyBy(reactionKey: entity.selectSkinKey) ?? key
                if group.type == .custom, shareEmotionResouce.isInAllResoucesMapBy(key: entity.key) == false {
                    // 如果是企业自定义表情，并且该表情还没有从远端拉下来（本地缓存中木有）
                    key = entity.key
                    selectSkinKey = entity.selectSkinKey
                }
                return EmojiEntity(key: key, selectSkinKey: selectSkinKey, skinKeys: entity.skinKeys, size: entity.size)
            }
            // 过滤EmojiEntity，把非法的踢出去，防止在面板上显示出非法的表情
            let emojiEntities = entitys
                .filter({
                    // 过滤不存在key的表情
                    let selectSkinKeyExist = !$0.selectSkinKey.isEmpty
                    let keyExist = !$0.key.isEmpty
                    if !selectSkinKeyExist {
                        Self.logger.error("emotion keyboard: selectSkinKey is not exit, remove from group")
                    }
                    if !keyExist {
                        Self.logger.error("emotion keyboard: key is not exit, remove from group")
                    }
                    return selectSkinKeyExist && keyExist
                })
            // 先更新数据源
            self.emojiGroups.append(EmojiGroup(type: group.type, iconKey: group.iconKey, title: group.title, source: group.source, entities: emojiEntities))
        }
        // 日志上报
        params.removeAll()
        extraInfo.removeAll()
        for group in self.emojiGroups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(self.emojiGroups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("emotion keyboard: allReactionGroups after filter", additionalData: params)
        // 数据源发生变化需要刷新collectionView
        UIView.performWithoutAnimation { [weak self] in
            FloatPickerManager.removeFloatPickerFromWindow(self?.collection?.window)
            self?.collection?.reloadData()
        }
    }

    public func numberOfOneRow() -> Int {
        return 7
    }

    public func emotionItemDefaultSize() -> CGSize {
        return CGSize(width: 48, height: 48)
    }

    /*
        每个表情的具体size：具体到某行某列，引入LarkValue后表情就不是等宽的了
        产品定义了一套很复杂的规则，具体如下，反正也看不懂，参考下就行
        1. 尺寸规范：图片资源高度为96px*width，96px≤width≤464px（4倍图）
        2. 面板适配规则：定高96px，宽度自适应，但是最大最小限制为：96px≤width≤464px（4倍图）
        emoji在面板的排版根据宽度区分而不是类型，width＞134px的emoji按宽版表情的间距分布
        width＜134px的emoji按照线上默认emoji的间距分布
     */
    public func emotionItemSize(indexPath: IndexPath) -> CGSize {
        if let emojiEntity = self.emojiEntityForIndexPath(indexPath) {
            // 只有企业自定义表情才需要每个元素分别计算大小，其他类型表情返回固定大小就行
            let type: Im_V1_EmojiPanel.TypeEnum = self.emojiEntityTypeForIndexPath(indexPath: indexPath)
            if type == .default {
                // 返回默认值
                return self.emotionItemDefaultSize()
            }

            // 高度固定等于默认高度
            let displayHeight = self.emotionItemDefaultSize().height
            // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
            var displayWidth = self.emotionItemDefaultSize().width
            // 容器里面实际图片的大小
            let iconHeight: CGFloat = 32.0
            // 取出服务端返回的实际size
            let entitySize = emojiEntity.size
            var size = entitySize
            // 如果图片大小和服务端给的不一致，以实际图片大小为准
            if let image = EmotionResouce.shared.imageBy(key: emojiEntity.key) {
                // 这样比较是为了忽略1像素的误差
                if abs(image.size.width - entitySize.width) > 1 || abs(image.size.height - entitySize.height) > 1 {
                    size = image.size
                }
            }
            // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
            // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
            if size.height != 0 {
                // 如果宽度大于45，说明是企业自定义表情，容器宽度有自己的计算规则
                if size.width > Const.emojiWithThreshold {
                    let iconWidth = iconHeight * size.width / size.height
                    // 企业自定义表情的话容器间距固定
                    displayWidth = iconWidth + (2 * 6)
                } else {
                    // 默认表情（32高度下，宽度限制在32~44.6之间）容器的大小是等宽等高的
                    displayWidth = displayHeight
                }
                return CGSize(width: displayWidth, height: displayHeight)
            }
        }
        // 返回默认值
        return self.emotionItemDefaultSize()
    }

    public func headerReferenceSize() -> CGSize {
        // 宽度只需要设置一个0.1，系统会默认拉长为所在视图的宽度
        return CGSize(width: 0.1, height: 26)
    }

    public func needAddEmptyView() -> Bool {
        return self.userEmojiKeys.isEmpty
    }

    public func didSelect() {
        self.setupUserEmojis()
        EmojiTracker.view(scene: scene)
    }

    public func didSwitch() {
        self.delegate?.switchEmojiSuccess()
    }

    public func numberOfSections() -> Int {
        // 最常使用+所有默认分类
        return 1 + self.emojiGroups.count
    }

    public func numberOfEmotions(section: Int) -> Int {
        // 最常使用
        if section == 0 {
            return self.userEmojiKeys.count
        }
        let rowIndex = section - 1
        guard rowIndex < self.emojiGroups.count else {
            return 0
        }
        return self.emojiGroups[rowIndex].entities.count
    }

    public func didSelectEmotion(indexPath: IndexPath) {
        // 最常使用
        if indexPath.section == 0 {
            guard indexPath.row < self.userEmojiKeys.count else {
                return
            }
            let emojiKey = self.emojiKeyForIndexPath(indexPath)
            self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: emojiKey)
            EmojiTracker.click(emojiKey, scene: scene, tab: .recent, chatId: chatId, isSkintonePanel: false)
            return
        }
        // 点击其他分类表情
        if let emojiEntity = self.emojiEntityForIndexPath(indexPath) {
            var emojiKey = emojiEntity.key
            emojiKey = emojiEntity.selectSkinKey
            self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: emojiKey)
            let logKey = EmotionResouce.shared.reactionKeyBy(emotionKey: emojiKey) ?? emojiKey
            EmojiTracker.click(logKey, scene: scene, tab: .all, chatId: chatId, isSkintonePanel: false)
        }
    }

    public func collectionView(collectionView: UICollectionView,
                               insetForSectionAt section: Int,
                               bottomBarHeight: CGFloat) -> UIEdgeInsets {
        if section == self.numberOfSections() - 1 {
            // 最后一行下边距要宽一点
            var edgeInsets = self.emotionInsets()
            edgeInsets.bottom += bottomBarHeight
            return edgeInsets
        }
        return self.emotionInsets()
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
                var xOffset: CGFloat = 14
                if indexPath.section == 0 {
                    var str = BundleI18n.LarkEmotionKeyboard.Lark_IM_FrequentlyUsedEmojis_Title
                    let model = EmotionHeaderModel(iconKey: nil, titleName: str)
                    emotionHeaderView.setData(model: model, xOffset: xOffset)
                } else {
                    // 其他分类
                    let rowIndex = indexPath.section - 1
                    guard rowIndex < self.emojiGroups.count else {
                        return cell
                    }
                    let group = self.emojiGroups[rowIndex]
                    emotionHeaderView.setData(model: EmotionHeaderModel(iconKey: group.iconKey, titleName: group.title), xOffset: xOffset)
                }
            }
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionCell(collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: EmotionCell.self)
        let cell = collection.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? EmotionCell {
            collectionCell.setCellContnet(EmotionResouce.shared.imageBy(key: self.emojiKeyForIndexPath(indexPath)),
                                          emojiEntity: self.emojiEntityForIndexPath(indexPath),
                                          delegate: self)
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

    public func setDeleteContainerHeight(_ height: ConstraintRelatableTarget) {
        self.deleteContainer.snp.updateConstraints { make in
            make.top.equalTo(height)
        }
    }

    public func updateActionBtnIfNeeded() {
        let enable = actionBtnEnable()
        self.deleteButton.isEnabled = enable
    }

    public func emotionActionViewWidth() -> CGFloat {
        if self.isNewKeyboardStyleEnable() {
            return Const.emotionActionViewWidthOnStyle
        } else {
            let labelFont = UIFont.systemFont(ofSize: 15)
            let labelText = BundleI18n.LarkEmotionKeyboard.Lark_Legacy_Send
            let rect = CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT))
            let labelTextSize = (labelText as NSString)
                .boundingRect(with: rect, options: .usesLineFragmentOrigin,
                              attributes: [.font: labelFont], context: nil)
            return max(Const.emotionActionViewMaxWidth, labelTextSize.width + 24)
        }
    }

    public func emotionActionView(excludeSendBtn: Bool) -> UIView? {
        if !self.isNewKeyboardStyleEnable(), excludeSendBtn { return nil }
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

    // 返回emojiKey，注意不是reactionKey
    fileprivate func emojiKeyForIndexPath(_ indexPath: IndexPath) -> String {
        if indexPath.section == 0 {
            // 最常使用的Reactions
            if indexPath.row < self.userEmojiKeys.count {
                return self.userEmojiKeys[indexPath.row]
            }
            return ""
        }
        // 其他分类Reactions
        let section = indexPath.section - 1
        if section < self.emojiGroups.count, indexPath.row < self.emojiGroups[section].entities.count {
            return self.emojiGroups[section].entities[indexPath.row].selectSkinKey
        }
        return ""
    }

    // 返回emojiEntity，里面的key是从reactionKey转换成emojiKey的
    fileprivate func emojiEntityForIndexPath(_ indexPath: IndexPath) -> EmojiEntity? {
        if indexPath.section == 0 {
            // 最常使用的Reactions
            if indexPath.row < self.userEmojiKeys.count {
                return self.getUserEmojiEntity(emojiKey: self.userEmojiKeys[indexPath.row])
            }
            return nil
        }
        // 其他分类Reactions
        let section = indexPath.section - 1
        if section < self.emojiGroups.count, indexPath.row < self.emojiGroups[section].entities.count {
            return self.emojiGroups[section].entities[indexPath.row]
        }
        return nil
    }

    private func getUserEmojiEntity(emojiKey: String) -> EmojiEntity? {
        let resource = EmotionResouce.shared
        let reactionKey = resource.reactionKeyBy(emotionKey: emojiKey)
        let reactions = self.dependency?.getMRUReactions()
        // 历史原因，需要把reactionKey转成emojiKey
        if let reactionEntity = reactions?.first(where: { entity in
            return entity.key == reactionKey
        }) {
            return EmojiEntity(key: resource.emotionKeyBy(reactionKey: reactionEntity.key) ?? "",
                               selectSkinKey: resource.emotionKeyBy(reactionKey: reactionEntity.selectSkinKey) ?? "",
                               skinKeys: reactionEntity.skinKeys.compactMap { resource.emotionKeyBy(reactionKey: $0) },
                               size: reactionEntity.size)
        }
        return nil
    }

    private func emojiEntityTypeForIndexPath(indexPath: IndexPath) -> Im_V1_EmojiPanel.TypeEnum {
        if indexPath.section == 0 {
            // 最常使用的Reactions
            if let reactions = self.dependency?.getMRUReactions(), indexPath.item < reactions.count {
                let reactionEntity = reactions[indexPath.item]
                if isNumber(string: reactionEntity.key) {
                    return .custom
                }
                // 把高度统一成32，算出同等比例下的宽度
                var regularWidth = 32.0
                if reactionEntity.size.height > 0 {
                    regularWidth = Const.regularWidth32 * reactionEntity.size.width / reactionEntity.size.height
                }
                // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
                // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
                if regularWidth <= Const.emojiWithThreshold {
                    // 如果宽度小于等于45，说明是默认表情
                    return .default
                } else {
                    // 如果宽度大于45，说明是企业自定义表情
                    return .custom
                }
            }
            return .unknown
        }
        // 其他分类Reactions
        let section = indexPath.section - 1
        if section < self.emojiGroups.count {
            return self.emojiGroups[section].type
        }
        return .default
    }

    private func addCustomEmojiObserver() {
        // 企业自定义表情图片下载成功通知
        let notificationName = NSNotification.Name("LKEmojiImageDownloadSucceed")
        NotificationCenter
            .default
            .rx
            .notification(.LKEmojiImageDownloadSucceedNotification)
            .subscribe(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                guard let notificationInfo = notification.object as? [String: Any] else { return }
                if let key = notificationInfo["key"] as? String {
                    Self.logger.info("emotion keyboard: emojiKey \(key) image is download succeed, reload data")
                    // 企业自定义表情图片下载成功需要刷新collectionView
                    self.collection?.reloadData()
                }
            }).disposed(by: self.disposeBag)
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
    
    private func isNumber(string: String) -> Bool {
        let reg = "^[0-9]+$"
        let pre = NSPredicate(format: "SELF MATCHES %@", reg)
        return pre.evaluate(with: string)
    }
}

extension EmojiEmotionDataSource: EmotionCellDelegate {

    public func onSkinTonesDidSelectedKey(_ newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay) {
        let defaultReactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: defaultKey) ?? defaultKey
        let skinReactionKey = EmotionResouce.shared.reactionKeyBy(emotionKey: newSkinKey) ?? newSkinKey
        if newSkinKey != oldSkinKey {
            self.skinApi.updateReactionSkin(defaultReactionKey: defaultReactionKey,
                                            skinKey: skinReactionKey)
                .subscribe(onError: { error in
                    Self.logger.error("emotion keyboard: emoji updateReactionSkin", error: error)
                }).disposed(by: self.disposeBag)
        }
        EmojiTracker.click(newSkinKey, scene: scene, tab: .all, chatId: chatId, isSkintonePanel: true, skintoneEmojiSelectWay: selectedWay)
        self.delegate?.emojiEmotionInputViewDidTapCell(emojiKey: newSkinKey)
    }

    public func getImageForKey(_ imageKey: String) -> UIImage? {
        return EmotionResouce.shared.imageBy(key: imageKey)
    }

    public func onKeyboardStatusChange(isFold: Bool) {
    }
}

extension EmojiEmotionDataSource {
    enum Const {
        public static let emotionActionViewMaxWidth: CGFloat = 56
        public static let emotionActionViewWidthOnStyle: CGFloat = 64
        public static let delayTimeInterval: CGFloat = 0.1
        public static let minSpaceOniPad: CGFloat = 16.0
        public static let minSpaceOniPhone: CGFloat = 4.5
        public static let maxNumberOnFGEnable: Int = 14
        public static let maxNumberOnFGUnable: Int = 7
        public static let maxNumberOniPad: Int = 18
        public static let regularWidth32: CGFloat = 32.0
        public static let emojiWithThreshold: CGFloat = 45
    }
}
