//
//  ReactionCell.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/6/6.
//

import UIKit
import ByteViewUI
import ByteViewSetting

protocol ReactionCellDelegate: AnyObject {
    func reactionCell(_ cell: UIView, didBeginLongPress gestureRecognizer: UILongPressGestureRecognizer, with reactionKey: String)
}

class ReactionCell: UICollectionViewCell {
    private static let defaultSize: CGFloat = 28
    private static let exclusiveSize: CGFloat = 30
    private static var exclusiveReactions: [String: UIImage] = [:]

    let iconView: UIImageView = {
        let view = UIImageView()
        // 手动设置 reactionKey 后会根据表情的实际大小计算出正确的尺寸，因此这里设置 contentMode 让图片能完全展示即可
        view.contentMode = .scaleToFill
        view.accessibilityLabel = "vc.reaction.cell.icon"
        return view
    }()
    var emotion: EmotionDependency?
    weak var delegate: ReactionCellDelegate?

    var reactionKey: String = "" {
        didSet {
            guard !reactionKey.isEmpty else { return }
            if let image = ExclusiveReactionResource.getExclusiveReaction(by: reactionKey) {
                iconView.image = image
                iconView.snp.updateConstraints { make in
                    make.width.equalTo(Self.exclusiveSize * image.size.width / image.size.height)
                    make.height.equalTo(Self.exclusiveSize)
                }
            } else if let image = emotion?.imageByKey(reactionKey) {
                iconView.image = image
                iconView.snp.updateConstraints { make in
                    make.width.equalTo(Self.defaultSize * image.size.width / image.size.height)
                    make.height.equalTo(Self.defaultSize)
                }
            } else if let imageKey = emotion?.imageKey(by: reactionKey) {
                Logger.ui.debug("reactionCell emotion dict has't reaction: \(reactionKey)")
                iconView.vc.setReaction(imageKey, completion: { [weak self] result in
                    if let icon = result.value, let size = icon?.size, size.height != 0 {
                        self?.iconView.image = icon
                        self?.iconView.snp.updateConstraints { make in
                            make.width.equalTo(Self.defaultSize * size.width / size.height)
                            make.height.equalTo(Self.defaultSize)
                        }
                    } else {
                        self?.iconView.snp.updateConstraints { make in
                            make.width.height.equalTo(Self.defaultSize)
                        }
                    }
                })
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.clipsToBounds = false
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Self.defaultSize)
        }

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.cancelsTouchesInView = false
        contentView.addGestureRecognizer(longPressGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Actions

    @objc
    private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        delegate?.reactionCell(self, didBeginLongPress: gestureRecognizer, with: reactionKey)
    }
}
