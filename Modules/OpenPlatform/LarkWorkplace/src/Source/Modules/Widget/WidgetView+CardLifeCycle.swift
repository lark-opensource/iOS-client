//
//  WidgetView+CardLifeCycle.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/2/5.
//

import TTMicroApp

// MARK: Card生命周期
/*------------------------------------------*/
//            Card生命周期
/*------------------------------------------*/
/// Card生命周期
extension WidgetView: CardLifeCycleProtocol {
    /// Notify that content has started loading on CardView. This method is called once for each content loading request.
    /// - Parameter view: card view
    func cardViewDidStartLoading(_ view: CardViewProtocol) {
        Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView start loading")
        /// 标记卡片开始加载
        updateFlag { (flag) in
            flag.didStartLoading = true
        }
    }

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    func cardViewDidFinishLoading(_ view: CardViewProtocol, with url: URL?) {
        Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did finish loading")
        DispatchQueue.main.async {
            /// 标记卡片加载完成
            self.updateFlag { (flag) in
                flag.didFinishLoading = true
            }
        }
        metrics.renderFinishDate = Date()
        if let startDate = metrics.startDate, let endDate = metrics.renderFinishDate {
            let cost = endDate.timeIntervalSince(startDate)
            WPEventReport(
                name: WPEvent.widget_rendering_time.rawValue,
                userId: userId,
                tenantId: tenantId
            )
            .set(key: WPEventNewKey.appId.rawValue, value: self.meta?.uniqueID.appID ?? "")
            .set(key: "time", value: Int(cost * 1_000.0))
            .post()
            widgetRender?
                .timing()
                .setResultTypeSuccess()
                .addCategoryValue("app_id", self.meta?.uniqueID.appID ?? "")
                .addCategoryValue("app_name", self.widgetModel.name)
                .addCategoryValue("app_version", self.meta?.version ?? "")
                .flush()
            metrics.clear()
            widgetRender = nil
            Self.log.info("[\(widgetModel.name)] WidgetCard- metrics render cost \(Int(cost * 1_000.0)) ms")
        }
    }

    /// Notify that CardView has been first layout after the content is loaded.
    /// - Parameter view: card view
    func cardViewDidLayoutFirstScreen(_ view: CardViewProtocol) {
        Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did layout first screen")
    }

    /// Notify the JS Runtime is  ready.
    /// - Parameter view: card view
    func cardViewDidConstructJSRuntime(_ view: CardViewProtocol) {
        Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did construct JSRuntime")
        widgetData?.readyToUpdateCard() // cardContainer的Js渲染环境就绪，准备更新卡片
        /// 标记卡片JS准备好
        updateFlag { (flag) in
            flag.didPrepareJSRuntime = true
        }
    }

    /// Notify that CardView has been updated after updating data on CardView, but the view may not be updated.
    /// - Parameter view: card view
    func cardViewDidUpdateData(_ view: CardViewProtocol) {
        Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did update data")
    }

    /// Notify the intriniscContentSize has changed.
    /// - Parameter view: card view
    func cardViewDidChangeIntrinsicContentSize(_ view: CardViewProtocol, cardContentSize: CGSize) {
        Self.log.info("[\(widgetModel.name)]WidgetCard-LifeCycle: cardView did change content size \(cardContentSize)")
        handleExpandSizeChange(expandSize: cardContentSize)
    }

    /// Notify that content has been sucessful loaded on CardView. This method is called once for each load content request.
    /// - Parameters:
    ///   - view: card view
    ///   - url: The url of the content
    ///   - error: Load failed error message
    func cardViewDidLoadFailed(_ view: CardViewProtocol, with url: String, error: Error?) {
        Self.log.warn("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did load failed with \(url)")
        /// 标记卡片加载遇到错误
        updateFlag { (flag) in
            flag.didFinishLoadingWithError = true
        }
        WPMonitor().setCode(WPMCode.workplace_widget_fail)
            .setWidgetTag(appName: widgetModel.name, appId: meta?.uniqueID.appID, widgetVersion: meta?.version)
            .setError(errMsg: "CardContainer-LifeCycle:cardViewDidLoadFailed", error: error)
            .postFailMonitor()
    }

    /// Notify that CardView has error happens
    /// - Parameters:
    ///   - view: card view
    ///   - error: error message
    func cardViewDidRecieve(_ view: CardViewProtocol, error: Error?) {
        if let err = error {
            Self.log.warn("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did recieve \(err)")
        } else {
            Self.log.info("[\(widgetModel.name)] WidgetCard-LifeCycle: cardView did recieve")
            /// 标记卡片运行遇到错误
            updateFlag { (flag) in
                flag.didRunningWithError = true
            }
        }
        WPMonitor().setCode(WPMCode.workplace_widget_fail)
            .setWidgetTag(appName: widgetModel.name, appId: meta?.uniqueID.appID, widgetVersion: meta?.version)
            .setError(errMsg: error?.localizedDescription ?? "", error: error)
            .postFailMonitor()
    }
    /// Notify that CardView has received first load performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveFirstLoadPerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?) {
        reportLoadPerformance(firstLoad: true, perf: perf)
    }
    /// Notify that CardView has received update performance data
    /// - Parameters:
    ///   - view: card view
    ///   - perf: performance data
    func cardViewDidReceiveUpdatePerf(_ view: CardViewProtocol, perf: [AnyHashable: Any]?) {
        reportLoadPerformance(firstLoad: false, perf: perf)
    }
    private func formatePerf(perf: [AnyHashable: Any]?) -> [String: Any]? {
        guard let performance = perf else {
            return nil
        }
        var maps: [String: Any] = [:]
        /// 传入非实现NSCoding的对象会导致抛出异常 Monitor‘s event tracing does not support the type of data unrealized NSCoding
        performance.forEach { (arg0) in
            let (key, value) = arg0
            if value is String || value is NSNumber {
                maps["\(key)"] = value
            } else {
                maps["\(key)"] = "\(value)"
            }
        }
        return maps
    }
    /// 上报卡片加载的性能数据
    private func reportLoadPerformance(firstLoad: Bool, perf: [AnyHashable: Any]?) {
        OPMonitor(WPMWorkplaceCode.workplace_widget_runing)
        .addCategoryValue("app_id", self.meta?.uniqueID.appID ?? "")
        .addCategoryValue("app_name", self.widgetModel.name)
        .addCategoryValue("app_version", self.meta?.version ?? "")
        .addCategoryValue("firstLoadPerf", firstLoad)
        .addMap(formatePerf(perf: perf))
        .flush()
    }
}
