//
//  ToolBarMoreItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewTracker
import ByteViewUI

final class ToolBarMoreItem: ToolBarItem {
    static let logger = Logger.ui

    override var itemType: ToolBarItemType { .more }

    override var title: String {
        I18n.View_G_More
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .moreReactionOutlined)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .moreOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        (Display.phone && !VCScene.isLandscape) ? .toolbar : .navbar
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        .right
    }

    override var actualPadLocation: ToolBarItemPadLocation {
        isCollapsed ? .none : desiredPadLocation
    }

    override var isSelected: Bool {
        isMoreVCOpening
    }

    private var isMoreVCOpening = false

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.updateMoreBadge()
        self.addBadgeListener()
    }

    override func clickAction() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "more"])

        // 妙享场景手机横屏，点击此按钮时，收起键盘
        if meeting.shareData.isSharingDocument, Display.phone, VCScene.isLandscape {
            Util.dismissKeyboard()
        }

        if Display.pad {
            openMoreVC()
        } else {
            provider?.generateImpactFeedback()
            provider?.expandToolBar(from: self)
        }
    }

    private func openMoreVC() {
        guard let sourceView = provider?.itemView(with: .more) else { return }
        let vc = ToolBarListViewController(viewModel: resolver.resolve()!)
        vc.delegate = self
        vc.updateContainerSize()
        let trackName = meeting.type.trackName

        let hideArrow: Bool
        if #available(iOS 13, *) {
            hideArrow = false
        } else {
            // iOS 11 12下如果不设置popoverBackgroundViewClass，背景会是黑色的
            // 参考UI意见直接去掉箭头使用CustomPopoverBackgroundView
            hideArrow = true
        }
        // disable-lint: magic number
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: sourceView.bounds.offsetBy(dx: 0, dy: -14),
                                                      backgroundColor: UIColor.clear,
                                                      hideArrow: hideArrow,
                                                      permittedArrowDirections: .down)
        // enable-lint: magic number
        let config = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        meeting.router.presentDynamicModal(vc, config: config) { (_, _) in
            VCTracker.post(name: trackName, params: [.action_name: "addition"])
        }
        isMoreVCOpening = true
        notifyListeners()
    }

    override func toolBarBadgeDidChange(on itemType: ToolBarItemType) {
        if itemType == .more {
            super.toolBarBadgeDidChange(on: itemType)
            return
        }
        updateMoreBadge()
    }

    func updateMoreBadge() {
        let showMoreBadge = provider?.badgeManager.hasMoreBadge(with: { itemType, _ in
            if itemType == .more {
                return false
            } else if Display.pad {
                return provider?.item(with: itemType).actualPadLocation == .more
            } else {
                return provider?.item(with: itemType).phoneLocation == .more
            }
        }) ?? false
        updateBadgeType(showMoreBadge ? .dot : .none)
    }
}

extension ToolBarMoreItem: ToolBarListViewControllerDelegate {
    func toolbarListViewControllerDidDismiss() {
        isMoreVCOpening = false
        notifyListeners()
    }
}
