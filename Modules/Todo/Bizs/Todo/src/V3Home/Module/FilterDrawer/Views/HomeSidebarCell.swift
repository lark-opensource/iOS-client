//
//  HomeSidebarCell.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/19.
//

import Foundation
import UniverseDesignFont
import UniverseDesignIcon
import LarkDocsIcon

final class HomeSidebarCell: UICollectionViewCell {

    var viewData: HomeSidebarItemData? {
        didSet {
            guard let viewData = viewData else { return }
            let isSelected = viewData.isSelected
            if var buider = viewData.leadingIconBuilder, let userResolver = viewData.userResolver {
                leadingImageView.isHidden = false
                buider.iconExtend.placeHolderImage = isSelected ? UDIcon.getIconByKey(.tasklistFilled, iconColor: UIColor.ud.primaryContentDefault) : buider.iconExtend.placeHolderImage
                leadingImageView.di.setIconImage(iconBuild: buider, userResolver: userResolver)
            } else {
                leadingImageView.isHidden = true
            }
            contentView.backgroundColor = UIColor.ud.bgBody
            var defaultColor = UIColor.ud.iconN3
            switch viewData.category {
            case .subItem(let type):
                if case .inSection(_, let isLastItem) = type {
                    bottomFillView.isHidden = !isLastItem
                    contentView.backgroundColor = UIColor.ud.bgBodyOverlay
                } else {
                    bottomFillView.isHidden = true
                }
                layoutContainer(isNormal: false, hasLeadingIcon: !leadingImageView.isHidden, hasBottomFill: !bottomFillView.isHidden)
            case .normal:
                bottomFillView.isHidden = true
                layoutContainer(isNormal: true, hasLeadingIcon: true, hasBottomFill: false)
                defaultColor = UIColor.ud.iconN2
            }
            if viewData.isDefaultIcon {
                leadingImageView.image = leadingImageView.image?.ud.withTintColor(
                    isSelected ? UIColor.ud.primaryContentDefault : defaultColor
                )
            }

            titleLabel.text = viewData.title

            if let accessory = viewData.accessory {
                switch accessory {
                case .none:
                    accessoryLabel.isHidden = true
                    firstAccessoryImageView.isHidden = true
                    secondAccessoryImageView.isHidden = true
                case .icon(let archived, let more):
                    accessoryLabel.isHidden = true
                    firstAccessoryImageView.isHidden = false
                    if let archived = archived {
                        secondAccessoryImageView.isHidden = false
                        firstAccessoryImageView.image = archived
                        secondAccessoryImageView.image = more
                    } else {
                        secondAccessoryImageView.isHidden = true
                        firstAccessoryImageView.image = more
                    }
                case .count(let count):
                    accessoryLabel.isHidden = false
                    firstAccessoryImageView.isHidden = true
                    secondAccessoryImageView.isHidden = true
                    accessoryLabel.text = count
                }
            } else {
                accessoryLabel.isHidden = true
                firstAccessoryImageView.isHidden = true
                secondAccessoryImageView.isHidden = true
            }

            containerView.backgroundColor = isSelected ? UIColor.ud.fillActive : .clear
            titleLabel.font = isSelected ? UDFont.systemFont(ofSize: 16, weight: .medium) : UDFont.systemFont(ofSize: 16)
            titleLabel.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            accessoryLabel.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption
        }
    }

    var onTapAccessortyHandler: ((_ sourceView: UIView, _ containerGuid: String?, _ ref: Rust.TaskListSectionRef?) -> Void)?

    private lazy var containerView = UIView()
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    private lazy var leadingImageView = UIImageView()
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var accessoryLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 16)
        return label
    }()
    private lazy var tapView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickMore))
        view.addGestureRecognizer(tap)
        return view
    }()
    private lazy var firstAccessoryImageView = UIImageView()
    private lazy var secondAccessoryImageView = UIImageView()
    private lazy var bottomFillView = UIView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension HomeSidebarCell {

    private func setupSubviews() {
        contentView.addSubview(containerView)
        contentView.addSubview(bottomFillView)
        contentView.addSubview(tapView)
        containerView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(leadingImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(accessoryLabel)
        contentStackView.addArrangedSubview(firstAccessoryImageView)
        contentStackView.addArrangedSubview(secondAccessoryImageView)

        containerView.layer.cornerRadius = 6.0
        containerView.layer.masksToBounds = true
        layoutContainer(isNormal: true, hasLeadingIcon: true, hasBottomFill: false)
        leadingImageView.snp.makeConstraints { make in
            make.size.equalTo(HomeSidebarItemData.Config.leadingIconSize)
        }
        firstAccessoryImageView.snp.makeConstraints { make in
            make.size.equalTo(HomeSidebarItemData.Config.accessoryIconSize)
        }
        secondAccessoryImageView.snp.makeConstraints { make in
            make.size.equalTo(HomeSidebarItemData.Config.accessoryIconSize)
        }
        accessoryLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        firstAccessoryImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        secondAccessoryImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        tapView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.width.equalTo(64)
        }

        bottomFillView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(4)
            make.left.right.equalToSuperview()
        }
    }

    private func layoutContainer(isNormal: Bool, hasLeadingIcon: Bool, hasBottomFill: Bool) {
        if isNormal {
            containerView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                if hasBottomFill {
                    make.bottom.equalTo(bottomFillView.snp.top)
                } else {
                    make.bottom.equalToSuperview()
                }
            }
            contentStackView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(24)
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(1)
                make.left.equalToSuperview().offset(6)
                make.right.equalToSuperview().offset(-6)
                if hasBottomFill {
                    make.bottom.equalTo(bottomFillView.snp.top).offset(-1)
                } else {
                    make.bottom.equalToSuperview().offset(-1)
                }
            }
            contentStackView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                if hasLeadingIcon {
                    make.left.equalToSuperview().offset(28)
                } else {
                    make.left.equalToSuperview().offset(42)
                }
                make.right.equalToSuperview().offset(-12)
                make.height.equalTo(24)
            }
        }
    }

    @objc
    private func clickMore() {
        guard case .icon = viewData?.accessory else { return }
        onTapAccessortyHandler?(firstAccessoryImageView, viewData?.identifier, viewData?.category.ref)
    }
}

