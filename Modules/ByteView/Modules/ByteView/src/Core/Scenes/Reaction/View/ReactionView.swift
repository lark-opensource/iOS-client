//
//  ReactionView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/9/2.
//

import UIKit

protocol ReactionViewDelegate: AnyObject {
    func reactionView(_ view: ReactionView, didClickReaction reactionKey: String)
    func reactionView(_ view: ReactionView, didBeginLongPress recognizer: UILongPressGestureRecognizer, with reactionKey: String)
}

// 用于 iPad toolbar 上展示表情
class ReactionView: UIView {
    private static let defaultSize: CGFloat = 24
    let iconView: UIImageView = {
        let view = UIImageView()
        // 手动设置 reactionKey 后会根据表情的实际大小计算出正确的尺寸，因此这里设置 contentMode 让图片能完全展示即可
        view.contentMode = .scaleToFill
        view.accessibilityLabel = "vc.reaction.cell.icon"
        return view
    }()
    lazy var reactionSize = CGSize(width: Self.defaultSize, height: Self.defaultSize) {
        didSet {
            if reactionSize != oldValue {
                invalidateIntrinsicContentSize()
            }
        }
    }
    var emotion: EmotionDependency?
    weak var delegate: ReactionViewDelegate?
    var verticalInset: CGFloat = 0

    var reactionKey: String = "" {
        didSet {
            guard !reactionKey.isEmpty else { return }

            if let image = emotion?.imageByKey(reactionKey) {
                iconView.image = image
                reactionSize = CGSize(width: Self.defaultSize * image.size.width / image.size.height, height: Self.defaultSize)
            } else if let imageKey = emotion?.imageKey(by: reactionKey) {
                Logger.ui.debug("reactionCell emotion dict has't reaction: \(reactionKey)")
                iconView.vc.setReaction(imageKey, completion: { [weak self] result in
                    if let icon = result.value, let size = icon?.size, size.height != 0 {
                        self?.iconView.image = icon
                        self?.reactionSize = CGSize(width: Self.defaultSize * size.width / size.height, height: Self.defaultSize)
                    } else {
                        self?.reactionSize = CGSize(width: Self.defaultSize, height: Self.defaultSize)
                    }
                })
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addInteraction(type: .lift)
        backgroundColor = .clear
        clipsToBounds = false
        addSubview(iconView)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.cancelsTouchesInView = false
        addGestureRecognizer(longPressGesture)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame.size = intrinsicContentSize
        iconView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    override var intrinsicContentSize: CGSize { reactionSize }

    // MARK: Actions

    @objc
    private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        delegate?.reactionView(self, didBeginLongPress: gestureRecognizer, with: reactionKey)
    }

    @objc
    private func handleClick() {
        delegate?.reactionView(self, didClickReaction: reactionKey)
    }
}
