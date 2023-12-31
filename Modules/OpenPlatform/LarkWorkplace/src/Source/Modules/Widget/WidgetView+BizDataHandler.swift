//
//  WidgetView+BizDataHandler.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/2/5.
//

import LKCommonsLogging
import LarkOPInterface
// MARK: Widget业务数据相关
/*------------------------------------------*/
//            Widget 业务数据相关
/*------------------------------------------*/
/// Widget 业务数据相关
extension WidgetView {
    /// 判断是否是需要「业务数据」
    func needBusinessData() -> Bool {
        // 首先检查配置信息是否load成功
        guard flag.configInfoLoadSuccess ?? false else {
            return false
        }
        // 判断是否需要请求业务数据
        return widgetConfig?.needRequestBusinessData ?? true
    }
    /// 刷新业务数据
    func updateWidgetBizData() {
        guard let meta = self.meta else {
            Self.log.error("[\(widgetModel.name)] Card Meta is nil, can't setup biz data")
            WPMonitor().setCode(WPMCode.workplace_widget_fail)
                .setError(errMsg: "Card Meta is nil, can't setup biz data")
                .postFailMonitor()
            self.state = .loadFail
            return
        }
        /// 需要meta和业务数据同时才能渲染
        guard needBusinessData() else {
            Self.log.error("[\(widgetModel.name)] Card render require widget biz data")
            return
        }
        /// 记录上一次的状态
        let canUpdateData = widgetData?.data.canUpdateData
        /// 请求card业务数据（定义）
        widgetData = WidgetBizDataUpdate(
            userId: userId,
            dataManage: widgetDataManage,
            widgetID: meta.uniqueID.identifier,
            widgetVersion: meta.version,
            uniqueWidgetID: metaUpdateTime ?? "",
            dataUpdateCallback: { [weak self] (rsp, err, data) in
                /// 检查数据是否匹配当前widget
                guard data.uniqueWidgetID == self?.metaUpdateTime else {
                    Self.log.error(
                        "update widgetData failed, not match current meta",
                        additionalData: [
                            "uniqueWidgetID": data.uniqueWidgetID,
                            "current uniqueWidgetID": self?.metaUpdateTime ?? ""
                        ]
                    )
                    return
                }
                /// widget业务数据加载失败
                if let widgetDataErr = err {
                    self?.handleLoadWidgetDataFail(err: widgetDataErr)
                    let err = widgetDataErr.localizedDescription
                    Self.log.error("updateWidgetData widget data error : \(err)")
                    return
                }
                /// 业务数据加载成功
                if let bizData = rsp {
                    self?.handleWidgetDataUpdate(bizData: bizData) // 处理业务数据，准备更新Card
                    Self.log.info("updateWidgetData response success", additionalData: [
                        "widgetID": bizData.reqContext?.widgetID ?? ""
                    ])
                }
            }
        )
        if let canUpdateData = canUpdateData {
            /// 如果卡片已经渲染，那么记录上一次的状态
            widgetData?.data.canUpdateData = canUpdateData
        }
        widgetData?.requestRemoteData() // 请求执行
    }
    /// 成功接受业务数据
    func handleWidgetDataUpdate(bizData: WidgetBizCacheData) {
        // swiftlint:disable todo
        // TODO: 统一使用OPMonitor监控错误
        var errorMsg = "widget data is not valid"
        if isWidgetDataValid(bizData: bizData, notValidReason: &errorMsg) {
            if let content = bizData.widgetBizDataResp?.content {
                Self.log.error("handleWidgetDataUpdate data content")
                flag.widgetBizDataFlag.lastBizData = bizData
                DispatchQueue.main.async {
                    /// 使用业务数据更新Card
                    self.updateCardData(widgetData: content)
                }
            }
        } else {
            if !isOldBizDataInvalid(bizData: bizData) {   // 无效数据不属于错误
                handleLoadWidgetDataFail(err: NSError(
                    domain: "handleWidgetDataUpdate",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg]
                ))
            }
        }
        // swiftlint:enable todo
    }

    /// widget data 是否有效
    private func isWidgetDataValid(bizData: WidgetBizCacheData, notValidReason: inout String ) -> Bool {
        guard let rspData = bizData.widgetBizDataResp, !rspData.content.isEmpty else {
            Self.log.error("isWidgetDataValid not valid rsp is nil or content is nil", additionalData: [
                "bizData.widgetBizDataResp.widgetID": bizData.widgetBizDataResp?.widgetID ?? ""
            ])
            return false
        }

        guard rspData.widgetVersion == meta?.version else {
            Self.log.error(
                "isWidgetDataValid not valid version not match dataVersion",
                additionalData: [
                    "rspData.widgetVersion": rspData.widgetVersion,
                    "meta?.version": meta?.version ?? "",
                    "bizData.widgetBizDataResp?.widgetID": bizData.widgetBizDataResp?.widgetID ?? ""
                ]
            )
            return false
        }

        let bizDataTimestamp = bizData.widgetBizDataResp?.timestamp ?? 0
        if let lastTimestamp = flag.widgetBizDataFlag.lastBizData?.widgetBizDataResp?.timestamp,
            bizDataTimestamp <= lastTimestamp {
            Self.log.warn(
                "isWidgetDataValid timestamp invalid",
                additionalData: [
                    "lastTimestamp": "\(lastTimestamp)",
                    "bizDataTimestamp": "\(bizDataTimestamp)"
                ]
            )
            return false
        }
        return true
    }

    /// 是否过时的业务数据
    private func isOldBizDataInvalid(bizData: WidgetBizCacheData) -> Bool {
        let bizDataTimestamp = bizData.widgetBizDataResp?.timestamp ?? 0
        /// 根据时间戳，判断是否是更新后的业务数据；如果过时，则认为是无效的业务数据（但是无需上报）
        if let lastTimestamp = flag.widgetBizDataFlag.lastBizData?.widgetBizDataResp?.timestamp,
            bizDataTimestamp <= lastTimestamp {
            return true
        } else {
            return false
        }
    }

    /// 处理加载widget业务数据失败的情况（超时，网络失败，业务数据请求失败）
    func handleLoadWidgetDataFail(err: Error? = nil) {
        /// 如果widget已经展示过业务数据（比如缓存数据），再次遇到错误的时候，这个时候忽略掉错误
        DispatchQueue.main.async {
            if self.flag.didSetWidgetData == nil {
                /// 标记业务数据加载错误
                self.updateFlag { (flag) in
                    flag.didLoadWidgetDataWithError = true
                }
            }
        }
        WPMonitor().setCode(WPMCode.workplace_widget_fail)
            .setError(errMsg: "handle load widget data fail", error: err)
            .postFailMonitor()
    }
}
