//
//  WidgetView+MetaCallback.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/2/5.
//

import TTMicroApp
import SwiftyJSON
// MARK: Card-Meta包回调
/*------------------------------------------*/
//            Card-Meta包回调
/*------------------------------------------*/
/// Card包信息回调，在这里面处理外观的配置更新
extension WidgetView: CardInfoListenerProtocol {
    func cardMetaCallback(with cardMeta: CardMeta) {
        Self.log.info("[\(widgetModel.name)] Card Meta Call Back \(cardMeta.uniqueID)")
        self.meta = cardMeta
        updateFlag { (flag) in
            flag.metaLoadSuccess = true
        }
    }

    func cardConfigCallback(with configData: Data) {
        let configString = String(data: configData, encoding: .utf8)
        let configJson = JSON(parseJSON: configString ?? "")
        // 可以新增一个控制config输出信息的统一方法
        Self.log.info("[\(widgetModel.name)] Card Config Call Back \(configJson)")

        if let widgetConfig = try? JSONDecoder().decode(WidgetConfig.self, from: configData) {
            /// 默认需要请求
            self.widgetConfig = widgetConfig
        } else {
            self.widgetConfig = nil
            Self.log.error("[\(widgetModel.name)] decode widgetConfig failed")
        }

        updateFlag { (flag) in
            flag.configInfoLoadSuccess = true
        }
        /// 更新业务数据
        updateWidgetBizData()
        /// 标记开始加载卡片数据
        markStartRender()
    }

    /// meta信息加载出错时的回调
    func cardInfoError(with error: Error) {
        Self.log.error("CardBagInfo-callBack: card bag info error", error: error)
        updateFlag { (flag) in
            if (error as NSError).code == widgetVersionErrCode {
                flag.clientVerNotSupport = true
            } else {
                flag.didFinishLoadingWithError = true
            }
        }
        if (error as NSError).code != widgetVersionErrCode {
            WPMonitor().setCode(WPMCode.workplace_widget_fail)
                .setWidgetTag(appName: widgetModel.name, appId: meta?.uniqueID.appID, widgetVersion: meta?.version)
                .setError(errMsg: "CardMeta-callBack:cardInfoError", error: error)
                .postFailMonitor()
        }
    }

    /// 业务异常的拦截
    func isMetaVaild(with cardMeta: CardMeta) -> Error? {
        if !cardMeta.minClientVersion.isEmpty, isSupportClientVersion(targetVersion: cardMeta.minClientVersion) {
            return NSError(
                domain: "widget data version check",
                code: widgetVersionErrCode,
                userInfo: [
                    "error": "client version not support",
                    "cardId": "\(cardMeta.uniqueID.identifier)",
                    "appName": "\(cardMeta.name)"
                ]
            )
        }
        return nil
    }

    /// 判断目标版本是否大于等于当前客户端版本号
    private func isSupportClientVersion(targetVersion: String) -> Bool {
        let clientVersion = WorkplaceTool.appVersion
        /// 客户端版本号相等，可用
        if targetVersion == clientVersion {
            return true
        } else {    // 将版本号转化为数组进行对比
            let targetVersInt = convertVersion(version: targetVersion)
            let clientVersInt = convertVersion(version: clientVersion)
            let minCount = min(clientVersInt.count, targetVersInt.count)
            for i in 0..<minCount where targetVersInt[i] != clientVersInt[i] {
                return targetVersInt[i] > clientVersInt[i]
            }
            return targetVersInt.count > clientVersInt.count
        }
    }

    /// 将客户端版本号转化为Int数组（没有做数据校验的防御⚠️，不要用于非法版本号）
    private func convertVersion(version: String) -> [Int] {
        var mainVer = version
        var typeVer = ""
        var subVer = ""
        let splitBlock = { (type: String) in
            /// 检索关键字（type），将version分割成三个部分; case：3.12.0-alpha12-10000 >>> [3.12.0] [-alpha] [12-10000]
            if version.contains(type) {
                // 不应该强解包
                // swiftlint:disable force_unwrapping
                let index = version.range(of: type)!.lowerBound
                // swiftlint:enable force_unwrapping
                mainVer = String(version[..<index])
                typeVer = type
                subVer = String(version[index...]).replacingOccurrences(of: type, with: "")
                if subVer.first == "-" {
                    subVer = "0" + subVer
                }
            }
        }
        splitBlock("-beta")
        splitBlock("-alpha")
        /// 从左到右将三部分转化为Int数组；case: [3.12.0] [-alpha] [12-10000] >>> [3, 12, 0, 1, 12, 10000]
        var vers = [Int]()
        for ver in mainVer.split(separator: ".") {
            if let verInt = Int(String(ver)) {
                vers.append(verInt)
            }
        }
        if !typeVer.isEmpty {
            vers.append(typeVer == "-beta" ? 2 : 1)
        }
        for ver in subVer.split(separator: "-") {
            if let verInt = Int(String(ver)) {
                vers.append(verInt)
            }
        }
        return vers
    }
}
