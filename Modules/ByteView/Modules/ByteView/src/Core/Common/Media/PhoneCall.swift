//
//  PhoneCall.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import CoreTelephony

protocol PhoneCallObserver: AnyObject {
    func didChangePhoneCallState(from: PhoneCall.State, to: PhoneCall.State, callUUID: UUID?)
}

protocol PhoneCallProvider: AnyObject {
    func bindPhoneCallStateUpdate(observer: @escaping (PhoneCall.State, UUID?) -> Void)
    func hasActiveCalls() -> Bool
    func hasActiveSystemCalls(_ completion: @escaping (Bool) -> Void)
}

protocol PhoneCallIdentifier: AnyObject {
    var callIdentifier: String { get }
}

final class PhoneCall {
    enum State: Hashable, Equatable {
        case unknown
        case connected
        case disconnected
        case incoming
        case dialing
        case holding
    }

    static let shared = PhoneCall()

    private let provider: PhoneCallProvider
    private init() {
#if BYTEVIEW_CALLKIT
        self.provider = CXPhoneCallProvider()
#else
        self.provider = CTPhoneCallProvider()
#endif
        provider.bindPhoneCallStateUpdate { [weak self] state, uuid in
            self?.setPhoneCallState(state, callUUID: uuid)
        }
    }

    @RwAtomic
    private var calls: [UUID: Storage] = [:]
    @RwAtomic
    private var lastStorge: Storage?
    var lastState: State { lastStorge?.lastState ?? .unknown }
    var state: State { lastStorge?.state ?? .unknown }
    var lastCallUUID: UUID? { lastStorge?.callUUID }

    private let observers = Listeners<PhoneCallObserver>()
    func addObserver(_ observer: PhoneCallObserver, needCached: Bool = true) {
        observers.addListener(observer)
        if let storge = self.lastStorge, needCached {
            let fromState = storge.lastState
            let toState = storge.state
            let uuid = storge.callUUID
            observer.didChangePhoneCallState(from: fromState, to: toState, callUUID: uuid)
        }
    }

    func removeObserver(_ observer: PhoneCallObserver) {
        observers.removeListener(observer)
    }

    private struct Storage: Equatable {
        var lastState: State = .unknown
        var state: State = .unknown
        var callUUID: UUID?

        static let `default` = Storage()
    }

    private func setPhoneCallState(_ state: State, callUUID: UUID?) {
        guard let uuid = callUUID else {
            return
        }
        var lastStorge = calls[uuid]
        if lastStorge?.state == state {
            return
        }
        if lastStorge != nil {
            lastStorge!.lastState = lastStorge!.state
            lastStorge!.state = state
            lastStorge!.callUUID = uuid
        } else {
            lastStorge = Storage(lastState: .unknown, state: state, callUUID: uuid)
        }
        calls[uuid] = lastStorge
        self.lastStorge = lastStorge
        let fromState = lastStorge!.lastState
        observers.forEach {
            Logger.phoneCallDial.info("PhoneCall.State change \(uuid) from: \(fromState) to: \(state)")
            $0.didChangePhoneCallState(from: fromState, to: state, callUUID: uuid)
        }
    }

    func hasActiveCalls() -> Bool {
        self.provider.hasActiveCalls()
    }

    func hasActiveSystemCalls(_ completion: @escaping (Bool) -> Void) {
        self.provider.hasActiveSystemCalls(completion)
    }
}

final class CTPhoneCallProvider: PhoneCallProvider {
    private var callCenter = CTCallCenter()
    @RwAtomic
    private var calls: [String: String] = [:]

    func bindPhoneCallStateUpdate(observer: @escaping (PhoneCall.State, UUID?) -> Void) {
        callCenter.callEventHandler = { [weak self] call in
            let lastCallIndentifier = self?.calls[call.callID]
            let currentIdentifier = call.callIdentifier
            Logger.phoneCall.info("phone call change \(currentIdentifier)")
            if lastCallIndentifier == currentIdentifier {
                return
            }
            self?.calls[call.callID] = currentIdentifier
            let callID = UUID(uuidString: call.callID)
            observer(call.state, callID)
            if call.state == .disconnected {
                self?.calls.removeValue(forKey: call.callID)
            }
        }
    }

    func hasActiveCalls() -> Bool {
        guard let calls = callCenter.currentCalls else {
            return false
        }
        for call in calls {
            if call.state == .connected || call.state == .incoming || call.state == .dialing {
                return true
            }
        }
        return false
    }

    func hasActiveSystemCalls(_ completion: @escaping (Bool) -> Void) {
        let hasActive = hasActiveCalls()
        completion(hasActive)
    }
}

extension CTCall {
    /// 电话状态
    var state: PhoneCall.State {
        switch self.callState {
        case CTCallStateConnected:
            return .connected
        case CTCallStateDisconnected:
            return .disconnected
        case CTCallStateDialing:
            return .dialing
        case CTCallStateIncoming:
            return .incoming
        default:
            return .unknown
        }
    }
}

extension CTCall: PhoneCallIdentifier {
    var callIdentifier: String {
        "\(callID)_\(callState)"
    }
}
