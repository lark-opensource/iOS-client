//
//  BlockCell.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/2/19.
//

import UIKit
import ECOInfra
import UniverseDesignIcon
import LarkContainer
import LarkAccountInterface

protocol BlockCellDelegate: NSObjectProtocol {

    /// 标题区域点击回调
    /// - Parameters:
    ///   - cell: cell
    ///   - link: 标题跳转的链接参数
    func onTitleClick(_ cell: BlockCell, link: String?)

    /// 模板化 BlockHeader 操作按钮点击回调
    /// - Parameters:
    ///   - cell: cell
    ///   - link: 更多跳转的链接参数
    func onActionClick(_ cell: BlockCell)

    /// 内容区域长按手势回调
    /// - Parameter cell: cell
    func onLongPress(_ cell: BlockCell, gesture: UIGestureRecognizer)

    /// Block 加载失败
    func blockDidFail(_ cell: BlockCell, error: OPError)

    /// block 渲染成功
    func blockRenderSuccess(_ cell: BlockCell)

    /// Block 收到 Lynx log 回调
    func blockDidReceiveLogMessage(_ cell: BlockCell, message: WPBlockLogMessage)

    /// Block 内容尺寸发生变化
    /// - Parameters:
    ///   - cell: cell 实例
    ///   - newSize: 变化后的尺寸信息
    func blockContentSizeDidChange(_ cell: BlockCell, newSize: CGSize)

    func blockLongGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool

    func deleteItem(_ cell: UICollectionViewCell)

    func tryHideBlockCell(_ cell: BlockCell)
}

extension BlockCellDelegate {
    func blockLongGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func deleteItem(_ cell: UICollectionViewCell) {}

    func tryHideBlockCell(_ cell: BlockCell) {}
}

final class BlockCell: WorkplaceBaseCell {

    // MARK: - life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
		observeVCNotifications()
		subviewsInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

    // MARK: - override

    override func onBadgeUpdate() {
        // Not support yet
    }

    // MARK: - public

    // BlockCell 事件回调
    weak var delegate: BlockCellDelegate?

    var blockModel: BlockModel? {
        blockView?.blockModel
    }

    /// 是否处于可编辑态
    var isEditing: Bool = false

    /// 删除按钮
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.deleteNormalColorful), for: .normal)
        button.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        return button
    }()

    private var userResolver: UserResolver?

    @available(*, deprecated, message: "be compatible for monitor")
    var tenantId: String? {
        let userService = try? userResolver?.resolve(assert: PassportUserService.self)
        return userService?.userTenant.tenantID ?? ""
    }

    /// 更新 Cell 数据
    func updateData(
		_ data: BlockModel,
		hostVCShow: Bool,
		extraInfo: ExtraBlockInfo? = nil,
		isEditing: Bool = false,
		trace: OPTrace?,
		portalId: String? = nil,
		prefetchData: WPBlockPrefetchData? = nil,
        userResolver: UserResolver
    ) {
        // 更新 badge
        badgeKey = data.badgeKey
        self.isEditing = isEditing
        updateEditState(deleting: data.isDeletable && isEditing)

        // 更新 Block 内容视图
        if let view = blockView {
            guard view.blockModel != data else {
                // 如果是同一个 Block，不进行更新
                view.canShowRecommand = isEditing
                return
            }
            resetBlockView()
        }
        let view = WPBlockView(
            userResolver: userResolver,
            model: data,
            extraInfo: extraInfo,
            canShowRecommand: isEditing,
            trace: trace,
            portalId: portalId,
            prefetchData: prefetchData
        )
        view.delegate = self
        contentView.addSubview(view)
        contentView.clipsToBounds = false
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        blockView = view

        view.visible = visible
		view.blockVCShow = hostVCShow
        contentView.bringSubviewToFront(deleteButton)
    }

    func resetBlockView() {
        blockView?.removeFromSuperview()
        blockView?.delegate = nil
        blockView = nil
    }

    var visible: Bool = false {
        didSet {
            blockView?.visible = visible
        }
    }

    /// 获取标题是否内置
    func isTitleInner() -> Bool? {
        return blockView?.isInnerTitleStyle
    }

    /// 获取操作菜单选项
    func getActionMenuItems() -> [ActionMenuItem]? {
        return blockView?.getActionItems()
    }

    func getConsoleLogItems() -> [WPBlockLogMessage]? {
        return blockView?.getConsoleLogItems()
    }

    func clearConsoleLogItems() {
        blockView?.clearConsoleLogItems()
    }

    /// 操作菜单曝光上报
    func postActionMenuExpo() {
        if let blockModel = blockView?.blockModel {
            // 最新业务埋点（for 业务数据分析）
            WPEventReport(
                name: WPNewEvent.openplatformWorkspaceMainPageComponentExpoView.rawValue,
                userId: userResolver?.userID,
                tenantId: tenantId
            )
                .set(key: WPEventNewKey.type.rawValue, value: WPExposeUIType.blockMenu.rawValue)
                .set(key: WPEventNewKey.blockTypeId.rawValue, value: blockModel.blockTypeId)
                .set(key: WPEventNewKey.blockId.rawValue, value: blockModel.blockId)
                .set(key: WPEventNewKey.applicationId.rawValue, value: blockModel.appId)
                .set(key: WPEventNewKey.appName.rawValue, value: blockModel.title)
                .set(key: WPEventNewKey.menuCount.rawValue, value: getActionMenuItems()?.count ?? 0)
                .set(key: WPEventNewKey.host.rawValue, value: blockModel.isInTemplatePortal ? "template" : "old")
                .set(key: WPEventNewKey.isInFavoriteComponent.rawValue, value: blockModel.isInFavoriteComponent)
                .post()
            // 业务埋点上报（for 分享数据分析）
            WPEventReport(
                name: WPEvent.openplatform_workspace_appcard_action_menu_view.rawValue,
                userId: userResolver?.userID,
                tenantId: tenantId
            )
                .set(key: WPEventNewKey.applicationId.rawValue, value: blockModel.appId)
                .post()
        }
    }

    /// 获取iPad展示菜单的目标视图
    func getTargetViewForPad() -> UIView {
        return blockView?.targetViewForPad ?? contentView
    }

    /// 可编辑态
    func updateEditState(deleting: Bool) {
        deleteButton.isHidden = !deleting
    }

    func cellStartDragging() {
        deleteButton.isHidden = true
    }

    func cellEndDragging() {
        let showDeleteButton = (blockModel?.isDeletable ?? false) && isEditing
        deleteButton.isHidden = !showDeleteButton
    }

    private var blockView: WPBlockView?

    // MARK: - subviews

    private func subviewsInit() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(-5.2)
            make.right.equalToSuperview().offset(5.2)
            make.height.width.equalTo(19)
        }
        deleteButton.isHidden = true
    }

    @objc
    private func deleteItem() {
        delegate?.deleteItem(self)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden {
            return super.hitTest(point, with: event)
        }
        let deleteButtonFrame = deleteButton.frame.inset(by: UIEdgeInsets(
            top: -6,
            left: -6,
            bottom: -6,
            right: -6
        ))
        if deleteButtonFrame.contains(point) && !deleteButton.isHidden {
            return deleteButton
        }
        return super.hitTest(point, with: event)
    }
}

