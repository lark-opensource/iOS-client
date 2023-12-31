//
//  LarkNCExtensionEmotionCell.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/20.
//

import Foundation
import UIKit

/// EmotionHighlightCollectionCell
public protocol LarkNCExtensionEmotionHighlightCollectionCell {
    /// show the hightlight background needed
    func showHighlightedBackgroundView ()

    /// hide the hightlight background needed
    func hideHighlightedBackgroundView ()
}

final class LarkNCExtensionEmotionCell: UICollectionViewCell, LarkNCExtensionEmotionHighlightCollectionCell {

    private var emotionView: UIImageView = .init(image: nil)

    private var longPressGesture: UILongPressGestureRecognizer?
    private var highLightedBackgroundView = UIImageView()
    private var constraint: [NSLayoutConstraint] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)

        //禁用多指触控,当且仅当同时选择一个cell
        self.isExclusiveTouch = true

        // setup highlight backgroud
        self.contentView.addSubview(self.highLightedBackgroundView)
        self.highLightedBackgroundView.isHidden = true
        self.highLightedBackgroundView.image = UIImage(named: "emoji_bg_highlighted", in: Bundle(for: Self.self), compatibleWith: nil)
        self.highLightedBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            highLightedBackgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            highLightedBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            highLightedBackgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            highLightedBackgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        // 表情
        let emotionView = UIImageView()
        emotionView.isUserInteractionEnabled = false
        // setCellContnet会根据image.size计算出正确的显示size，设置scaleToFill让图片按照显示size进行展示
        emotionView.contentMode = .scaleToFill
        emotionView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(emotionView)
        self.emotionView = emotionView
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellContnet(_ emojiImage: UIImage?) {
        NSLayoutConstraint.deactivate(constraint)
        self.emotionView.image = emojiImage
        if let size = emojiImage?.size, size.height != 0 {

            constraint = [
                emotionView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                emotionView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                emotionView.widthAnchor.constraint(equalToConstant: 32 * size.width / size.height),
                emotionView.heightAnchor.constraint(equalToConstant: 32),
            ]
            NSLayoutConstraint.activate(constraint)
        }
        /// 数显刷新之后，回复选中状态
        self.hideHighlightedBackgroundView()
    }

    public func showHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = false
    }

    public func hideHighlightedBackgroundView () {
        self.highLightedBackgroundView.isHidden = true
    }
}
