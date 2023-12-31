//
//  WPBlockView+Monitor.swift
//  LarkWorkplace
//
//  Created by doujian on 2022/7/1.
//

import LarkWorkplaceModel

extension WPBlockView {
    /// 区分 Block 的基本信息，用于日志
    var identityInfo: [String: String] {
        [
            "app_name": self.blockModel.title,
            "app_id": self.blockModel.appId,
            "block_id": self.blockModel.blockId,
            "block_type_id": self.blockModel.blockTypeId
        ]
    }

    /// Block 开始加载，初始化 Monitor
    func monitor_setup(forceUpdate: Bool) {
        blockLoadStartDate = Date()
        WPMonitor().setCode(WPMCode.workplace_block_start_mount)
            .setTrace(blockTrace)
            .setInfo(identityInfo)
            .setInfo(forceUpdate, key: "force_update")
            .flush()
    }

    /// Block 展示成功状态
    func monitor_blockShowContent(useStartLoading: Bool) {
        let cost = Int(Date().timeIntervalSince(blockLoadStartDate) * 1_000)
        var info = ["use_start_loading": useStartLoading, "duration": cost]
            .merging(retryAction.monitorInfo ?? [:], uniquingKeysWith: { $1 })
        if !enableBlockitTimeoutOptimize {
            info = info.merging(
                ["blockit_timeout": blockitTimeout, "block_biz_timeout": blockBizTimeout],
                uniquingKeysWith: { $1 }
            )
        }
        WPMonitor().setCode(WPMCode.workplace_block_show_content)
            .setInfo(identityInfo)
            .setTrace(self.blockTrace)
            .setResult(.success())
            .setInfo(info)
            .flush()
        self.delegate?.blockRenderSuccess(self)
        /// 使用loading时，渲染结束点
    }

    /// Block 展示失败状态
    func monitor_blockShowFail(_ additonalInfo: [String: Any]) {
        let cost = Int(Date().timeIntervalSince(blockLoadStartDate) * 1_000)
        var monitorInfo = ["duration": cost, "use_start_loading": blockSettings?.useStartLoading ?? false]
            .merging(additonalInfo, uniquingKeysWith: { $1 })
            .merging(retryAction.monitorInfo ?? [:], uniquingKeysWith: { $1 })
        if !enableBlockitTimeoutOptimize {
            monitorInfo = monitorInfo.merging(
                ["blockit_timeout": blockitTimeout, "block_biz_timeout": blockBizTimeout],
                uniquingKeysWith: { $1 }
            )
        }
        WPMonitor().setCode(WPMCode.workplace_block_show_fail)
            .setInfo(identityInfo)
            .setTrace(self.blockTrace)
            .setResult(.fail())
            .setInfo(monitorInfo)
            .flush()
    }

    func monitor_blockAPIInvoke(_ api: WPBlockAPI.InvokeAPI) {
        WPMonitor().setInfo(identityInfo)
            .setCode(WPMCode.workplace_block_invoke_api)
            .setTrace(self.blockTrace)
            .setInfo(api.rawValue, key: "api_type")
            .flush()
    }

    func monitorHideBlockLoading() {
        var blockStatus: BlockStatus = .loading
        switch self.stateView.state {
        case .running:
            blockStatus = .success
        case .loading:
            blockStatus = .loading
        case .loadFail,
                .updateTip:
            blockStatus = .error
        }
        var timerStatus: TimerStatus = .none
        if let timer = self.loadingTimer {
            timerStatus = timer.isValid ? .valid : .invalid
        }
        WPMonitor().setCode(WPMCode.workplace_block_receive_hide_loading)
            .setTrace(blockTrace)
            .setInfo(identityInfo)
            .setInfo([
                "block_status": blockStatus.rawValue,
                "timer_status": timerStatus.rawValue,
                "use_start_loading": blockSettings?.useStartLoading ?? false
            ])
            .flush()
    }

    func monitor_trace(
        error: Error? = nil,
        info: [String: Any]? = nil,
        fileName: String = #fileID,
        functionName: String = #function,
        line: Int = #line
    ) {
        let monitor = WPMonitor()
            .setCode(WPMCode.workplace_block_trace)
            .setInfo(identityInfo)
            .setTrace(self.blockTrace)
        if let err = error {
            monitor.setResult(.fail(err))
        }
        if let info = info {
            monitor.setInfo(info)
        }
        // Warn 以下级别日志不会上报这些字段，这里手动添加一下
        monitor.setInfo(functionName, key: "wp_func")
        monitor.setInfo(line, key: "wp_line")

        monitor.flush(
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    func monitor_blockLaunchCancel() {
        WPMonitor().setInfo(identityInfo)
            .setCode(WPMCode.workplace_block_mount_cancel)
            .setTrace(self.blockTrace)
            .flush()
    }

    func event_blockClick(_ type: WPClickValue) {
        WPEventReport(
            name: WPNewEvent.openplatformWorkspaceMainPageClick.rawValue,
            userId: userResolver.userID,
            tenantId: tenantId
        )
            .set(key: WPEventNewKey.click.rawValue, value: type.rawValue)
            .set(key: WPEventNewKey.target.rawValue, value: WPTargetValue.none.rawValue)
            .set(key: WPEventNewKey.blockTypeId.rawValue, value: blockModel.blockTypeId)
            .set(key: WPEventNewKey.blockId.rawValue, value: blockModel.blockId)
            .set(key: WPEventNewKey.applicationId.rawValue, value: blockModel.appId)
            .set(key: WPEventNewKey.appName.rawValue, value: blockModel.title)
            .set(key: WPEventNewKey.blockMode.rawValue, value: blockModel.isStandardBlock ? "standard" : "off_standard")
            .set(key: WPEventNewKey.host.rawValue, value: blockModel.isInTemplatePortal ? "template" : "old")
            .set(key: WPEventNewKey.templateId.rawValue, value: portalId ?? "")
            .set(key: WPEventNewKey.isInFavoriteComponent.rawValue, value: blockModel.isInFavoriteComponent)
            .post()
    }

    func postBlockShare(receivers: [WPMessageReceiver]) {
        let chats: [WPMessageReceiver] = receivers.filter{ $0.type == .chat }
        let userCount = receivers.count - chats.count
        let chatIds = chats.map{ $0.id }
        WPEventReport(name: WPNewEvent.shareBlock.rawValue, userId: userResolver.userID, tenantId: tenantId)
            .set(key: WPEventNewKey.click.rawValue, value: WPClickValue.send.rawValue)
            .set(key: WPEventNewKey.target.rawValue, value: WPTargetValue.none.rawValue)
            .set(key: WPEventNewKey.chatId.rawValue, value: chatIds)
            .set(key: WPEventNewKey.personalChatCount.rawValue, value: userCount)
            .set(key: WPEventNewKey.appId.rawValue, value: blockModel.appId)
            .set(key: WPEventNewKey.blockTypeId.rawValue, value: blockModel.blockTypeId)
            .set(key: WPEventNewKey.blockId.rawValue, value: blockModel.blockId)
            .set(key: WPEventNewKey.host.rawValue, value: blockModel.isInTemplatePortal ? "template" : "old")
            .post()
    }
}
