//
//  OPBlockContainerPlugin.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/13.
//

import Foundation
import OPSDK
import LarkSetting
import LarkOPInterface
import OPBlockInterface
import LarkContainer

fileprivate enum EventName: String {
    case setBlockInfo
    case cancel
    case hideBlockLoading
    case blockShareEnableStatus
    case receiveBlockShareInfo
}

fileprivate struct ShareEnableStatus: Codable {
    let isBlockEnableShare: Bool
}

protocol OPBlockContainerPluginDelegate: AnyObject {
    func setBlockInfo(event: OPEvent, callback: OPEventCallback) -> Bool
    func onCancel(event: OPEvent, callback: OPEventCallback) -> Bool
    func hideBlockLoading(callback: @escaping (Result<[AnyHashable: Any]?, OPError>) -> Void) -> Bool
    func updateBlockShareEnableStatus(_ enable: Bool)
    func receiveBlockShareInfo(_ info: OPBlockShareInfo)
}

final class OPBlockContainerPlugin: NSObject, OPPluginProtocol {
    private let userResolver: UserResolver

    private var enableTimeoutOptimize: Bool {
        userResolver.fg.staticFeatureGatingValue(with: BlockFGKey.enableTimeoutOptimize.key)
    }

    private weak var delegate: OPBlockContainerPluginDelegate?

    private let containerContext: OPContainerContext

    private var trace: BlockTrace {
        containerContext.blockTrace
    }

    public var filters: [String] = [
        EventName.setBlockInfo.rawValue,
        EventName.cancel.rawValue,
        EventName.hideBlockLoading.rawValue,
        EventName.blockShareEnableStatus.rawValue,
        EventName.receiveBlockShareInfo.rawValue
    ]
    
    required public init(
        userResolver: UserResolver,
        delegate: OPBlockContainerPluginDelegate,
        containerContext: OPContainerContext
    ) {
        self.userResolver = userResolver
        self.containerContext = containerContext
        self.delegate = delegate
        super.init()
        if !enableTimeoutOptimize { filters = [
            EventName.setBlockInfo.rawValue,
            EventName.cancel.rawValue,
            EventName.blockShareEnableStatus.rawValue,
            EventName.receiveBlockShareInfo.rawValue
        ] }
    }
    
    public func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        trace.info("OPBlockContainerPlugin.interceptEvent")
        return false
    }
    
    public func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        guard let delegate = delegate, let api = EventName(rawValue: event.eventName) else { return false }
        switch api {
        case .setBlockInfo:
            return delegate.setBlockInfo(event: event, callback: callback)
        case .cancel:
            return delegate.onCancel(event: event, callback: callback)
        case .hideBlockLoading:
            return delegate.hideBlockLoading(callback: { result in
                DispatchQueue.global().async {
                    switch result {
                    case .success(_):
                        callback.callbackSuccess(data: nil)
                    case .failure(let error):
                        callback.callbackFail(data: nil, error: error)
                    }
                }
            })
        case .blockShareEnableStatus:
            do {
                let data = try JSONSerialization.data(withJSONObject: event.params)
                let shareStatus = try JSONDecoder().decode(ShareEnableStatus.self, from: data)
                delegate.updateBlockShareEnableStatus(shareStatus.isBlockEnableShare)
                return true
            } catch {
                trace.error("blockShareEnableStatus params decode error", error: error)
                return false
            }
        case .receiveBlockShareInfo:
            do {
                let data = try JSONSerialization.data(withJSONObject: event.params)
                let shareInfo = try JSONDecoder().decode(OPBlockShareInfo.self, from: data)
                delegate.receiveBlockShareInfo(shareInfo)
                return true
            } catch {
                trace.error("receiveBlockShareInfo params decode error", error: error)
                return false
            }
        }
    }
}
