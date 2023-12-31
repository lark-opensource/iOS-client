//
//  ToolBarViewModel.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/5.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewUI

protocol ToolBarViewModelDelegate: AnyObject {
    func toolbarItemDidChange(_ item: ToolBarItem)
    func toolbarItemSizeDidChange(_ item: ToolBarItem)
}

extension ToolBarViewModelDelegate {
    func toolbarItemSizeDidChange(_ item: ToolBarItem) {}
}

protocol ToolBarViewModelBridge: AnyObject {
    func toggleToolBarStatus(expanded: Bool, completion: (() -> Void)?)
    func itemView(with type: ToolBarItemType) -> UIView?
}

enum ToolBarViewModelBridgeType {
    case navbar
    case toolbar
}

final class ToolBarViewModel {
    private let meeting: InMeetMeeting
    let context: InMeetViewContext
    private let resolver: InMeetViewModelResolver

    private let listeners = Listeners<ToolBarViewModelDelegate>()
    private let bridges = HashListeners<ToolBarViewModelBridgeType, ToolBarViewModelBridge>()

    // 让外界获取当前 toolbar 展开状态，同时也是为了横竖屏切换时在两个 VC 之间同步状态
    var isExpanded = false
    var isAnimating = false
    let badgeManager = ToolBarBadgeManager()
    let factory: ToolBarFactory

    let phoneMainItems: [ToolBarItemType] = ToolBarConfiguration.phoneMainItems
    let phoneMoreItems: [ToolBarItemType] = ToolBarConfiguration.phoneCollectionItems
    let padLeftItems: [ToolBarItemType] = ToolBarConfiguration.padLeftItems
    let padCenterItems: [ToolBarItemType] = ToolBarConfiguration.padCenterItems
    let padRightItems: [ToolBarItemType] = ToolBarConfiguration.padRightItems
    var padMoreItems: [[ToolBarItemType]] {
        ToolBarConfiguration.padMoreItems.map {
            $0.filter { factory.item(for: $0).actualPadLocation == .more }
        }
    }

    var hostControlItem: ToolBarSecurityItem? {
        factory.item(for: .security) as? ToolBarSecurityItem
    }

    var hostControlShouldShowOnPhone: Bool {
        (hostControlItem?.phoneLocation ?? .none) != .none
    }

    var fullScreenDetector: InMeetFullScreenDetector? {
        context.fullScreenDetector
    }

    var meetingTrackName: TrackEventName {
        meeting.type.trackName
    }

    var meetingLayoutStyle: MeetingLayoutStyle {
        context.meetingLayoutStyle
    }

    init(resolver: InMeetViewModelResolver) {
        self.resolver = resolver
        self.meeting = resolver.meeting
        self.context = resolver.viewContext
        self.factory = ToolBarFactory(resolver: resolver)

        self.factory.provider = self
        self.factory.resolveToolbarItems()
        self.addItemListeners()
    }

    // MARK: - Public

    func addListener(_ listener: ToolBarViewModelDelegate) {
        listeners.addListener(listener)
    }

    func setBridge(_ bridge: ToolBarViewModelBridge, for type: ToolBarViewModelBridgeType) {
        bridges.addListener(bridge, for: type)
    }

    /// 在 toolbar 上查找给定类型的 item，如果找不到，且其实际处于 more 列表内，则返回 more item，都没有时返回 nil
    func itemOrContainerView(with type: ToolBarItemType) -> UIView? {
        if let view = itemView(with: type) {
            return view
        }
        let item = factory.item(for: type)
        if Display.pad {
            switch item.actualPadLocation {
            case .more, .center, .right: return itemView(with: .more)
            default: return nil
            }
        } else {
            return item.phoneLocation == .more ? itemView(with: .more) : nil
        }
    }

    func shrinkToolBar(completion: (() -> Void)?) {
        bridges.invokeListeners(for: bridgeType(for: nil), action: {
            $0.toggleToolBarStatus(expanded: false, completion: completion)
        })
    }

    // MARK: - Private

    private func addItemListeners() {
        ToolBarItemType.allCases.map { factory.item(for: $0) }.forEach {
            $0.addListener(self)
        }
    }

    private func bridgeType(for item: ToolBarItem?) -> ToolBarViewModelBridgeType {
        if Display.pad {
            // iPad 固定从 toolbar 上查询
            return .toolbar
        } else if VCScene.isPhoneLandscape {
            // 手机横屏从 navbar 查询
            return .navbar
        } else {
            // 竖屏时，根据 item 的实际显示位置决定是从 toolbar 查询还是 navbar 查询
            return item?.phoneLocation == .navbar ? .navbar : .toolbar
        }
    }
}

extension ToolBarViewModel: ToolBarServiceProvider {
    func shrinkToolBar(from item: ToolBarItem, completion: (() -> Void)?) {
        let key = bridgeType(for: item)
        bridges.invokeListeners(for: key, action: {
            $0.toggleToolBarStatus(expanded: false, completion: completion)
        })
    }

    func expandToolBar(from item: ToolBarItem) {
        let key = bridgeType(for: item)
        bridges.invokeListeners(for: key, action: {
            $0.toggleToolBarStatus(expanded: true, completion: nil)
        })
    }

    func item(with type: ToolBarItemType) -> ToolBarItem {
        factory.item(for: type)
    }

    func itemView(with type: ToolBarItemType) -> UIView? {
        let key = bridgeType(for: factory.item(for: type))
        if let obj = bridges.first(for: key) {
            return obj.itemView(with: type)
        }
        return nil
    }

    func generateImpactFeedback() {
        if Display.phone {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    var hostViewController: UIViewController? {
        context.hostViewController
    }
}

extension ToolBarViewModel: ToolBarItemDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        listeners.forEach { $0.toolbarItemDidChange(item) }
    }

    func toolbarItemSizeDidChange(_ item: ToolBarItem) {
        listeners.forEach { $0.toolbarItemSizeDidChange(item) }
    }
}
