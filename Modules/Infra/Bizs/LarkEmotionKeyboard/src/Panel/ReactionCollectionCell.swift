//
//  ReactionCollectionCell.swift
//  LarkEmotionKeyboard
//
//  Created by phoenix on 2023/3/28.
//

import UIKit
import Foundation
import LarkFloatPicker
import LarkEmotion
import LKCommonsLogging

protocol ReactionCollectionCellDelegate: AnyObject {
    func onSkinTonesDidSelected(newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay)
}

final class ReactionCollectionCell: UICollectionViewCell {
    private static let logger = Logger.log(ReactionCollectionCell.self, category: "Module.LarkEmotionKeyboard.ReactionCollectionCell")
    
    // 表情图标
    var iconView: UIImageView = UIImageView()
    
    private weak var delegate: ReactionCollectionCellDelegate?

    private var longPressGesture: UILongPressGestureRecognizer?
    
    // 是否支持长按手势
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
            // 支持多肤色
            if self.supportSkinTones {
                let key = reactionEntity?.key ?? ""
                let selectSkinKey = reactionEntity?.selectSkinKey ?? ""
                let skinKeys = reactionEntity?.skinKeys ?? []
                Self.logger.info("ReactionCollectionCell: key = \(key) selectSkinKey = \(selectSkinKey) skinKeys = \(skinKeys)")
                self.updateFloatPickerIfNeed()
            } else {
                // 不支持多肤色的话需要把pickerManager设置成nil
                if pickerManager?.floatView != nil {
                    pickerManager?.hideFloatPickerView()
                }
                self.pickerManager = nil
            }
        }
    }

    var reactionKey: String = "" {
        didSet {
            let key = self.reactionKey
            // 表情图片的高度和容器一致
            let iconHeight = self.bounds.size.height != 0 ? self.bounds.size.height : 28
            var iconWidth = self.bounds.size.width != 0 ? self.bounds.size.width : 28
            if let image = EmotionResouce.shared.imageBy(key: key), image.size.height != 0 {
                iconView.image = image
                // 等比计算图片的宽度
                iconWidth = iconHeight * image.size.width / image.size.height
                // 高度等于容器高度，宽度根据图片大小等比压缩
                iconView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(iconWidth)
                    make.height.equalTo(iconHeight)
                }
            } else {
                let key = self.reactionKey
                Self.logger.error("ReactionCollectionCell: key = \(key) has no image!!! use palceholder image!!!")
                iconView.image = EmotionResouce.placeholder
                // 恢复到和容器大小一致，避免兜底image展示异常
                iconView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalToSuperview()
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 设置reactionKey的时候会根据image.size计算出正确的显示size，设置scaleToFill让图片按照显示size进行展示
        iconView.contentMode = .scaleToFill
        iconView.isUserInteractionEnabled = false
        // 避免图片超出父视图部分被裁掉
        self.contentView.clipsToBounds = false
        self.contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview()
        }
        iconView.accessibilityIdentifier = "reaction.cell.icon"
        iconView.backgroundColor = UIColor.clear

        // 添加长按换肤手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gesture:)))
        // 由于reaction相关的UI都添加在LarkMenuController上，手势的响应和响应时候都受到
        // LarkMenuController上一堆手势影响，自定的手势如果需要不受这这些的影响，需要将name设置成：reaction.high.priority.gesture
        // 以这个命名的手势会高于处理与其他手势
        longPress.name = "reaction.high.priority.gesture"
        longPress.isEnabled = supportSkinTones
        longPress.minimumPressDuration = 0.4
        self.contentView.addGestureRecognizer(longPress)
        self.longPressGesture = longPress
    }

    func setCellContent(reactionEntity: ReactionEntity?, delegate: ReactionCollectionCellDelegate?) {
        // 清空上次的图片
        self.iconView.image = EmotionResouce.placeholder
        self.iconView.transform = CGAffineTransform.identity
        self.reactionEntity = reactionEntity
        self.delegate = delegate
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        guard let entity = self.reactionEntity, !entity.skinKeys.isEmpty else {
            Self.logger.error("ReactionCollectionCell: longPressed key = \(self.reactionKey) skinKeys is empty")
            return
        }
        pickerManager?.onLongPress(gesture: gesture)
    }

    private func updateFloatPickerIfNeed() {
        guard supportSkinTones, let entity = self.reactionEntity else {
            return
        }
        if !entity.skinKeys.isEmpty {
            // 替换之前如果有floatView存在，需要移除
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
}

extension ReactionCollectionCell: FloatPickerManagerDelegate {
    public func didSelectedIndex(_ seletcedIdx: Int, allItemCount: Int, selectedWay: SelectedWay) {
        guard let entity = self.reactionEntity, entity.skinKeys.count == allItemCount else {
            return
        }
        self.delegate?.onSkinTonesDidSelected(newSkinKey: entity.skinKeys[seletcedIdx],
                                              oldSkinKey: entity.selectSkinKey,
                                              defaultKey: entity.key,
                                              selectedWay: selectedWay)
    }
    // 外界用来配置ItemView
    public func itemViewWillAppearForIndexItem(_ indexItem: FloatPickerIndexItem,
                                               itemView: FloatPickerDisplayItemView) {
        guard let entity = self.reactionEntity, indexItem.idx < entity.skinKeys.count else {
            return
        }
        let skinKey = entity.skinKeys[indexItem.idx]
        if let image = EmotionResouce.shared.imageBy(key: skinKey) {
            itemView.imageView.image = image
        } else {
            itemView.imageView.image = EmotionResouce.placeholder
        }
    }
}
