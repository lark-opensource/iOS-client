//
//  BubbleReactionTipView.swift
//  ByteView
//
//  Created by yangfukai on 2020/12/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignFont

protocol ReactionTipView: UIView {
    var count: Int { get set }
    init(emotion: EmotionDependency)
    func show(_ sourceView: UIView, reactionKey: String, with count: Int)
    func dismiss(animate: Bool)
}

final class BubbleReactionTipView: UIView, ReactionTipView {
    private let horizontalInset: CGFloat = 12

    private lazy var reactionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var countX: UDLabel = {
        let label = UDLabel()
        let font = UDFont.systemFont(ofSize: 20, weight: .semibold).boldItalic
        let offset = font.italicOffset()
        label.font = font
        label.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: offset)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        label.text = "x "
        return label
    }()

    private lazy var countLabel: UDLabel = {
        let label = UDLabel()
        let font = UDFont.systemFont(ofSize: 20, weight: .semibold).boldItalic
        let offset = font.italicOffset()
        label.font = font
        label.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: offset)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var countView: UIView = {
        let view = UIView()
        return view
    }()

    private weak var sourceView: UIView?

    private var labelCountTransform: CGAffineTransform

    let emotion: EmotionDependency
    init(emotion: EmotionDependency) {
        self.emotion = emotion
        // countLabel.transform.rotated(by: 0.192)
        labelCountTransform = .identity
        super.init(frame: .zero)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initView() {
        backgroundColor = UIColor.ud.vcTokenMeetingBgFeed
        layer.cornerRadius = 22
        layer.masksToBounds = true

        addSubview(reactionImageView)
        addSubview(countView)
        countView.addSubview(countX)
        countView.addSubview(countLabel)
        countView.transform = labelCountTransform

        reactionImageView.snp.remakeConstraints { (make) in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(horizontalInset)
        }
        countView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(reactionImageView.snp.right).offset(4)
            make.right.equalToSuperview().inset(horizontalInset)
        }
        countX.snp.remakeConstraints { (make) in
            make.centerY.left.equalToSuperview()
            make.width.equalTo(11)
        }
        countLabel.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(countX.snp.right)
            make.right.equalToSuperview()
            make.width.equalTo(0)
        }
    }

    func show(_ sourceView: UIView, reactionKey: String, with count: Int = 1) {
        if superview != nil {
            removeFromSuperview()
        }

        guard let window = sourceView.window else {
            return
        }

        window.addSubview(self)

        if let image = ExclusiveReactionResource.getExclusiveReaction(by: reactionKey) {
            setReactionImage(image)
        } else if let image = self.emotion.imageByKey(reactionKey) {
            setReactionImage(image)
        } else if let imageKey = self.emotion.imageKey(by: reactionKey) {
            Logger.ui.debug("tipView emotion dict has't reaction: \(reactionKey)")
            reactionImageView.vc.setReaction(imageKey, completion: { [weak self] result in
                guard let self = self, case .success(let r) = result, let image = r else { return }
                self.setReactionImage(image)
            })
        }

        alpha = 1
        snp.remakeConstraints { (make) in
            make.height.equalTo(44)
            make.bottom.equalTo(sourceView.snp.top).offset(-10)
            make.centerX.equalTo(sourceView).priority(.low)
            make.left.greaterThanOrEqualTo(window.safeAreaLayoutGuide).inset(8)
            make.right.lessThanOrEqualTo(window.safeAreaLayoutGuide).inset(8)
        }
        self.count = count
    }

    private func setReactionImage(_ image: UIImage) {
        reactionImageView.image = image
        let height: CGFloat = 28
        let width = image.size.height == 0 ? 28 : (image.size.width / image.size.height * height)
        reactionImageView.snp.remakeConstraints { make in
            make.height.equalTo(height)
            make.width.equalTo(width)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(horizontalInset)
        }
    }

    func dismiss(animate: Bool = true) {
        if animate {
            animateOut()
        } else {
            removeFromSuperview()
        }
    }

    var count: Int = 0 {
        didSet {
            countLabel.text = "\(count)"
            countLabel.snp.remakeConstraints { (make) in
                make.centerY.right.equalToSuperview()
                make.left.equalTo(countX.snp.right)
            }
            animateZoom()
        }
    }

    private func animateOut() {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    private func animateZoom() {
        let countTransform = labelCountTransform.scaledBy(x: 1.1, y: 1.1)
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.1, animations: {
            self.countView.transform = countTransform
        }, completion: { _ in
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.1, animations: {
                self.countView.transform = self.labelCountTransform
            }, completion: nil)
        })
    }
}

private extension NSInteger {
    /// 获取整形数字的位数
    func getDigit() -> NSInteger {
        var counter = 0
        var tempNumber = self
        while tempNumber != 0 {
            tempNumber = (NSInteger)(tempNumber / 10)
            counter += 1
        }
        return counter
    }
}
