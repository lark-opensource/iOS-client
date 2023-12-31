//
//  ProfileExpandableView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/7.
//

import UIKit
import Foundation
import UniverseDesignIcon

typealias ExpandAllCallback = () -> Void

struct ExpandableItem {
    let content: String
    let contentColor: UIColor
    let tappedCallback: ItemTappedCallback?
    let expandStatus: ExpandStatus

    init(content: String,
         contentColor: UIColor = UIColor.ud.N500,
         tappedCallback: ItemTappedCallback? = nil,
         expandStatus: ExpandStatus) {
        self.content = content
        self.contentColor = contentColor
        self.tappedCallback = tappedCallback
        self.expandStatus = expandStatus
    }
}

final class ProfileExpandableView: UIView {

    enum Alignment {
        case left, right
    }

    var alignment: Alignment

    private let maxCount: Int // 超过多少后折叠
    private let font: UIFont
    private let items: [ExpandableItem]
    private var preferredMaxLayoutWidth: CGFloat = .infinity
    private var expandAll: Bool
    private let expandAllCallback: ExpandAllCallback?

    private lazy var expandButton: UIControl = {
        let view = UIControl()
        let label = UILabel()
        label.text = BundleI18n.LarkProfile.Lark_Legacy_ProfileDetailMore
        label.textColor = UIColor.ud.textLinkNormal
        label.font = font
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        let imageView = UIImageView(image: UDIcon.downOutlined.ud.withTintColor(UIColor.ud.textLinkNormal))
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(ProfileExpandableLabel.Cons.iconSize)
            make.left.equalTo(label.snp.right).offset(ProfileExpandableLabel.Cons.iconSpacing)
            make.right.equalToSuperview()
        }
        view.addTarget(self, action: #selector(tappedExpandAll), for: .touchUpInside)
        return view
    }()

    private var expandableLabels: [ProfileExpandableLabel] = []

    private lazy var labelsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Cons.itemSpacing
        stack.alignment = alignment == .left ? .leading : .trailing
        return stack
    }()

    init(items: [ExpandableItem],
         maxCount: Int = 5,
         font: UIFont = .systemFont(ofSize: 16),
         expandAll: Bool = false,
         alignment: Alignment = .left,
         preferredMaxLayoutWidth: CGFloat = -1,
         expandAllCallback: ExpandAllCallback? = nil) {
        self.maxCount = maxCount
        self.font = font
        self.items = items
        self.expandAll = expandAll
        self.alignment = alignment
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        self.expandAllCallback = expandAllCallback
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let hideExpandButton = (expandAll || items.count <= maxCount)
        addSubview(labelsContainer)
        if hideExpandButton {
            labelsContainer.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            addSubview(expandButton)
            labelsContainer.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
            }
            expandButton.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.top.equalTo(labelsContainer.snp.bottom).offset(Cons.itemSpacing)
                if alignment == .left {
                    make.leading.equalToSuperview()
                } else {
                    make.trailing.equalToSuperview()
                }
            }
        }
        bindItem()
    }

    private func makeExpandableLabel(for item: ExpandableItem) -> ProfileExpandableLabel {
        let label = ProfileExpandableLabel()
        label.font = font
        label.textColor = item.contentColor
        label.textAlignment = alignment == .left ? .left : .right
        label.set(expandStatus: item.expandStatus,
                  content: item.content,
                  preferredMaxLayoutWidth: preferredMaxLayoutWidth,
                  tappedCallback: item.tappedCallback
        )
        return label
    }

    private func bindItem() {
        labelsContainer.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        expandableLabels.removeAll()
        guard !items.isEmpty else { return }
        let maxCount = expandAll ? items.count : self.maxCount
        for (index, item) in items.enumerated() where index < maxCount {
            let label = makeExpandableLabel(for: item)
            labelsContainer.addArrangedSubview(label)
            expandableLabels.append(label)
            label.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.left.lessThanOrEqualToSuperview()
            }
        }
    }

    @objc
    private func tappedExpandAll() {
        expandAllCallback?()
    }
}

extension ProfileExpandableView {

    enum Cons {
        static var itemSpacing: CGFloat { 14 }
    }
}
