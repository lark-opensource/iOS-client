//
//  FeedFilterListSectionHeader.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import Foundation
import UIKit
import LarkSwipeCellKit
import RxSwift
import SnapKit
import LarkBizAvatar
import LarkZoomable
import LarkSceneManager
import ByteWebImage
import RustPB
import LarkModel
import LarkBadge
import UniverseDesignDialog
import EENavigator
import LarkInteraction
import LarkMessengerInterface
import UniverseDesignColor
import LarkUIKit

protocol FeedFilterListSectionHeaderDelegate: AnyObject {
    func expandAction(_ header: FeedFilterListSectionHeader, type: Feed_V1_FeedFilter.TypeEnum, isExpanded: Bool)
    func selectAction(_ header: FeedFilterListSectionHeader, type: Feed_V1_FeedFilter.TypeEnum, _ tabIndex: Int)
}

final class FeedFilterListSectionHeader: UITableViewHeaderFooterView {
    static var identifier: String = "FeedFilterListSectionHeader"

    private var filterItemModel: FilterItemModel?
    private var sectionIndex: Int?
    private var selectState: Bool = false
    private var expand: Bool?

    public var highlightColor = UIColor.ud.fillHover
    public var selectedColor = UDMessageColorTheme.imFeedFeedFillActive
    weak var delegate: FeedFilterListSectionHeaderDelegate?

    private var backView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 6.0
        return view
    }()
    private let arrowImageView = UIImageView()
    private let arrowControlView = UIView()
    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private let separatorView = UIView()

    private static let downsampleSize = CGSize(width: 36, height: 36)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .right
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let bgColor = UIColor.ud.bgBody
        self.backgroundColor = bgColor

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(expandAction))
        arrowControlView.addGestureRecognizer(tapGes)
        let selectTapGes = UITapGestureRecognizer(target: self, action: #selector(selectAction))
        self.contentView.addGestureRecognizer(selectTapGes)
        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
        self.contentView.addGestureRecognizer(longPressGes)

        arrowImageView.image = Resources.sidebar_filtertab_expand
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.ud.title3

        separatorView.backgroundColor = UIColor.ud.lineDividerDefault
    }

    private func layout() {
        contentView.addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 1.0, left: 8.0, bottom: 1.0, right: 8.0))
        }

        contentView.addSubview(arrowControlView)
        arrowControlView.snp.makeConstraints { (make) in
            make.width.equalTo(58)
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
        }

        arrowControlView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.size.equalTo(14)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(27)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.arrowControlView.snp.right)
            make.top.bottom.equalToSuperview()
        }

        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(16)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }
    }

    func set(_ section: Int,
             _ filterItemModel: FilterItemModel,
             selectedType: Feed_V1_FeedFilter.TypeEnum,
             selectedId: String?,
             expand: Bool) {
        self.filterItemModel = filterItemModel
        self.sectionIndex = section
        self.expand = expand

        if let selectedId = selectedId, !selectedId.isEmpty {
            // 团队二级item已选中
            selectState = false
        } else if selectedType != .unknown {
            selectState = (filterItemModel.type == selectedType)
        } else {
            selectState = false
        }

        let remindUnreadCount = filterItemModel.unread
        let countStr = filterItemModel.unreadText
        badgeLabel.text = countStr
        badgeLabel.snp.remakeConstraints { make in
            make.left.equalTo(self.titleLabel.snp.right).offset(countStr.isEmpty ? 0 : 16)
            make.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }

        titleLabel.text = filterItemModel.name
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: (selectState || remindUnreadCount > 0) ? .medium : .regular)
        titleLabel.textColor = selectState ? UIColor.ud.textLinkHover :
                   (remindUnreadCount > 0) ? UIColor.ud.textTitle : UIColor.ud.textCaption

        layoutExpanded(expand)
        backView.backgroundColor = backgroundColor(false)
    }

    private func layoutExpanded(_ isExpanded: Bool) {
        self.separatorView.isHidden = true
        badgeLabel.isHidden = isExpanded
        let rotation = getRotation(isWillExpanded: isExpanded)
        UIView.animate(withDuration: 0.3, animations: {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }) { _ in
            if !isExpanded {
                self.separatorView.isHidden = false
            }
        }
    }

    private func getRotation(isWillExpanded: Bool) -> CGFloat {
        var targetRotation: CGFloat
        if isWillExpanded {
            // 将要展开
            targetRotation = 0

        } else {
            // 将要收起
            targetRotation = 1 * -(.pi / 2)
        }
        return targetRotation
    }

    @objc
    private func expandAction() {
        guard let type = filterItemModel?.type else { return }
        if let expand = expand {
            layoutExpanded(!expand)
            delegate?.expandAction(self, type: type, isExpanded: !expand)
        }
    }

    @objc
    private func selectAction() {
        guard let type = filterItemModel?.type else { return }
        if let sectionIndex = sectionIndex {
            delegate?.selectAction(self, type: type, sectionIndex)
        }
    }

    @objc
    private func longPressed(gesture: UILongPressGestureRecognizer) {
        if !Display.pad {
            if gesture.state == .began {
                backView.backgroundColor = backgroundColor(true)
            } else if gesture.state == .ended {
                selectAction()
            }
        }
    }

    func backgroundColor(_ highlighted: Bool) -> UIColor {
        var backgroundColor = UIColor.ud.fillHover
        if selectState {
            backgroundColor = self.selectedColor
        } else {
            backgroundColor = highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
        return backgroundColor
    }
}
