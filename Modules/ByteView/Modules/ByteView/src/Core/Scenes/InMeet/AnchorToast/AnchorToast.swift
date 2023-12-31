//
//  AnchorToast.swift
//  ByteView
//
//  Created by lutingting on 2022/8/30.
//

import Foundation

enum AnchorToastType: String {
    case participants
    case attendees
    case more
}

enum AnchorToastIdentifier: String {
    case general
    case handsUp
    case refuseReply
}

class AnchorToastDescriptor: Equatable {
    typealias Action = () -> Void

    let type: AnchorToastType
    var title: String?
    var actionTitle: String?
    var duration: TimeInterval?
    var sureAction: Action?
    var pressToastAction: Action?
    var deinitAction: Action?
    var hasClosed: Bool = false
    var identifier: AnchorToastIdentifier = .general

    init(type: AnchorToastType, title: String?, actionTitle: String? = nil) {
        self.type = type
        self.title = title
        self.actionTitle = actionTitle
    }

    deinit {
        deinitAction?()
    }

    static func == (lhs: AnchorToastDescriptor, rhs: AnchorToastDescriptor) -> Bool {
        lhs.type == rhs.type && lhs.title == rhs.title && lhs.duration == rhs.duration
    }
}

class AnchorToast {
    static let shared = AnchorToast()
    var current: AnchorToastDescriptor? {
        component?.currentToast
    }
    private weak var component: InMeetAnchorToastComponent?

    private init() {}

    func setComponent(component: InMeetAnchorToastComponent) {
        self.component = component
    }

    static func show(_ anchorToast: AnchorToastDescriptor) {
        Util.runInMainThread {
            Self.shared.component?.show(anchorToast)
        }
    }

    static func dismiss(_ anchorToast: AnchorToastDescriptor) {
        Util.runInMainThread {
            Self.shared.component?.dismissToast(anchorToast)
        }
    }
}