final class HomeSidebarHeaderView: UICollectionReusableView {

    var viewData: HomeSidebarHeaderData? {
        didSet {
            guard let viewData = viewData else { return }

            let hasDividingLine = viewData.category.hasDividingLine
            dividingLineView.isHidden = !hasDividingLine
            layoutContainer(hasDividingLine: hasDividingLine)

            if let leadingIcon = viewData.leadingIcon {
                leadingImageView.isHidden = false
                leadingImageView.image = leadingIcon
                leadingImageView.transform = viewData.isCollapsed ? CGAffineTransform.identity.rotated(by: -.pi / 2) : .identity
                leadingImageView.snp.remakeConstraints { make in
                    make.size.equalTo(leadingIcon.size)
                    make.center.equalToSuperview()
                }
            } else {
                leadingImageView.isHidden = true
            }

            titleLabel.text = viewData.title

            if let tailingIcon = viewData.tailingIcon {
                accessoryImageView.isHidden = false
                accessoryImageView.image = tailingIcon
                accessoryImageView.snp.remakeConstraints { make in
                    make.size.equalTo(tailingIcon.size)
                    make.center.equalToSuperview()
                }
            } else {
                accessoryImageView.isHidden = true
            }

            let isSelected = viewData.isSelected
            containerView.backgroundColor = isSelected ? UIColor.ud.fillActive : .clear
            backgroundView.backgroundColor = viewData.category.isSection ? UIColor.ud.bgBodyOverlay : UIColor.ud.bgBody
            leadingImageView.image = leadingImageView.image?.ud.withTintColor(
                isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN2
            )
            titleLabel.font = isSelected ? UDFont.systemFont(ofSize: 16, weight: .medium) : UIFont.systemFont(ofSize: 16)
            titleLabel.textColor = isSelected ? UIColor.ud.primaryContentDefault : (viewData.category.isAdd ? UIColor.ud.textCaption : UIColor.ud.textTitle)
        }
    }

    var onTapHeaderHandler: (() -> Void)?
    var onTapTailingViewHandler: ((_ sourceView: UIView, _ category: HomeSidebarHeaderData.Category) -> Void)?

    private(set) lazy var backgroundView = UIView()
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickContainer))
        view.addGestureRecognizer(tap)
        return view
    }()
    private lazy var dividingLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    private lazy var leadingContainer = UIView()
    private lazy var leadingImageView = UIImageView()
    private lazy var titleLabel = UILabel()
    // container for layout
    private lazy var accessoryContainer =  UIView()
    // for tap
    private lazy var tapView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAccessory))
        view.addGestureRecognizer(tap)
        return view
    }()
    // for display
    private lazy var accessoryImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(backgroundView)
        backgroundView.addSubview(dividingLineView)
        backgroundView.addSubview(containerView)
        backgroundView.addSubview(tapView)

        containerView.addSubview(leadingContainer)
        leadingContainer.addSubview(leadingImageView)
        containerView.addSubview(titleLabel)

        containerView.addSubview(accessoryContainer)
        accessoryContainer.addSubview(accessoryImageView)

        containerView.layer.cornerRadius = 6.0
        containerView.layer.masksToBounds = true

        backgroundView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        layoutContainer(hasDividingLine: true)

        leadingContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(HomeSidebarHeaderData.Config.leadingViewSize)
            make.centerY.equalToSuperview()
        }

        accessoryContainer.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(HomeSidebarHeaderData.Config.tailingViewSize)
        }

        tapView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(accessoryContainer.snp.left)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(leadingContainer.snp.right).offset(12)
            make.right.equalTo(accessoryImageView.snp.left).offset(-12)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutContainer(hasDividingLine: Bool) {
        if hasDividingLine {
            dividingLineView.snp.remakeConstraints { make in
                make.height.equalTo(1)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview()
            }
            containerView.snp.remakeConstraints { make in
                make.top.equalTo(dividingLineView.snp.bottom).offset(6)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            containerView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    @objc
    private func clickContainer() {
        onTapHeaderHandler?()
    }

    @objc
    private func clickAccessory() {
        guard let viewData = viewData else { return }
        onTapTailingViewHandler?(accessoryContainer, viewData.category)
    }

}

final class HomeSidebarFooterView: UICollectionReusableView {

}
