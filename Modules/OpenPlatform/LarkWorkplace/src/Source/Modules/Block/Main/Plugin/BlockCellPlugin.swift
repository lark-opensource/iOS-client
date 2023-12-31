//
//  BlockHeaderPlugin.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/2/25.
//

import Foundation
import OPSDK
import LarkOPInterface
import LarkSetting

/// 工作台宿主注册的 API，供 Block 开发者调用（请勿随意修改枚举变量名）
enum WPBlockAPI {
    // Block -> Native API
    enum InvokeAPI: String, CaseIterable {
        // Header Menu 相关 API
        case addMenuItem
        case removeMenuItem
        case updateMenuItem

        /// 获取 HostInfo
        case getHostInfo
        /// 获取 Block 容器的最大尺寸
        case getContainerRect
        /// 隐藏 Block 的 loading
        case hideBlockLoading
        /// 隐藏 block
        case tryHideBlock

        /// 打开block demo
        case openDemoBlock = "_openDemoBlock"

        /// 是否为同步，默认 false
        var isSync: Bool {
            switch self {
            default:
                return false
            }
        }
    }

    // Native -> Block API
    enum OnAPI: String, CaseIterable {
        /// Block Header 按钮点击回调
        case onMenuItemTap

        /// Block 容器大小发生变化回调
        case onContainerResize

        /// 向 JS SDK 发送获取 Block 分享数据的事件
        case getBlockShareInfo

        /// 是否为同步，默认 false
        var isSync: Bool {
            switch self {
            default:
                return false
            }
        }
    }

    static func allApis(for enableTimeoutOptimizeFG: Bool) -> [[AnyHashable: Any]] {
        var apis = [[AnyHashable: Any]]()
        for api in InvokeAPI.allCases {
            if enableTimeoutOptimizeFG, api == .hideBlockLoading { continue }
            apis.append([
                "apiName": api.rawValue,
                "isSync": api.isSync,
                "apiType": "invoke"
            ])
        }
        for api in OnAPI.allCases {
            apis.append([
                "apiName": api.rawValue,
                "isSync": api.isSync,
                "apiType": "on"
            ])
        }
        return apis
    }
}

typealias WPBlockAPICallback = (Result<[AnyHashable: Any]?, OPError>) -> Void

protocol BlockCellPluginDelegate: NSObjectProtocol {

    /// Plugin 收到前端 Block API 调用
    /// - Parameters:
    ///   - plugin: 插件实例
    ///   - api: 调用的 API
    ///   - param: 调用的 API 参数
    ///   - callback: 调用 API 的结果回传
    func handleAPI(
        _ plugin: BlockCellPlugin,
        api: WPBlockAPI.InvokeAPI,
        param: [AnyHashable: Any],
        callback: @escaping WPBlockAPICallback
    )
}

final class BlockCellPlugin: OPPluginBase {
    weak var delegate: BlockCellPluginDelegate?
    private let enableBlockitTimeoutOptimize: Bool

    init(delegate: BlockCellPluginDelegate? = nil, enableBlockitTimeoutOptimize: Bool) {
        self.delegate = delegate
        self.enableBlockitTimeoutOptimize = enableBlockitTimeoutOptimize
        super.init()
        self.filters = WPBlockAPI.InvokeAPI.allCases.map({ $0.rawValue })
        if enableBlockitTimeoutOptimize {
            self.filters.removeAll(where: { $0 == "hideBlockLoading" })
        }
    }

    override func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        var eventName = event.eventName
        guard let apiName = WPBlockAPI.InvokeAPI(rawValue: eventName) else {
            return false
        }
        guard let imp = delegate else {
            return false
        }
        imp.handleAPI(self, api: apiName, param: event.params) { result in
            DispatchQueue.global().async {
                switch result {
                case .success(let data):
                    callback.callbackSuccess(data: data)
                case .failure(let error):
                    if apiName == .hideBlockLoading {
                        let data: [AnyHashable: Any] = [
                            "errno": error.monitorCode.code,
                            "errString": error.monitorCode.message
                        ]
                        callback.callbackFail(data: data, error: error)
                    } else {
                        callback.callbackFail(data: nil, error: error)
                    }
                }
            }
        }
        return true
    }
}
