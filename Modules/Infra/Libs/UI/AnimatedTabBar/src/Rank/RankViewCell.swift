//
//  RankViewCell.swift
//  RankDemo
//
//  Created by bytedance on 2020/11/26.
//

import Foundation
import UIKit
import SnapKit
import FigmaKit
import LarkTab
import ByteWebImage
import UniverseDesignIcon
import LarkExtensions

enum RankEventType {
    case add(cell: RankViewCell) // 添加「更多」到「底部导航」
    case delete(cell: RankViewCell) // 移出「底部导航」
    case deleteThoroughly(cell: RankViewCell) // 直接从列表删除
}

final class RankViewCell: UITableViewCell {
    typealias RankEvent = (_ type: RankEventType) -> Void

    /// deleteButton是否处在展示状态
    var deleteButtonIsShowing: Bool = false
    private var rankEvent: RankEvent?

    // MARK: 视图组件
    /// 编辑图标，红删除、灰删除、绿加号
    private lazy var editIconButton: UIButton = UIButton()
    /// 内容容器
    private lazy var container: UIView = UIView()
    /// Cell的图标
    private lazy var logoView: UIImageView = UIImageView()
    /// Cell的图标的底
    private lazy var logoContainerView = SquircleView()
    /// Cell的标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// 删除按钮
    private lazy var deleteBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.hitTestEdgeInsets = .init(top: -10, left: -10, bottom: -10, right: -10)
        return btn
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: 视图设置
    /// 设置Cell视图组成
    private func setupViews() {
        // 直接赋值给cell.backgroundColor或backgroundView的话, 拖拽阴影会偏深
        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = UIColor.ud.bgFloat
        addSubview(backgroundColorView)
        sendSubviewToBack(backgroundColorView)
        backgroundColorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.addSubview(editIconButton)
        contentView.addSubview(container)

        logoContainerView.cornerRadius = 8.0
        logoContainerView.backgroundColor = UIColor.ud.bgFloat
        logoContainerView.borderWidth = 0.5
        logoContainerView.borderColor = UIColor.ud.lineBorderCard
        logoContainerView.addSubview(logoView)
        container.addSubview(logoContainerView)
        container.addSubview(titleLabel)
        container.addSubview(deleteBtn)

        editIconButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        container.snp.makeConstraints { (make) in
            make.height.centerY.equalToSuperview()
            make.left.equalTo(editIconButton.snp.right).offset(12)
            make.right.equalToSuperview()
        }
        logoContainerView.snp.makeConstraints { (make) in
            make.size.equalTo(32)
            make.centerY.left.equalToSuperview()
        }
        logoView.snp.makeConstraints { (make) in
            make.size.lessThanOrEqualTo(Config.iconSize)
            make.center.equalToSuperview()
        }
        deleteBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
            make.right.equalTo(-20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(logoContainerView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(deleteBtn.snp.left).offset(-12)
        }
    }

    func refresh(info: RankItem, isQuick: Bool, canDelete: Bool = false, rankEvent: RankEvent? = nil) {
        self.rankEvent = rankEvent
        titleLabel.text = info.name
        logoView.image = info.stateConfig.quickBarIcon
        let isCustomType = info.tab.isCustomType()
        logoView.layer.cornerRadius = isCustomType ? 6.0 : 0.0
        logoView.clipsToBounds = isCustomType
        deleteBtn.isHidden = !canDelete
        if isCustomType, let icon = info.tab.tabIcon {
            let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
            switch icon.type {
            case .udToken:
                logoView.image = UDIcon.getIconByString(icon.content) ?? placeHolder
            case .byteKey, .webURL:
                var resource: LarkImageResource
                if icon.type == .byteKey {
                    let (key, entityId) = icon.parseKeyAndEntityID()
                    resource = .avatar(key: key ?? "", entityID: entityId ?? "")
                } else {
                    resource = .default(key: icon.content)
                }
                logoView.bt.setLarkImage(resource, placeholder: placeHolder)
            @unknown default:
                break
            }
        } else if info.tab.appType != .native,
           let icon = info.tab.mobileRemoteSelectedIcon,
           !icon.isEmpty {
            // 远程图片确保加载出来显示到UI上
            logoView.bt.setImage(with: URL(string: icon))
        }
        logoView.snp.updateConstraints { (make) in
            make.size.lessThanOrEqualTo(Config.iconImageSize)
        }
        refreshEditButton(info: info, isQuick: isQuick, canDelete: canDelete)
    }

    func refreshEditButton(info: RankItem, isQuick: Bool, canDelete: Bool) {
        editIconButton.removeTarget(self, action: nil, for: .touchUpInside)
        if isQuick {
            editIconButton.setImage(Resources.AnimatedTabBar.quick_tab_btn_add, for: .normal)
            editIconButton.addTarget(self, action: #selector(addItem), for: .touchUpInside)
        } else if info.primaryOnly || info.unmovable {  // 不可移出主导航或置顶
            editIconButton.setImage(BundleResources.AnimatedTabBar.quick_tab_btn_uneditable, for: .normal)
        } else {
            editIconButton.setImage(Resources.AnimatedTabBar.quick_tab_btn_delete, for: .normal)
            editIconButton.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        }
        if canDelete {
            deleteBtn.setImage(UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UIColor.ud.iconN3), for: .normal)
            deleteBtn.addTarget(self, action: #selector(deleteThoroughlyItem), for: .touchUpInside)
            titleLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(logoContainerView.snp.right).offset(12)
                make.right.lessThanOrEqualTo(deleteBtn.snp.left).offset(-12)
            }
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(logoContainerView.snp.right).offset(12)
                if info.primaryOnly || info.unmovable {
                    make.right.equalToSuperview().offset(-48)
                } else {
                    make.right.lessThanOrEqualToSuperview()
                }
            }
        }
    }

    @objc
    private func addItem() {
        rankEvent?(.add(cell: self))
    }

    @objc
    private func deleteItem() {
        rankEvent?(.delete(cell: self))
    }

    @objc
    private func deleteThoroughlyItem() {
        rankEvent?(.deleteThoroughly(cell: self))
    }
}

/// cell 配置
extension RankViewCell {
    struct Config {
        static let identifier: String = "RankViewCell"
        static let cellHeight: CGFloat = 56
        static let iconSize: CGFloat = 32
        static let iconImageSize: CGFloat = 18
    }
}
