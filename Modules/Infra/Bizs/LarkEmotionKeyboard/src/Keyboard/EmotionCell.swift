//
//  EmotionCell.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkFloatPicker
import LarkFeatureGating
import LarkEmotion
import LKCommonsLogging

public protocol EmotionCellDelegate: AnyObject {
    func onSkinTonesDidSelectedKey(_ newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay)
    func getImageForKey(_ imageKey: String) -> UIImage?
}

final class EmotionCell: UICollectionViewCell, EmotionHighlightCollectionCell {

    private static let logger = Logger.log(EmotionCell.self, category: "Module.LarkEmotionKeyboard.EmotionCell")
    private var emotionView: UIImageView = .init(image: nil)
    private weak var delegate: EmotionCellDelegate?
    private var emojiEntity: ReactionEntity? {
        didSet {
            self.updateFloatPickerIfNeedWith(oldKey: oldValue?.selectSkinKey ?? "")
        }
    }

    /// 是否支持长按手势
    private var supportSkinTones = false {
        didSet {
            longPressGesture?.isEnabled = supportSkinTones
        }
    }

    private var longPressGesture: UILongPressGestureRecognizer?
    private var highLightedBackgroundView = UIImageView(image: Resources.emojiHighlightedBg)
    private var pickerManager: FloatPickerManager?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        // 禁用多指触控,当且仅当同时选择一个cell
        self.isExclusiveTouch = true

        // setup highlight background
        self.contentView.addSubview(self.highLightedBackgroundView)
        self.highLightedBackgroundView.isHidden = true
        self.highLightedBackgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        // 表情
        let emotionView = UIImageView()
        emotionView.isUserInteractionEnabled = false
        // setCellContnet会根据image.size计算出正确的显示size，设置scaleToFill让图片按照显示size进行展示
        emotionView.contentMode = .scaleToFill
        self.contentView.addSubview(emotionView)
        self.emotionView = emotionView
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gesture:)))
        gesture.minimumPressDuration = 0.4
        gesture.isEnabled = supportSkinTones
        gesture.name = emotionKeyboardHighPriorityGesture
        self.contentView.addGestureRecognizer(gesture)
        longPressGesture = gesture
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellContnet(_ emojiImage: UIImage?,
                        emojiEntity: ReactionEntity?,
                        delegate: EmotionCellDelegate?) {
        if let image = emojiImage {
            self.emotionView.image = image
        } else {
            Self.logger.error("EmotionCell: key = \(emojiEntity?.key) has no image!!! use palceholder image!!!")
            self.emotionView.image = EmotionResouce.placeholder.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), resizingMode: .stretch)
        }
        self.supportSkinTones = !(emojiEntity?.skinKeys.isEmpty ?? true)
        // 支持多肤色的话打个日志
        if self.supportSkinTones {
            let count = emojiEntity?.skinKeys.count ?? 0
            Self.logger.info("EmotionCell: key = \(emojiEntity?.key) skin_lens = \(count)")
        }
        self.emojiEntity = emojiEntity
        self.delegate = delegate
        if let size = emojiImage?.size, size.height != 0 {
            self.emotionView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.equalTo(32 * size.width / size.height)
                make.height.equalTo(32)
            }
        } else {
            self.emotionView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
                make.height.equalTo(32)
            }
        }
        /// 数据刷新之后，恢复选中状态
        self.hideHighlightedBackgroundView()
    }

    public func showHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = false
    }

    public func hideHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = true
    }

    private func updateFloatPickerIfNeedWith(oldKey: String?) {
        guard supportSkinTones else {
            return
        }

        if let entity = emojiEntity, !entity.skinKeys.isEmpty, oldKey != entity.selectSkinKey {
            /// 替换之前如果有floatView存在，需要移除
            pickerManager?.hideFloatPickerView()
            let config = FloatPickerConfig(avoidInsets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8),
                                           allItemCount: entity.skinKeys.count,
                                           selectedItemIdx: entity.skinKeys.firstIndex(of: entity.selectSkinKey) ?? 0,
                                           interactiveStyle: .tapAndSlide,
                                           contentOffset: 4)
            self.pickerManager = FloatPickerManager(config: config, delegate: self)
        }
    }
    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        pickerManager?.onLongPress(gesture: gesture)
    }
}

extension EmotionCell: FloatPickerManagerDelegate {

    public func didSelectedIndex(_ seletcedIdx: Int, allItemCount: Int, selectedWay: SelectedWay) {
        guard let entity = self.emojiEntity, entity.skinKeys.count == allItemCount else {
            return
        }
        self.delegate?.onSkinTonesDidSelectedKey(entity.skinKeys[seletcedIdx],
                                                 oldSkinKey: entity.selectSkinKey,
                                                 defaultKey: entity.key,
                                                 selectedWay: selectedWay)
    }

    /// 外界用来配置ItemView
    public func itemViewWillAppearForIndexItem(_ indexItem: FloatPickerIndexItem,
                                        itemView: FloatPickerDisplayItemView) {
        guard let entity = self.emojiEntity, indexItem.idx < entity.skinKeys.count else {
            return
        }
        itemView.imageView.image = self.delegate?.getImageForKey(entity.skinKeys[indexItem.idx]) ?? EmotionResouce.placeholder

    }
}
