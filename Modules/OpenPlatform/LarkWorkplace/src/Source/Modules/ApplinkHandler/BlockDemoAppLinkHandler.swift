//
//  BlockDemoAppLinkHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/26.
//

import Foundation
import LKCommonsLogging
import LarkNavigator
import LarkContainer
import EENavigator
import LarkAppLinkSDK
import Blockit
import LarkWorkplaceModel

/// Block 开发者示例: /client/block/workplace/open
///
/// base path: /client/block/workplace/open
///
/// 基础参数:
/// - Parameter appId: 应用id
/// - Parameter blockTypeId: blockTypeId
/// - Parameter sourceData: block sourceData，用于传递给 Block 业务
/// - Parameter openDetail: 是否打开详情页
/// - Parameter title: 标题, 用于跳转详情页显示
/// - Parameter list_page_url: 跳转到详情页的信息，仍然是当前 schema，但参数不同
///
/// sourceData 示例内容:
/// ```
/// {"sourceData":{"tab":"api"}}
/// ```
///
/// 详情页参数:
/// - Parameter blockEntity: 跳转到详情页时传递给 Block 的 entity 参数
///
/// blockEntity 示例内容:
/// ```
/// {"sourceData":{"tab":"component","isNew":true,"item":"text"},"blockID":"mock-block"}
/// ```
///
/// 参数拼接示例:
/// 列表页:
/// ```
/// https://applink.feishu.cn/client/block/workplace/open?appId=cli_a180fc58feb8d00b&blockTypeId=blk_610a40455f800004c32b6bb6&sourceData=%7B%22tab%22%3A%22api%22%7D
/// ```
/// 详情页:
/// ```
/// https://applink.feishu.cn/client/block/workplace/open?appId=cli_a180b32bf8f8900b&blockTypeId=blk_610a0f3659c04004c56b2b90&openDetail=1&title=text&list_page_url=https://applink.feishu.cn/client/block/workplace/open?appId=cli_a180fc58feb8d00b%26blockTypeId=blk_610a40455f800004c32b6bb6%26blockEntity=%7B%22sourceData%22%3A%7B%22tab%22%3A%22api%22%7D%7D&blockEntity=%7B%22sourceData%22%3A%7B%22tab%22%3A%22component%22%2C%22isNew%22%3Atrue%2C%22item%22%3A%22text%22%7D%2C%22blockID%22%3A%22mock-block%22%7D
/// ```
struct BlockDemoAppLinkHandler {
    static let logger = Logger.log(BlockDemoAppLinkHandler.self)

    static let pattern = "/client/block/workplace/open"

    static func handle(applink: AppLink) {
        logger.info("start handle block demo applink", additionalData: ["url": applink.url.absoluteString])
        guard let from = applink.context?.from() else { return }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator
        let url = applink.url

        let appLinkParams = parseBlockDemoAppLink(url: url)
        // openDetail=1, 打开 demo 详情页
        if let openDetail = appLinkParams["openDetail"] as? String, openDetail == "1" {
            var params = OpenDemoBlockParams()
            if let appId = appLinkParams["appId"] as? String {
                params.appId = appId
            }
            if let blockTypeId = appLinkParams["blockTypeId"] as? String {
                params.blockTypeId = blockTypeId
            }
            if let title = appLinkParams["title"] as? String {
                params.title = title
            }
            if let sourceData = appLinkParams["sourceData"] as? [String: Any],
               let blockId = appLinkParams["blockID"] as? String {
                params.sourceData = sourceData
                params.blockId = blockId
            }
            let blockInfo = WPBlockInfo(
                blockId: params.blockId, blockTypeId: params.blockTypeId, hasSetting: nil, settingURL: nil
            )
            let item = WPAppItem.buildBlockDemoItem(appId: params.appId, blockInfo: blockInfo)
            let blockDemoParams = BlockDemoParams(
                item: item,
                title: params.title,
                sourceData: params.sourceData,
                sourceMeta: params.sourceMeta
            )
            let listPageData = appLinkParams["listPageData"] as? [String: Any] ?? [:]

            let body = BlockDemoDetailBody(params: blockDemoParams, listPageData: listPageData)
            navigator.push(body: body, from: from)
        } else {    // 打开 demo 首页
            logger.info("blockDemo page open success")
            let body = BlockDemoBody(params: appLinkParams)
            navigator.push(body: body, from: from)
        }
    }

    /// 解析 blockDemo 的 AppLink
    private static func parseBlockDemoAppLink(url: URL) -> [String: Any] {
        let param = url.queryParameters
        var newParams: [String: Any] = [:]

        if let appId = param["appId"] {
            newParams["appId"] = appId
        }
        if let blockTypeId = param["blockTypeId"] {
            newParams["blockTypeId"] = blockTypeId
        }
        if let openDetail = param["openDetail"] {
            newParams["openDetail"] = openDetail
        }
        if let title = param["title"] {
            newParams["title"] = title
        }

        // demo 详情页 url 包含 blockEntity
        if let blockEntityString = param["blockEntity"],
           let blockEntity = convertJsonToDict(inputString: blockEntityString) {
            newParams["sourceData"] = blockEntity["sourceData"]
            newParams["blockID"] = blockEntity["blockID"]

            // 解析直接跳转详情页 url 中包含的列表页 url
            if let listPageParam = param["list_page_url"],
               let listPageURL = HttpSerializer.encode(listPageParam) {
                newParams["listPageData"] = parseBlockDemoAppLink(url: listPageURL)
            }
        }
        // demo 列表 url 包含 sourceData
        if let sourceDataString = param["sourceData"] {
            let sourceData = convertJsonToDict(inputString: sourceDataString)
            newParams["sourceData"] = sourceData
        }

        return newParams
    }

    /// json串转化为字典
    private static func convertJsonToDict(inputString: String) -> [String: Any]? {
        guard let data = inputString.data(using: .utf8) else {
            logger.info("ConvertJsonToDict invalid data from inputstring")
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
    }
}
