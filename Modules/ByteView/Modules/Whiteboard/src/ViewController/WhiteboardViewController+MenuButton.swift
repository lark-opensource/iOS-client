//
//  WhiteboardViewController+MenuButton.swift
//  Whiteboard
//
//  Created by helijian on 2023/2/2.
//

import Foundation
import UIKit
import SnapKit
import ByteViewNetwork
import UniverseDesignColor
import ByteViewCommon
import UniverseDesignIcon

extension WhiteboardViewController {

    @objc func handlePan(_ gr: UIPanGestureRecognizer) {
        guard gr.view == showMenuButton, !showMenuButton.isHidden else {
            isDragging = false
            return
        }
        switch gr.state {
        case .began:
            isDragging = true
            if Display.phone { dragbleMargin.bottom = 8 }
            let location = gr.location(in: whiteboardView)
            let origin = self.showMenuButton.frame.origin
            panOffsetX = location.x - origin.x
            panOffsetY = location.y - origin.y
        case .changed:
            guard isDragging else { return }
            let location = gr.location(in: whiteboardView)
            self.showMenuButton.frame.origin = CGPoint(x: location.x - panOffsetX, y: location.y - panOffsetY)
        default:
            guard isDragging else { return }
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: {
                self.fixBoundary()
            }, completion: { _ in
                self.isDragging = false
            })
        }
    }

    private func fixBoundary() {
        switch currentMeetingLayoutStyle {
        case .tiled:
            dragbleMargin.bottom = 8
        case .overlay:
            let inset: CGFloat = Display.pad ? 8 : 48
            dragbleMargin.bottom = view.safeAreaInsets.bottom + bottomBarGuide.layoutFrame.height + inset
        case .fullscreen:
            let inset: CGFloat = Display.pad ? 24 : 16
            dragbleMargin.bottom = view.safeAreaInsets.bottom + inset
        }
        let size = self.showMenuButton.frame.size
        let rect = whiteboardView.bounds.inset(by: dragbleMargin).insetBy(dx: size.width / 2, dy: size.height / 2)
        self.showMenuButton.center.x = showMenuButton.center.x > rect.midX ? rect.maxX : rect.minX
        self.showMenuButton.center.y = max(rect.minY, min(self.showMenuButton.center.y, rect.maxY))
    }

    @objc func didTapMenuButton() {
        self.shouldShowMenuFirst = false
        if !hasActivateTool {
            configDefaultTool(manualy: true)
        }
        self.phoneToolBar.isHidden = false
        self.showMenuButton.isHidden = true
        changeWhiteboardPhoneMenuHiddenStatus(to: false)
    }

    func setShowButtonLayout() {
        if case .ipad = self.viewStyle, Display.pad { return }
        let isTopOnLeft = self.view.orientation == .landscapeRight
        var padding = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
        if Display.iPhoneXSeries {
            let safeAreaInsets = self.view.safeAreaInsets
            if self.view.orientation?.isLandscape ?? false {
                padding = UIEdgeInsets(top: 8, left: 24, bottom: 0, right: 24)
                if isTopOnLeft {
                    padding.left = safeAreaInsets.left
                } else {
                    padding.right = safeAreaInsets.right
                }
            }
        }
        padding.bottom = self.view.safeAreaInsets.bottom
        if !showContentOnly, (shouldShowMenuFirst || !phoneToolBar.isHidden) {
            padding.bottom += (self.view.orientation?.isLandscape ?? false) ? 70 : 134
            showMenuButton.isHidden = true
            phoneToolBar.isHidden = false
        } else {
            if Display.pad, viewStyle == .phone {
                padding.bottom += currentMeetingLayoutStyle == .tiled ? 36 : 56
            } else {
                padding.bottom += (self.view.orientation?.isLandscape ?? false) ? 36 : 40
            }
            showMenuButton.isHidden = (showContentOnly || !canEdit)
            phoneToolBar.isHidden = true
        }
        dragbleMargin = padding
        showMenuButton.snp.remakeConstraints { maker in
            maker.size.equalTo(CGSize(width: 48, height: 48))
            maker.right.equalToSuperview().inset(padding.right)
            if Display.phone {
                let bottomHeight = (self.view.orientation?.isLandscape ?? false) ? 61 : 48
                maker.bottom.equalTo(bottomBarGuide.snp.top).offset(-bottomHeight)
            } else {
                maker.bottom.equalToSuperview().inset(padding.bottom)
            }
        }
    }
}
