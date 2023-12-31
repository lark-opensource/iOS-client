//
//  FloatReactionTipView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/10/13.
//

import UIKit
import UniverseDesignFont

final class FloatReactionTipView: UIView, ReactionTipView {
    private let horizontalInset: CGFloat = 12

    private lazy var reactionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var countLabel = StrokeLabel()

    private weak var sourceView: UIView?

    private var labelCountTransform: CGAffineTransform

    let emotion: EmotionDependency
    init(emotion: EmotionDependency) {
        self.emotion = emotion
        labelCountTransform = .identity
        super.init(frame: .zero)
        initView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initView() {
        backgroundColor = UIColor.ud.Y100.withAlphaComponent(0.9)
        layer.borderColor = UIColor.ud.Y800.withAlphaComponent(0.08).cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 22
        layer.masksToBounds = true

        addSubview(reactionImageView)
        addSubview(countLabel)
        countLabel.transform = labelCountTransform

        reactionImageView.snp.remakeConstraints { (make) in
            make.size.equalTo(28)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(horizontalInset)
        }
        countLabel.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(reactionImageView.snp.right).offset(4)
            make.right.equalToSuperview().inset(horizontalInset)
        }
    }

    func show(_ sourceView: UIView, reactionKey: String, with count: Int = 1) {
        if superview != nil {
            removeFromSuperview()
        }

        guard let window = UIApplication.shared.keyWindow, sourceView.window == window else {
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
            let config = FloatReactionView.labelConfig(for: count)
            let font = UDFont.systemFont(ofSize: config.fontSize, weight: .semibold).boldItalic
            countLabel.text = "×\(count)"
            countLabel.font = font
            countLabel.colors = config.colors

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
            self.countLabel.transform = countTransform
        }, completion: { _ in
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.1, animations: {
                self.countLabel.transform = self.labelCountTransform
            }, completion: nil)
        })
    }
}
