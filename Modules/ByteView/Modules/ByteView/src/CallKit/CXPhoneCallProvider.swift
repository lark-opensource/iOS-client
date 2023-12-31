//
//  CXPhoneCallProvider.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import CallKit

final class CXPhoneCallProvider: NSObject, PhoneCallProvider {
    let callObserver: CXCallObserver = CXCallObserver()
    private var observer: ((PhoneCall.State, UUID?) -> Void)?
    @RwAtomic
    private var calls: [UUID: String] = [:]

    override init() {
        super.init()
        callObserver.setDelegate(self, queue: DispatchQueue.global())
    }

    func bindPhoneCallStateUpdate(observer: @escaping (PhoneCall.State, UUID?) -> Void) {
        self.observer = observer
    }

    func hasActiveCalls() -> Bool {
        for call in callObserver.calls {
            if call.state == .connected || call.state == .incoming || call.state == .dialing {
                return true
            }
        }
        return false
    }

    func hasActiveSystemCalls(_ completion: @escaping (Bool) -> Void) {
        CallKitQueue.queue.async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }

            for call in self.callObserver.calls {
                let isActive = call.state == .connected || call.state == .incoming
                let byteViewCall = CallKitManager.shared.lookupCall(uuid: call.uuid)
                if isActive && byteViewCall == nil {
                    completion(true)
                    return
                }
            }

            completion(false)
        }
    }
}

extension CXPhoneCallProvider: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        let currenrIdentifier = call.callIdentifier
        Logger.phoneCall.info("phone call changed \(currenrIdentifier)")
        let lastCallIdentifier = calls[call.uuid]
        if lastCallIdentifier == currenrIdentifier {
            return
        }
        calls[call.uuid] = currenrIdentifier
        observer?(call.state, call.uuid)
        if call.state == .disconnected {
            calls.removeValue(forKey: call.uuid)
        }
    }
}

extension CXCall {
    /// 电话状态
    var state: PhoneCall.State {
        if self.hasEnded {
            return .disconnected
        } else if self.isOutgoing && !self.hasConnected {
            return .dialing
        } else if !self.isOutgoing && !self.hasConnected && !self.hasEnded {
            return .incoming
        } else if self.hasConnected && !self.hasEnded && !self.isOnHold {
            return .connected
        } else if self.isOnHold && !self.hasEnded {
            return .holding
        } else {
            return .unknown
        }
    }
}

extension CXCall: PhoneCallIdentifier {
    var callIdentifier: String {
        "\(uuid)_o:\(isOutgoing)_h:\(isOnHold)_c:\(hasConnected)_e:\(hasEnded)"
    }
}
