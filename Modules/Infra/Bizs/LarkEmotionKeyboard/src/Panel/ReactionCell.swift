//
//  ReactionCell.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/17.
//
import UIKit
import Foundation
import LarkFloatPicker
import LarkFeatureGating
import LarkEmotion
import LKCommonsLogging

/// 由于reaction相关的UI都添加在LarkMenuController上，手势的响应和响应时候都受到
/// LarkMenuController上一堆手势影响，自定的手势如果需要不受这这些的影响，可以将gesture.name = emotionKeyboardHighPriorityGesture
/// 以这个命名的手势会高于处理与其他手势
public let emotionKeyboardHighPriorityGesture = "reaction.high.priority.gesture"

protocol ReactionCellDelegate: AnyObject {
    func supportSkinTones() -> Bool
    func onSkinTonesDidSelectedReactionKey(_ newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay)
}

final class ReactionCell: UICollectionViewCell, EmotionHighlightCollectionCell {
    private static let logger = Logger.log(ReactionCell.self, category: "Module.LarkEmotionKeyboard.ReactionCell")
    var icon: UIImageView = UIImageView()
    private weak var delegate: ReactionCellDelegate?

    private var longPressGesture: UILongPressGestureRecognizer?
    private var highLightedBackgroundView = UIImageView(image: Resources.emojiHighlightedBg)
    /// 是否支持长按手势
    private var supportSkinTones = false {
        didSet {
            longPressGesture?.isEnabled = supportSkinTones
        }
    }

    private var pickerManager: FloatPickerManager?

    private var reactionEntity: ReactionEntity? {
        didSet {
            if let key = reactionEntity?.selectSkinKey {
                self.reactionKey = key
            }
            self.supportSkinTones = !(reactionEntity?.skinKeys.isEmpty ?? false)
            // 支持多肤色的话打个日志
            if self.supportSkinTones {
                let count = reactionEntity?.skinKeys.count ?? 0
                Self.logger.info("ReactionCell: key = \(reactionEntity?.key) skin_lens = \(count)")
            }
            self.updateFloatPickerIfNeedWith(oldKey: oldValue?.selectSkinKey ?? "")
        }
    }

    var reactionKey: String = "" {
        didSet {
            let key = self.reactionKey
            var displaySize = CGSize(width: self.bounds.size.height, height: self.bounds.size.height)
            if displaySize.width == 0 || displaySize.height == 0 {
                displaySize = CGSize(width: 28, height: 28)
            }
            // 开始拉取图片
            self.reactionImageFetcher?.reactionViewImage(key) { [weak self] image in
                if self?.reactionKey != key { return }
                excuteInMain {
                    self?.icon.image = image ?? EmotionResouce.placeholder.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), resizingMode: .stretch)
                    if let size = image?.size, size.height != 0 {
                        // UI要求高度固定为28展示，宽度等比压缩显示
                        self?.icon.snp.remakeConstraints { make in
                            make.center.equalToSuperview()
                            make.width.equalTo(displaySize.height * size.width / size.height)
                            make.height.equalTo(displaySize.height)

                        }
                    } else {
                        // 恢复到原始宽度，避免兜底image展示异常
                        self?.icon.snp.remakeConstraints { make in
                            make.center.equalToSuperview()
                            make.left.right.equalToSuperview()
                            make.height.equalTo(displaySize.height)
                        }
                    }
                }
            }
        }
    }

    var reactionImageFetcher: ReactionImageDelegate.Type?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // setup highlight background
        self.contentView.addSubview(self.highLightedBackgroundView)
        self.highLightedBackgroundView.isHidden = true
        self.highLightedBackgroundView.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(-4)
            make.right.bottom.equalToSuperview().offset(4)
        }

        // setCellContnet会根据image.size计算出正确的显示size，设置scaleToFill让图片按照显示size进行展示
        icon.contentMode = .scaleToFill
        icon.isUserInteractionEnabled = false
        // 避免图片超出父视图部分被裁掉
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(28)
        }
        icon.accessibilityIdentifier = "reaction.cell.icon"

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gesture:)))
        longPress.name = emotionKeyboardHighPriorityGesture
        longPress.isEnabled = supportSkinTones
        longPress.minimumPressDuration = 0.4
        self.contentView.addGestureRecognizer(longPress)
        self.longPressGesture = longPress
    }

    func setReactionEntity(_ reactionEntity: ReactionEntity?, delegate: ReactionCellDelegate?) {
        self.reactionEntity = reactionEntity
        self.delegate = delegate
        /// 数据刷新之后，恢复选中状态
        self.hideHighlightedBackgroundView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        guard let entity = self.reactionEntity, !entity.skinKeys.isEmpty else {
            return
        }
        pickerManager?.onLongPress(gesture: gesture)
    }

    private func updateFloatPickerIfNeedWith(oldKey: String?) {
        guard supportSkinTones, let entity = self.reactionEntity else {
            return
        }
        if !entity.skinKeys.isEmpty, oldKey != entity.selectSkinKey {
            /// 替换之前如果有floatView存在，需要移除
            if pickerManager?.floatView != nil {
                pickerManager?.hideFloatPickerView()
            }
            let config = FloatPickerConfig(avoidInsets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
                                           allItemCount: entity.skinKeys.count,
                                           selectedItemIdx: entity.skinKeys.firstIndex(of: entity.selectSkinKey) ?? 0,
                                           interactiveStyle: .tapAndSlide,
                                           contentOffset: -4)
            self.pickerManager = FloatPickerManager(config: config, delegate: self)
        }
    }
    
    public func showHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = false
    }

    public func hideHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = true
    }
}

extension ReactionCell: FloatPickerManagerDelegate {
    public func didSelectedIndex(_ seletcedIdx: Int, allItemCount: Int, selectedWay: SelectedWay) {
        guard let entity = self.reactionEntity, entity.skinKeys.count == allItemCount else {
            return
        }
        self.delegate?.onSkinTonesDidSelectedReactionKey(entity.skinKeys[seletcedIdx],
                                                         oldSkinKey: entity.selectSkinKey,
                                                         defaultKey: entity.key,
                                                         selectedWay: selectedWay)
    }
    /// 外界用来配置ItemView
    public func itemViewWillAppearForIndexItem(_ indexItem: FloatPickerIndexItem,
                                        itemView: FloatPickerDisplayItemView) {
        guard let entity = self.reactionEntity, indexItem.idx < entity.skinKeys.count else {
            return
        }
        itemView.imageView.image = EmotionResouce.placeholder
        let idx = indexItem.idx
        // 开始拉取图片
        self.reactionImageFetcher?.reactionViewImage(entity.skinKeys[idx]) { [weak itemView] image in
            excuteInMain {
                itemView?.imageView.image = image
            }
        }
    }
}
