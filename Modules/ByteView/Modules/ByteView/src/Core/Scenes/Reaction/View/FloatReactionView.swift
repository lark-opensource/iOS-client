//
//  FloatReactionView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/27.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewUI
import RichLabel
import UniverseDesignFont

/// 配置项 Reaction Display Mode 为 Float 类型时的表情气泡
class FloatReactionView: UIView {
    private static let maxNameWidth: CGFloat = 84 - 10
    private static let reactionHeight: CGFloat = 36
    private lazy var imageWidth = Self.reactionHeight
    private var senderName = ""
    private var count = 0
    private var reactionKey = "" {
        didSet {
            if reactionKey != oldValue {
                setNeedsLayout()
            }
        }
    }
    private static let lineHeight: CGFloat = 16
    private static let nameConfig = VCFontConfig(fontSize: 12, lineHeight: lineHeight, fontWeight: .regular)

    let bottomView: UIView = {
        let view = UIView()
        view.layer.ud.setShadow(type: .s4Down)
        view.layer.ud.setShadowColor(UIColor.ud.Y500)
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let nameContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.backgroundColor = UIColor.ud.Y100.withAlphaComponent(0.7)
        view.layer.borderColor = UIColor.ud.Y800.withAlphaComponent(0.08).cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        return view
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.Y800
        label.numberOfLines = 3
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    let reactionView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let countLabel = StrokeLabel()

    private let emotion: EmotionDependency
    init(emotion: EmotionDependency) {
        self.emotion = emotion
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForAnimation() {
        bottomView.alpha = 0
        alpha = 0
        reactionView.transform = CGAffineTransformMakeScale(0, 0)
    }

    func update(senderName: String, reactionKey: String, count: Int) {
        self.senderName = senderName
        self.count = count
        self.reactionKey = reactionKey
        nameLabel.attributedText = NSAttributedString(string: senderName, config: Self.nameConfig, alignment: .center, lineBreakMode: .byTruncatingTail, textColor: UIColor.ud.Y800)
        if let image = ExclusiveReactionResource.getExclusiveReaction(by: reactionKey) {
            reactionView.image = image
            updateReactionImage(image)
        } else  if let image = emotion.imageByKey(reactionKey) {
            reactionView.image = image
            updateReactionImage(image)
        } else if let imageKey = emotion.imageKey(by: reactionKey) {
            reactionView.vc.setReaction(imageKey) { [weak self] result in
                if case .success(let img) = result, let image = img {
                    self?.updateReactionImage(image)
                }
            }
        }

        if count > 1 {
            let config = Self.labelConfig(for: count)
            let font = UDFont.systemFont(ofSize: config.fontSize, weight: .semibold).boldItalic

            countLabel.text = "×\(count > 999 ? 999 : count)"
            countLabel.font = font
            countLabel.colors = config.colors
            countLabel.isHidden = false
        } else {
            countLabel.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.sizeToFit()
        let width = max(imageWidth, Self.maxNameWidth)
        if nameLabel.frame.width > width {
            let nameSize = senderName.vc.boundingSize(with: CGSize(width: width, height: .greatestFiniteMagnitude), config: Self.nameConfig)
            nameLabel.frame.size = nameSize
        }
        reactionView.frame = CGRect(x: (width - imageWidth) / 2, y: 0, width: imageWidth, height: Self.reactionHeight)
        bottomView.frame.size = CGSize(width: min(nameLabel.frame.width, Self.maxNameWidth) + 10, height: min(nameLabel.frame.height, 3 * Self.lineHeight) + 3)
        bottomView.frame.origin = CGPoint(x: (width - bottomView.frame.width) / 2, y: reactionView.frame.maxY + reactionLabelInset)
        nameContainer.frame = CGRect(x: 0, y: 0, width: bottomView.bounds.width, height: bottomView.bounds.height)
        nameLabel.center = CGPoint(x: nameContainer.frame.width / 2, y: nameContainer.frame.height / 2)

        if count > 0 {
            countLabel.sizeToFit()
            countLabel.frame.origin = CGPoint(x: reactionView.frame.maxX - 10.5, y: reactionView.frame.minY + 18 - countLabel.bounds.height)
        }

        bounds = CGRect(x: 0, y: 0, width: width, height: bottomView.frame.maxY)
    }

    // MARK: - Private

    private func setupSubviews() {
        layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        reactionView.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        addSubview(reactionView)
        addSubview(bottomView)
        bottomView.addSubview(nameContainer)
        nameContainer.addSubview(nameLabel)
        countLabel.clipsToBounds = false
        addSubview(countLabel)
    }

    private func updateReactionImage(_ image: UIImage) {
        imageWidth = image.size.width / image.size.height * Self.reactionHeight
        setNeedsLayout()
    }

    private var reactionLabelInset: CGFloat {
        // UX 强烈要求会议专属表情异化间距
        // nolint-next-line: magic number
        ExclusiveReactionResource.defaultKeys.contains(reactionKey) ? 2 : 5
    }

    // MARK: - Utils

    static func labelConfig(for reactionCount: Int) -> LabelConfig {
        // UX 暂定字体大小不随连击数改变，可能调整，因此先写在这里
        let fontSize: CGFloat = 18
        let colors: [UIColor]
        if reactionCount < 8 {
            colors = [UIColor.ud.primaryPri350, UIColor.ud.G350]
        } else if reactionCount < 15 {
            colors = [UIColor.ud.Y350, UIColor.ud.functionWarning400]
        } else {
            colors = [UIColor.ud.functionWarning400, UIColor.ud.functionDanger500]
        }
        return LabelConfig(colors: colors, fontSize: fontSize)
    }

    struct LabelConfig {
        let colors: [UIColor]
        let fontSize: CGFloat
    }
}
