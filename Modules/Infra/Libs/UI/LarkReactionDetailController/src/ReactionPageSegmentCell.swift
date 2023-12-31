//
//  ReactionPageSegmentCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/12.
//

import Foundation
import UIKit
import SnapKit
import LarkPageController
import LarkEmotion

final class ReactionPageSegmentCell: PageSegmentCell {
    private let rectionHeight: CGFloat = 20
    override var isSelected: Bool {
        didSet {
            switchStyle()
        }
    }

    let wapperView: UIView = UIView()
    let reactionView: UIImageView = UIImageView()
    let countLabel: UILabel = UILabel()

    private var reactionKey: String? {
        didSet {
            let placeholder = EmotionResouce.placeholder
            let scale = rectionHeight / placeholder.size.height
            let scaledPlaceholder = placeholder.ud.scaled(by: scale)
            self.reactionView.image = scaledPlaceholder.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: rectionHeight/2, bottom: 0, right: rectionHeight/2), resizingMode: .stretch)
            if let reactionKey = reactionKey,
                let reactionImageFetcher = self.reactionImageFetcher {
                reactionImageFetcher(reactionKey) { [weak self] image in
                    if self?.reactionKey != reactionKey { return }
                    excuteInMain {
                        self?.reactionView.image = image
                    }
                }
            }
        }
    }

    var reactionImageFetcher: ((String, @escaping (UIImage) -> Void) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(wapperView)
        wapperView.addSubview(reactionView)
        wapperView.addSubview(countLabel)

        wapperView.clipsToBounds = true
        wapperView.layer.cornerRadius = 14
        wapperView.backgroundColor = UIColor.ud.bgBody
        wapperView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(28)
        }
        reactionView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().inset(8)
            maker.width.height.equalTo(self.rectionHeight)
        }

        countLabel.textColor = UIColor.ud.N600
        countLabel.font = UIFont.systemFont(ofSize: 17)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(reactionView.snp.right).offset(6)
            maker.right.equalToSuperview().inset(8)
        }

        wapperView.accessibilityIdentifier = "reaction.detail.segment.cell.wraper"
        countLabel.accessibilityIdentifier = "reaction.detail.segment.cell.countlabel"
        reactionView.accessibilityIdentifier = "reaction.detail.segment.cell.reactionview"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func switchStyle() {
        if isSelected {
            wapperView.backgroundColor = UIColor.ud.primaryContentDefault
            countLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        } else {
            wapperView.backgroundColor = UIColor.ud.N100
            countLabel.textColor = UIColor.ud.N600
        }
    }

    func set(reactionKey: String, count: Int) {
        self.reactionKey = reactionKey
        countLabel.text = "\(count)"
        if let size = EmotionResouce.shared.sizeBy(key: reactionKey) {
            let width = size.width / (size.height / self.rectionHeight)
            self.reactionView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        } else {
            self.reactionView.snp.updateConstraints { make in
                make.width.equalTo(self.rectionHeight)
            }
        }
        /// 这个需要更新一下被选中的背景色，目前线上有这个问题，默认颜色是白色，来回滑动变色
        switchStyle()
        setNeedsLayout()
    }
}
