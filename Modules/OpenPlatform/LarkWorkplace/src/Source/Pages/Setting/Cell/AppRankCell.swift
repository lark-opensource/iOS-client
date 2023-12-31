//
//  AppRankCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/18.
//

import Foundation
import LarkUIKit
import UIKit
import SnapKit
import LarkInteraction
import UniverseDesignShadow
import UniverseDesignTag

final class DeleteBarView: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 工作台-排序页面的单个Cell
final class AppRankCell: UICollectionViewCell {
    /// cell 配置
    enum AppRankCellConfig {
        static let cellHeight: CGFloat = 56
        static let cellID: String = "AppRankCell"
        /// 删除滑块的宽度
        static let removeBarWidth: CGFloat = 70
    }
    /// tag字体大小
    let tagFontSize: CGFloat = 11.0
    /// 屏幕间距
    let screenMargin: CGFloat = 16.0
    /// 一般view的间距（排序页Cell的视图通用设计）
    let commonMargin: CGFloat = 12.0
    /// 点击delete回调事件
    var deleteEvent: ((_ cell: AppRankCell, _ isDeleted: Bool) -> Void)?
    /// 是否准备删除
    var isDeleting: Bool = false

    private static let tagMaxWidth: CGFloat = 74.0

    // MARK: 视图组件
    /// 删除图标
    private lazy var deleteIconView: UIButton = {
        let deleteIcon = UIButton()
        deleteIcon.setImage(Resources.rank_delete, for: .normal)
        deleteIcon.addTarget(self, action: #selector(showDeleteBar), for: .touchUpInside)
        return deleteIcon
    }()
    /// 排序图标
    private lazy var sortView: UIImageView = {
        let sortIcon = UIImageView()
        sortIcon.image = Resources.rank_drag.ud.withTintColor(UIColor.ud.iconN3)
        return sortIcon
    }()
    /// 内容容器
    private lazy var container: UIView = {
        return UIView()
    }()

    /// 拖动区域
    private lazy var dragView: UIView = {
        return UIView()
    }()

    /// Cell的图标
    private lazy var logoView: WPMaskImageView = {
        let logoView = WPMaskImageView()
        logoView.backgroundColor = UIColor.clear
        logoView.clipsToBounds = true
        return logoView
    }()
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
    /// Cell的标签
    private lazy var tagView: UDTag = {
        UDTag(text: "", textConfig: UDTagConfig.TextConfig())
    }()
    /// 分割线-bottom
    private lazy var bottomDividerLine: UIView = {
        let deviderLine = UIView()
        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
        return deviderLine
    }()
    /// 标识应用相关单元格位置
    private var position: AppCollectionCellPosition = .middle
    /// 删除确认块
    private lazy var deleteBar: DeleteBarView = {
        let removeBar = DeleteBarView(frame: CGRect(
            x: self.contentView.bdp_width,
            y: self.contentView.bdp_origin.y,
            width: AppRankCellConfig.removeBarWidth,
            height: AppRankCellConfig.cellHeight
        ))
        removeBar.backgroundColor = UIColor.ud.functionDangerContentDefault
        removeBar.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveBttn, for: .normal)
        removeBar.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        removeBar.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        // swiftlint:enable init_font_with_token
        removeBar.addTarget(self, action: #selector(handleDeleteEvent), for: .touchUpInside)
        return removeBar
    }()

    // MARK: cell 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraint()
        setKeyMouseEffect()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: 视图设置
    /// 设置Cell视图组成
    private func setupViews() {
        layer.masksToBounds = true
        layer.cornerRadius = 10.0
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(dragView)
        contentView.addSubview(bottomDividerLine)
        dragView.addSubview(container)
        dragView.addSubview(deleteIconView)
        dragView.addSubview(sortView)
        container.addSubview(logoView)
        container.addSubview(titleLabel)
        container.addSubview(tagView)
    }
    /// 展示移除操作块
    @objc
    private func showDeleteBar() {
        if isDeleting {
            return
        }
        // 划出删除块
        if deleteBar.superview == nil {
            contentView.addSubview(deleteBar)
        }
        UIView.animate(withDuration: 0.4, animations: { [weak self] in
            /// 子view的frame没有改变，导致点击区域和可见区域对不上，点击事件不生效，通过hitTest进行拦截转发
            self?.contentView.bounds.origin.x += AppRankCellConfig.removeBarWidth
        })
        deleteEvent?(self, false)
        isDeleting = true
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let deleteBarRect = CGRect(
            x: self.contentView.frame.width - AppRankCellConfig.removeBarWidth,
            y: 0,
            width: AppRankCellConfig.removeBarWidth,
            height: self.contentView.frame.height
        )
        if isDeleting, deleteBarRect.contains(point) {
            return deleteBar
        }
        return super.hitTest(point, with: event)
    }
    /// 隐藏移除操作块
    func hideDeleteBar() {
        if isDeleting {
            UIView.animate(
                withDuration: 0.4,
                animations: { [weak self] in
                    self?.contentView.bounds.origin.x -= AppRankCellConfig.removeBarWidth
                },
                completion: { [weak self] (_) in
                    self?.deleteBar.removeFromSuperview()
                }
            )
            isDeleting = false
        }
    }
    /// 点击移除bar，执行删除的回调事件
    @objc
    private func handleDeleteEvent() {
        deleteEvent?(self, true)
    }
    /// 设置Cell内容视图的约束视图约束
    private func setupConstraint() {
        dragView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        deleteIconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(screenMargin)
        }
        sortView.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-screenMargin)
        }
        bottomDividerLine.snp.makeConstraints { make in
            make.height.equalTo(WPUIConst.BorderW.pt0_5)
            make.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel)
        }
        container.snp.makeConstraints { (make) in
            make.height.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(commonMargin)
            make.right.equalToSuperview()
        }
        logoView.sqRadius = WPUIConst.AvatarRadius.small
        logoView.sqBorder = WPUIConst.BorderW.pt1
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(WPUIConst.AvatarSize.small)
            make.centerY.left.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(logoView.snp.right).offset(commonMargin)
        }
        tagView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.width.lessThanOrEqualTo(Self.tagMaxWidth)
            make.right.lessThanOrEqualToSuperview().inset(commonMargin)
            make.left.equalTo(titleLabel.snp.right).offset(8)
        }
    }
    /// 适配键鼠动效
    private func setKeyMouseEffect() {
        deleteIconView.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (
                        CGSize(
                            width: size.width + highLightIconWidthMargin,
                            height: size.height + highLightIconHeightMargin
                        ),
                        highLightCorner
                    )
                }
            )
        )
        sortView.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (
                        CGSize(
                            width: size.width + highLightIconWidthMargin,
                            height: size.height + highLightIconHeightMargin
                        ),
                        highLightCorner
                    )
                }
            )
        )
    }
    /// 更新约束
    /// - Parameter isEditable: 是否是编辑模式
    private func updateEditConstraint(isDeletable: Bool, isSortable: Bool) {
        if isDeletable && isSortable {
            deleteIconView.isHidden = false
            sortView.isHidden = false
            container.snp.remakeConstraints { (make) in
                make.height.centerY.equalToSuperview()
                make.left.equalTo(deleteIconView.snp.right).offset(commonMargin)
                make.right.equalTo(sortView.snp.left)
            }
        } else if isDeletable {
            deleteIconView.isHidden = false
            sortView.isHidden = true
            container.snp.remakeConstraints { (make) in
                make.height.centerY.equalToSuperview()
                make.left.equalTo(deleteIconView.snp.right).offset(commonMargin)
                make.right.equalToSuperview()
            }
        } else {
            deleteIconView.isHidden = true
            sortView.isHidden = true
            container.snp.remakeConstraints { (make) in
                make.height.centerY.equalToSuperview()
                make.left.equalToSuperview().offset(screenMargin)
                make.right.equalToSuperview()
            }
        }
    }

    /// 设置Cell视图Tag约束（满足tag动态要求）
    private func updateTagConstraint() {
        if tagView.isHidden, let spview = tagView.superview {
            tagView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.height.equalTo(18)
                make.width.lessThanOrEqualTo(Self.tagMaxWidth)
                make.left.lessThanOrEqualTo(spview.snp.right)
                make.left.equalTo(titleLabel.snp.right).offset(4)
            }
        } else {
            tagView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.height.equalTo(18)
                make.width.lessThanOrEqualTo(Self.tagMaxWidth)
                make.right.lessThanOrEqualToSuperview().inset(commonMargin)
                make.left.equalTo(titleLabel.snp.right).offset(4)
            }
        }
    }
    /// 复用视图刷新（依赖于section，不能直接通过itemInfo判断类型）
    func refresh(
        itemInfo: RankItem,
        sortable: Bool,
        tagType: WPCellTagType,
        deleteEvent: ((_ cell: AppRankCell, _ isDeleted: Bool) -> Void)?,
        position: AppCollectionCellPosition = .middle
    ) {
        logoView.bt.setLarkImage(with: .avatar(
            key: itemInfo.iconKey,
            entityID: "",
            params: .init(sizeType: .size(avatarSideS))
        ))
        titleLabel.text = itemInfo.name
        tagView.wp_updateType(tagType)
        self.deleteEvent = deleteEvent
        updateTagConstraint()
        let deletable: Bool = deleteEvent != nil
        updateEditConstraint(isDeletable: deletable, isSortable: sortable)
        refreshDividlineShowStatus(by: position)
    }

    /// 仿照UITableView.separatorColor来显示下划线
    func refreshDividlineShowStatus(by position: AppCollectionCellPosition) {
        switch position {
        case .top:
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            bottomDividerLine.isHidden = false
        case .middle:
            layer.maskedCorners = []
            bottomDividerLine.isHidden = false
        case .bottom:
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            bottomDividerLine.isHidden = true
        case .topAndBottom:
            bottomDividerLine.isHidden = true
            layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
        }
    }
    /// 拖动开始请调用这个方法
    func startDrag() {
        alpha = 0
        contentView.alpha = 0
        isHidden = true
        contentView.isHidden = true
    }
    /// 拖动结束或者取消请调用这个方法
    func endDrag() {
        alpha = 1
        contentView.alpha = 1
        isHidden = false
        contentView.isHidden = false
    }
    /// 获取拖动时的item快照
    func getDargView() -> UIView? {
        guard let snapShotView = self.dragView.snapshotView(afterScreenUpdates: false) else {
            return nil
        }
        /// 去除分割线
        let cellFrame = snapShotView.frame
        let dragView = UIView(frame: cellFrame)
        dragView.addSubview(snapShotView)
        dragView.backgroundColor = UIColor.ud.bgBody
        dragView.layer.ud.setShadow(type: .s4Down)
        return dragView
    }
}
