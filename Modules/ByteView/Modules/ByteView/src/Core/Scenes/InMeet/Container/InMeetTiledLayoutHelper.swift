//
//  InMeetTiledLayoutHelper.swift
//  ByteView
//
//  Created by liujianlong on 2021/10/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import ByteViewCommon
import UIKit
import ByteViewMeeting
import ByteViewUI

extension ConstraintPriority {
    static var veryHigh: ConstraintPriority {
        // nolint-next-line: magic number
        return 999.0
    }
}

class TiledLayoutGuideHelper: InMeetLayoutGuideHelper {
    static var topBarHeight: CGFloat {
        return InMeetNavigationBar.contentHeight + VCScene.safeAreaInsets.top
    }
    static let bottomBarHeight: CGFloat = {
        if VCScene.safeAreaInsets.bottom == 0 {
            if Display.phone {
                return 54 + 8
            } else {
                return 64
            }
        } else {
            if Display.phone {
                return 54
            } else {
                return 64
            }
        }
    }()
    static var subtitleHeight: CGFloat {
        return 98
    }

    let storage: UserStorage
    init(storage: UserStorage) {
        self.storage = storage
    }

    var isFlowShrunken: Bool {
        storage.bool(forKey: .isFlowShrunken)
    }

    func updateLayoutGuides(container: InMeetViewContainer) {
        updateTopBarGuide(container: container)
        updateBottomBarGuide(container: container)

        updateInterpreterGuide(container: container)
        updateFullScreenMicGuide(container: container)
    }

    func handleViewChange(_ change: InMeetViewChange, userInfo: Any?, container: InMeetViewContainer) {
        switch change {
        case .topBarHidden:
            updateTopBarGuide(container: container)
        case .bottomBarHidden:
            updateBottomBarGuide(container: container)
        case .singleVideo:
            updateInterpreterGuide(container: container)
            updateFullScreenMicGuide(container: container)
        case .contentScene:
            updateInterpreterGuide(container: container)
        case .subtitle:
            updateInterpreterGuide(container: container)
            updateFullScreenMicGuide(container: container)
        case .fullScreenMicHidden:
            updateFullScreenMicGuide(container: container)
        case .interpretation:
            updateFullScreenMicGuide(container: container)
        default:
            break
        }
    }

    func updateTopBarGuide(container: InMeetViewContainer) {
        let isTopBarHidden = container.context.isTopBarHidden || container.meetingLayoutStyle == .fullscreen
        container.topBarGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            if isTopBarHidden {
                make.height.equalTo(Self.topBarHeight)
                make.bottom.equalTo(container.view.snp.top)
            } else {
                make.top.equalToSuperview()
            }
        }
        container.topBarContentGuide.snp.remakeConstraints { make in
            make.left.right.bottom.equalTo(container.topBarGuide)
            make.height.equalTo(InMeetNavigationBar.contentHeight)
            if !isTopBarHidden {
                // 横屏忙线的时候，如果点击忙线卡片，需要看window的方向
                let hasPending = MeetingManager.shared.sessions.contains(where: { $0.isPending })
                if Display.phone, hasPending, let topConstraint = container.view.window?.safeAreaLayoutGuide.snp.top {
                    make.top.equalTo(topConstraint)
                } else {
                    make.top.equalTo(container.view.safeAreaLayoutGuide.snp.top)
                }

            }
        }
    }

    func updateBottomBarGuide(container: InMeetViewContainer) {
        let isBottomBarHidden = container.context.isBottomBarHidden

        container.bottomBarGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(Self.bottomBarHeight)
            if isBottomBarHidden {
                make.top.equalTo(container.view.snp.bottom)
            } else {
                make.bottom.equalTo(container.view.safeAreaLayoutGuide.snp.bottom).offset(Display.pad ? 3 : 0)
            }
        }
    }

    func updateFullScreenMicGuide(container: InMeetViewContainer) {
        let isInterpreter = container.context.isInterpreter
        let isSubtitleVisible = container.context.isSubtitleVisible

        container.fullScreenMicGuide.snp.remakeConstraints { make in
            if Display.phone {
                make.size.equalTo(CGSize(width: 48.0, height: 48.0))
            } else {
                make.size.equalTo(CGSize(width: 40.0, height: 48.0))
            }

            if isInterpreter, isSubtitleVisible, Display.phone {
                make.right.equalToSuperview().inset(8)
            } else {
                make.centerX.equalToSuperview()
            }

            if container.context.isFullScreenMicHidden {
                make.top.equalTo(container.view.snp.bottom)
            } else if container.context.isSingleVideoVisible {
                let offset = isSubtitleVisible ? -42 - Self.subtitleHeight : -48
                make.bottom.equalTo(container.view.safeAreaLayoutGuide.snp.bottom).offset(offset)
            } else {
                var offset: CGFloat = InMeetFlowComponent.isNewLayoutEnabled ? (Display.iPhoneXSeries ? -16 : -20) : -48
                if isSubtitleVisible {
                    offset -= Self.subtitleHeight - 24
                }

                make.bottom.lessThanOrEqualTo(container.accessoryGuide.snp.bottom).offset(offset)
                make.bottom.equalTo(container.accessoryGuide.snp.bottom).offset(offset).priority(.veryHigh)
            }
        }
    }

    func updateInterpreterGuide(container: InMeetViewContainer) {
        let isSubtitleVisible = container.context.isSubtitleVisible

        container.interpreterGuide.snp.remakeConstraints { make in
            if VCScene.isPhoneLandscape {
                self.updateInterpreterLandscapeLayoutGuide(container: container)
                return
            }

            make.top.left.right.equalTo(container.accessoryGuide)

            let offset: CGFloat = isSubtitleVisible ? -30 - Self.subtitleHeight : -12
            make.bottom.lessThanOrEqualTo(container.accessoryGuide.snp.bottom).offset(offset)
            make.bottom.equalTo(container.accessoryGuide.snp.bottom).offset(offset).priority(.veryHigh)

            if container.context.isSingleVideoVisible {
                let offset: CGFloat = isSubtitleVisible ? -38 - Self.subtitleHeight : -38
                make.bottom.lessThanOrEqualTo(container.view.safeAreaLayoutGuide.snp.bottom).offset(offset)
                make.bottom.equalTo(container.view.safeAreaLayoutGuide.snp.bottom).offset(offset).priority(.veryHigh)
            }
        }
    }

}

/// Landscape Layout
/// - Figma : https://www.figma.com/file/iMMjsepDNRexXHuYA6UHso/
extension TiledLayoutGuideHelper {
    func updateInterpreterLandscapeLayoutGuide(container: InMeetViewContainer) {

        if container.context.meetingScene == .thumbnailRow && container.context.meetingContent == .follow {
            let interpreterHeight = 100.0
            let offsetToShareBar = (interpreterHeight / 2) + 120
            container.interpreterGuide.snp.remakeConstraints { make in
                make.right.equalTo(container.accessoryGuide.snp.right).offset(-4)
                make.centerY.equalTo(container.contentGuide.snp.bottom).offset(-offsetToShareBar)
            }
            return
        }

        container.interpreterGuide.snp.remakeConstraints { make in
            make.right.equalTo(container.accessoryGuide.snp.right).offset(-4)
            make.centerY.lessThanOrEqualTo(container.view.snp.centerY)
        }
    }
}
