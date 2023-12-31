//
//  WidgetView+ActionHandler.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/2/5.
//

// MARK: Widget交互相关
/*------------------------------------------*/
//            widget交互相关
/*------------------------------------------*/
/// widget交互相关的操作
extension WidgetView {
    /// 得到最终的响应链接
    func handleHeaderClick() {
        if let link = widgetConfig?.mobileHeaderLinkUrl {
            Self.log.info("[\(widgetModel.name)] WidgetCard getRespondHeaderLink config") // 后期等待Logger能力接入统一支持排查link信息
            if let appID = meta?.uniqueID.appID {
                WPEventReport(
                    name: WPEvent.widget_icon_click.rawValue,
                    userId: userId,
                    tenantId: tenantId
                )
                .set(key: WPEventNewKey.appId.rawValue, value: appID).post()
            }
            headerClick?(link)
        } else {
            Self.log.info("[\(widgetModel.name)] WidgetCard getRespondHeaderLink nil")
            headerClick?(nil)
        }
    }
    /// widget 是否支持展开
    func supportExpand() -> Bool {
        guard let widgetConfig = self.widgetConfig else {
            Self.log.info("[\(widgetModel.name)] supportExpand widgetConfig is nil")
            return false
        }
        return widgetConfig.widgetCanExpand ?? false
    }
    /// 点击widget展开收起的回调
    func handleExpandClick(sender: UIButton) {
        Self.log.info("[\(widgetModel.name)] expand button click callback in widgetView")
        let expandType = widgetModel.widgetContainerState.isExpand ? "fold" : "expand"
        WPEventReport(
            name: WPEvent.origin_logevent_log_hourly.rawValue,
            userId: userId,
            tenantId: tenantId
        )
        .set(key: WPEventNewKey.appId.rawValue, value: "\(meta?.uniqueID.appID ?? "")")
            .set(key: "click_type", value: expandType)
            .post()

        let state = widgetModel.widgetContainerState
        // 取反更新state
        state.isExpand.toggle()
        state.isNeedChangeSizeForExpand = true
        state.saveWidgetView(widgetView: self)
        updateBizDataForExpand(state: state)  // 更新widget业务数据
    }
    /// 更新卡片尺寸（只接受来自展开收起的触发)
    func handleExpandSizeChange(expandSize: CGSize) {
        Self.log.info("[\(widgetModel.name)] expandSize update to \(expandSize)")
        /// 支持展开，并且尺寸和上一次的不同
        if supportExpand(),
           // 表示是展开收起触发的尺寸变化
           widgetModel.widgetContainerState.isNeedChangeSizeForExpand,
           // 如果尺寸发生了变化，则通知监听者，widget发生变化，外部根据变化调整列表的高度
           !widgetModel.widgetContainerState.expandSize.equalTo(expandSize) {
            let containerState = widgetModel.widgetContainerState
            containerState.isNeedChangeSizeForExpand = false
            widgetModel.cardSizeDidChange?(self, containerState, expandSize)
        } else {
            let isSizeChange = widgetModel.widgetContainerState.expandSize.equalTo(expandSize)
            let expandState = widgetModel.widgetContainerState.isExpand ? "expand" : "fold"
            WidgetView.log.info(
                "[\(widgetModel.name)] not change card size, isSizeChange: \(isSizeChange)",
                additionalData: ["expand state": expandState]
            )
        }
    }

    /// 更新卡片的expand的data
    private func updateCardExpandData() {
        let expandStateData = expandStateDic()
        updateCardData(widgetData: expandStateData)
        Self.log.info("[\(widgetModel.name)] widgetview update expand card data:\(expandStateData)")
    }
    /// 展开状态的信息（字典），如果当前不支持展开，那就是为空
    func expandStateDic() -> [String: Any] {
        let suppertExpand = supportExpand()
        guard suppertExpand else {
            Self.log.info("[\(widgetModel.name)] expandStateDic not support expand")
            return [:]
        }
        return widgetModel.widgetContainerState.getWidgetDataIndex(canExpand: suppertExpand)
    }
    /// 为展开/收起操作，单独更新业务数据
    func updateBizDataForExpand(state: WidgetContainerState) {
        guard supportExpand() else {
            Self.log.info("[\(widgetModel.name)] updateContainer not support expand")
            return
        }
        widgetModel.widgetContainerState = state
        navBar.setExpand(expand: state.isExpand)
        updateCardExpandData()  // 更新card展开收起的内容（对外叫widget，对内叫card）
    }
    /// 模拟展开收起的操作（for长按菜单触发）
    func simulateExpand() {
        Self.log.info("[\(widgetModel.name)] widgetview simulateExpand simulate click")
        handleExpandClick(sender: navBar.expandBtnHotView)
    }
}
