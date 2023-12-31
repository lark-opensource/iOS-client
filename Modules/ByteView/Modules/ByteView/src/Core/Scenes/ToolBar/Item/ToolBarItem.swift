//
//  ToolBarItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation
import UniverseDesignIcon

enum ToolBarItemType: String, Hashable, CaseIterable {
    case microphone
    case camera
    case speaker
    case share
    case participants
    case security
    case chat
    case record
    case transcribe
    case subtitle
    case live
    case effects
    case interpretation
    case countDown
    case settings
    case askHostForHelp
    case switchAudio
    case more
    case leaveMeeting
    case room
    case roomControl
    case breakoutRoomHostControl
    case rejoinBreakoutRoom
    case vote
    case handsup
    case interviewPromotion
    case interviewSpace
    case notes
    case myai
    case reaction
    case roomCombined
}

enum ToolBarItemPadLocation {
    case none
    case left
    case center
    case right
    case more
    case inCombined
}

enum ToolBarItemPhoneLocation {
    case none
    case toolbar
    case navbar
    case more
    /// 供 iPhone security 使用
    case custom
}

enum ToolBarBadgeType: Equatable {
    case none
    case dot
    case text(String)

    func isSameType(with other: ToolBarBadgeType) -> Bool {
        switch (self, other) {
        case (.none, .none): return true
        case (.dot, .dot): return true
        case (.text, .text): return true
        default: return false
        }
    }

    /// 当在一个 toolbar item 上有多个红点请求时，展示的优先级
    var priority: Int {
        switch self {
        case .none: return 0
        case .text: return 1
        case .dot: return 2
        }
    }
}

extension ToolBarBadgeType: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        switch self {
        case .none: return "none"
        case .dot: return "dot"
        case .text(let string): return "text(\(string)"
        }
    }

    var debugDescription: String { description }
}

protocol ToolBarItemDelegate: AnyObject {
    func toolbarItemDidChange(_ item: ToolBarItem)
    func toolbarItemSizeDidChange(_ item: ToolBarItem)
}

extension ToolBarItemDelegate {
    func toolbarItemSizeDidChange(_ item: ToolBarItem) {}
}

enum ToolBarIconType {
    case none
    case image(UIImage?)
    case icon(key: UDIconType)
    case customColoredIcon(key: UDIconType, color: UIColor)
}

enum ToolBarColorType {
    case none
    case pureColor(color: UIColor)
    case obliqueGradientColor(colors: [UIColor])

    func toRealColor(_ bounds: CGRect? = nil) -> UIColor? {
        switch self {
        case .none: return nil
        case .pureColor(color: let color): return color
        case .obliqueGradientColor(colors: let colors):
            guard let validBounds = bounds else { return nil }
            return UIColor(patternImage: UIImage.vc.obliqueGradientImage(bounds: validBounds, colors: colors))
        }
    }
}

class ToolBarItem: ToolBarBadgeManagerDelegate {
    private let listeners = Listeners<ToolBarItemDelegate>()
    let meeting: InMeetMeeting
    weak var provider: ToolBarServiceProvider?
    let resolver: InMeetViewModelResolver

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.provider = provider
        self.resolver = resolver
    }

    /// 有标题时显示的颜色类型，默认按照isEnabled设置
    var titleColor: ToolBarColorType {
        .none
    }

    var itemType: ToolBarItemType {
        fatalError("Must Be Overrided")
    }

    var title: String {
        ""
    }

    /// 业务视角下，是否需要在 pad toolbar 上显示 title
    var showTitle: Bool {
        true
    }

    /// 是否被收纳，对复合型按钮表示子按钮是否全部收纳
    var isCollapsed = false

    var phoneLocation: ToolBarItemPhoneLocation {
        .none
    }

    /// 业务逻辑视角下，item 应该显示的位置，与实际显示的位置 *acutalLocation* 不同
    var desiredPadLocation: ToolBarItemPadLocation {
        .none
    }

    var actualPadLocation: ToolBarItemPadLocation {
        isCollapsed ? .more : desiredPadLocation
    }

    private(set) var badgeType: ToolBarBadgeType = .none

    var filledIcon: ToolBarIconType {
        .none
    }

    var outlinedIcon: ToolBarIconType {
        .none
    }

    var isEnabled: Bool {
        true
    }

    var isSelected: Bool {
        false
    }

    /// ToolBarItems 全部创建完成后的回调
    func initialize() {
    }

    func shrinkToolBar(completion: (() -> Void)?) {
        if meeting.router.isFloating {
            completion?()
        } else {
            provider?.shrinkToolBar(from: self, completion: completion)
        }
    }

    func addListener(_ listener: ToolBarItemDelegate) {
        Util.runInMainThread {
            self.listeners.addListener(listener)
        }
    }

    func removeListener(_ listener: ToolBarItemDelegate) {
        Util.runInMainThread {
            self.listeners.removeListener(listener)
        }
    }

    func notifyListeners() {
        Logger.ui.info("ToolBar item \(itemType.rawValue) notify listeners")
        Util.runInMainThread {
            self.listeners.forEach { $0.toolbarItemDidChange(self) }
        }
    }

    func notifySizeListeners() {
        Logger.ui.info("ToolBar item \(itemType.rawValue) notify size change listeners")
        Util.runInMainThread {
            self.listeners.forEach { $0.toolbarItemSizeDidChange(self) }
        }
    }

    func clickAction() {
    }

    func addBadgeListener() {
        provider?.badgeManager.addListener(self)
        self.badgeType = provider?.badgeManager.currentBadge(for: itemType) ?? .none
    }

    func updateBadgeType(_ badgeType: ToolBarBadgeType) {
        if self.badgeType != badgeType {
            provider?.badgeManager.requestBadge(badgeType, from: itemType)
        }
    }

    func removeBadgeType(_ badgeType: ToolBarBadgeType) {
        provider?.badgeManager.requestRemovingBadge(badgeType, from: itemType)
    }

    func toolBarBadgeDidChange(on itemType: ToolBarItemType) {
        guard itemType == self.itemType, let provider = provider else { return }
        let badgeType = provider.badgeManager.currentBadge(for: itemType)
        if self.badgeType != badgeType {
            self.badgeType = badgeType
            notifyListeners()
        }
    }
}
