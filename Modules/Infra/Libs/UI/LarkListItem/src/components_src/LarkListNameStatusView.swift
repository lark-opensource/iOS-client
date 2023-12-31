//
//  LarkListNameStatusView.swift
//  LarkListItem
//
//  Created by 姚启灏 on 2020/7/12.
//

import Foundation
import LarkTag
import UIKit

public final class LarkListNameStatusView: UIStackView {

    public let textContentView = UIStackView()

    public func setFocusTag(_ tagView: UIView?) {
        guard let index = textContentView.arrangedSubviews.firstIndex(of: focusView), index - 1 >= 0 else {
            focusView.isHidden = true
            return
        }
        // 取到 focusView 前一个 view，不直接取 nameLabel 是因为 Search 对结构做了改变，将 nameLabel 和 countLabel 封装了一层
        let prevView = textContentView.arrangedSubviews[index - 1]
        focusView.image = nil
        focusView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        focusView.snp.removeConstraints()
        if let tagView = tagView {
            focusView.isHidden = false
            focusView.addSubview(tagView)
            tagView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            focusView.isHidden = true
        }
    }

    public func setFocusIcon(_ icon: UIImage?) {
        guard let index = textContentView.arrangedSubviews.firstIndex(of: focusView), index - 1 >= 0 else {
            focusView.isHidden = true
            return
        }
        // 取到 focusView 前一个 view，不直接取 nameLabel 是因为 Search 对结构做了改变，将 nameLabel 和 countLabel 封装了一层
        let prevView = textContentView.arrangedSubviews[index - 1]
        focusView.image = icon
        focusView.snp.removeConstraints()
        focusView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        if let icon = icon {
            focusView.isHidden = false
        } else {
            focusView.isHidden = true
        }
    }

    public func setNameTag(_ tagView: TagWrapperView?) {
        guard let index = textContentView.arrangedSubviews.firstIndex(of: nameTag), index - 1 >= 0 else {
            nameTag.isHidden = true
            return
        }
        if let tagView = tagView {
            if tagView != nameTag {
                /// 如果不是之前的对象，remove后重新insert
                textContentView.removeArrangedSubview(nameTag)
                nameTag = tagView
                nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
                nameTag.setContentHuggingPriority(.required, for: .horizontal)
                textContentView.insertArrangedSubview(nameTag, at: index)
            }
        } else {
            nameTag.isHidden = true
        }
    }

    public lazy var nameLabel: ItemLabel = {
        let nameLabel = ItemLabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return nameLabel
    }()

    public lazy var focusView: UIImageView = {
        let imageView = UIImageView()
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return imageView
    }()

    public lazy var statusLabel: StatusLabel = {
        let statusLabel = StatusLabel()
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return statusLabel
    }()

    public lazy var timeLabel: LarkTimeLabel = {
        let timeLabel = LarkTimeLabel()
        timeLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        return timeLabel
    }()

    public lazy var nameTag: TagWrapperView = {
        let nameTag = TagWrapperView()
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        return nameTag
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)

        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 8

        textContentView.axis = .horizontal
        textContentView.alignment = .center
        textContentView.distribution = .fill
        textContentView.spacing = 8
        addArrangedSubview(textContentView)

        textContentView.addArrangedSubview(nameLabel)
        textContentView.addArrangedSubview(focusView)
        textContentView.addArrangedSubview(nameTag)
        textContentView.addArrangedSubview(timeLabel)
        textContentView.addArrangedSubview(statusLabel)

        setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        setContentHuggingPriority(.defaultLow - 1, for: .horizontal)

        focusView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        statusLabel.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(40)
        }
    }

    required public init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
