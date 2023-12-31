//
//  DebugConfigs.swift
//  ByteView
//
//  Created by kiri on 2021/6/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewRTCRenderer
import ByteViewSetting
import ByteViewRtcBridge

public protocol DebugFormEntry {
    func tableViewDidSelectEntry(_ tableView: UITableView, vc: UIViewController?)
}

extension DebugFormEntry {
    public func tableViewDidSelectEntry(_ tableView: UITableView, vc: UIViewController?) {}
}

public enum DebugConfigs {

    public struct InputFieldEntry: DebugFormEntry {
        public let label: String
        public let variable: BehaviorRelay<String>
        public init(label: String, valueRelay: BehaviorRelay<String>) {
            self.label = label
            self.variable = valueRelay
        }
    }

    public struct SwitchFieldEntry: DebugFormEntry {
        public let label: String
        public let variable: BehaviorRelay<Bool>
        public init(label: String, valueRelay: BehaviorRelay<Bool>) {
            self.label = label
            self.variable = valueRelay
        }
    }

    public struct CustomVCEntry: DebugFormEntry {
        public let label: String
        public let vcBuilder: () -> UIViewController
        public init(label: String, vcBuilder: @escaping () -> UIViewController) {
            self.label = label
            self.vcBuilder = vcBuilder
        }

        public func tableViewDidSelectEntry(_ tableView: UITableView, vc: UIViewController?) {
            vc?.navigationController?.pushViewController(vcBuilder(), animated: true)
        }
    }

    public static var entries: [DebugFormEntry] = [
        SwitchFieldEntry(label: "EnableOrientationKit", valueRelay: Self.isOrientationKitEnabledRelay)
    ]

    private static let isOrientationKitEnabledRelay: BehaviorRelay<Bool> = {
        let relay = BehaviorRelay(value: RtcDebugger.isOrientationKitEnabled)
        _ = relay.subscribe(onNext: { RtcDebugger.isOrientationKitEnabled = $0 })
        return relay
    }()
}