extension BlockCell: WPBlockViewDelegate {
    func onTitleClick(_ view: WPBlockView, link: String?) {
        delegate?.onTitleClick(self, link: link)
    }

    func onActionClick(_ view: WPBlockView) {
        delegate?.onActionClick(self)
    }

    func onLongPress(_ view: WPBlockView, gesture: UIGestureRecognizer) {
        delegate?.onLongPress(self, gesture: gesture)
    }

    func blockDidFail(_ view: WPBlockView, error: OPError) {
        delegate?.blockDidFail(self, error: error)
    }

    func blockRenderSuccess(_ view: WPBlockView) {
        delegate?.blockRenderSuccess(self)
    }

    func blockDidReceiveLogMessage(_ view: WPBlockView, message: WPBlockLogMessage) {
        delegate?.blockDidReceiveLogMessage(self, message: message)
    }

    func blockContentSizeDidChange(_ view: WPBlockView, newSize: CGSize) {
        delegate?.blockContentSizeDidChange(self, newSize: newSize)
    }

    func handleAPI(
        _ plugin: BlockCellPlugin,
        api: WPBlockAPI.InvokeAPI,
        param: [AnyHashable: Any],
        callback: @escaping WPBlockAPICallback
    ) {}

    func tryHideBlock(_ view: WPBlockView) {
        delegate?.tryHideBlockCell(self)
    }

    func longGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return delegate?.blockLongGestureShouldBegin(gestureRecognizer) ?? true
    }
}

// 接收vc的事件，通知block按需切换onShow.onHide状态
extension BlockCell {
	private func observeVCNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(hostVCDidAppear),
			name: WorkplaceViewControllerNotifiction.vcDidAppear.name,
			object: nil
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(hostVDidDisappear),
			name: WorkplaceViewControllerNotifiction.vcDidDisappear.name,
			object: nil
		)
	}
	@objc private func hostVCDidAppear() {
		blockView?.blockVCShow = true
	}
	@objc private func hostVDidDisappear() {
		blockView?.blockVCShow = false
	}
}

extension BlockCell : WorkPlaceCellExposeProtocol {
    var exposeId: String {
        blockModel?.item.itemId ?? ""
    }
    
    func didExpose() {
        guard let blockModel = blockView?.blockModel else { return }

        WPEventReport(
            name: WPNewEvent.openplatformWorkspaceMainPageComponentExpoView.rawValue,
            userId: userResolver?.userID,
            tenantId: tenantId
        )
            .set(key: WPEventNewKey.type.rawValue, value: WPExposeUIType.block.rawValue)
            .set(key: WPEventNewKey.blockTypeId.rawValue, value: blockModel.blockTypeId)
            .set(key: WPEventNewKey.blockId.rawValue, value: blockModel.blockId)
            .set(key: WPEventNewKey.applicationId.rawValue, value: blockModel.appId)
            .set(key: WPEventNewKey.appName.rawValue, value: blockModel.title)
            .set(
                key: WPEventNewKey.blockMode.rawValue,
                value: blockModel.isStandardBlock ? "standard" : "off_standard"
            )
            .set(
                key: WPEventNewKey.host.rawValue,
                value: blockModel.isInTemplatePortal ? "template" : "old"
            ).set(key: WPEventNewKey.isInFavoriteComponent.rawValue, value: blockModel.isInFavoriteComponent)
            .post()
    }
}
