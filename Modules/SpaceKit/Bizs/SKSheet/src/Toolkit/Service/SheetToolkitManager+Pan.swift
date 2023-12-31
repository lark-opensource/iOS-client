//
//  SheetToolkitManager+Pan.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/29.
//

import Foundation
import SKBrowser

enum SheetToolkitFloatModel {
    case middle
    case nearlyFull
    case hidden

    var logText: String {
        switch self {
        case .middle:
            return "mid"
        case .hidden:
            return "close"
        case .nearlyFull:
            return "max"
        }
    }
}

typealias FloatModifyFinishBlock = () -> Void

extension SheetToolkitManager: SheetToolkitNavigationControllerGestureDelegate {

    func panBegin(_ point: CGPoint, allowUp: Bool) {
        guard inhibitsDraggability != true else { return }

        beginPoint = point
    }

    func panMove(_ point: CGPoint, allowUp: Bool) {
        guard inhibitsDraggability != true else { return }

        let offsetY = (point.y - beginPoint.y)
        guard let dstView = navigationController?.view else { return }
        fabButtonPanel?.isHidden = true
        var wantedPanelY = dstView.frame.minY + offsetY
        let btnOldFrame = quickKeyboardBtn?.frame ?? CGRect.zero
        var wantedButtonY = btnOldFrame.minY + offsetY
        if !allowUp, wantedPanelY < defaultRect.minY {
            wantedPanelY = defaultRect.minY
            wantedButtonY = assistButtonDefaultRect.minY
        }
        //高度，最低不能小于默认的高度
        var height = superHeight - wantedPanelY
        height = max(height, defaultRect.height)
        if wantedPanelY > nearlyFullRect.minY {
            // dstView y和height在滑动过程中需要实时更新，只在panEnd更新会导致工具栏内部collectionView出现奇怪偏移现象
            dstView.frame = CGRect(x: dstView.frame.minX, y: wantedPanelY, width: dstView.frame.width, height: height)
            backView.frame = CGRect(origin: CGPoint(x: 0, y: dstView.frame.origin.y), size: CGSize(width: backView.frame.size.width, height: height))
            if let btn = quickKeyboardBtn {
                btn.frame = CGRect(x: btnOldFrame.minX, y: wantedButtonY, width: btnOldFrame.width, height: btnOldFrame.height)
            }
        }
    }

    func panEnd(_ point: CGPoint, allowUp: Bool) {
        guard inhibitsDraggability != true else { return }

        guard let endRect = navigationController?.view.frame, endRect != defaultRect else { return }
        let nextModel = panEndNextModel(endRect: endRect)
        switchToFloatModel(model: nextModel)
        //回调
        delegate?.adjustPanelModel(nextModel, fromToolkit: isShowingToolkit(), manager: self)
        //收起键盘
        if nextModel == .middle, let conditionFilterVC = filterVC as? SheetFilterByConditionController {
            conditionFilterVC.endTextEditing()
        }
        //收起键盘
        if let valueFilterVC = filterVC as? SheetFilterByValueViewController {
            if nextModel == .middle {
                valueFilterVC.exitSearch()
                valueFilterVC.switchDisplayMode(.normal)
            } else if nextModel == .nearlyFull {
                valueFilterVC.switchDisplayMode(.spread)
            }
        }

    }

    func tapToExit() {
        hideToolkitView()
    }

}

extension SheetToolkitManager {
    func panEndNextModel(endRect: CGRect) -> SheetToolkitFloatModel {
        if endRect.minY >= defaultRect.minY {
            if endRect.minY - defaultRect.minY > 20 {
                return .hidden
            } else {
                return .middle
            }
        } else {
            let spaceHeight = nearlyFullRect.height - defaultRect.height
            if defaultRect.minY - endRect.minY > spaceHeight / 2 {
                return .nearlyFull
            } else {
                return .middle
            }
        }
    }

    func switchToFloatModel(model: SheetToolkitFloatModel, completed: FloatModifyFinishBlock? = nil) {
        if model == .hidden {
            hideToolkitView()
            SheetTracker.report(event: .closeToolbox(action: 0), docsInfo: self.docsInfo)
        } else {
            var rect = self.defaultRect
            rect.origin.x = navigationController?.view.frame.minX ?? self.defaultRect.minX
            rect.size.width = navigationController?.view.frame.size.width ?? self.defaultRect.width
            var buttonRect = self.assistButtonDefaultRect
            switch model {
            case .middle:
                rect = self.defaultRect
                rect.origin.x = navigationController?.view.frame.minX ?? self.defaultRect.minX
                rect.size.width = navigationController?.view.frame.size.width ?? self.defaultRect.width
                buttonRect = self.assistButtonDefaultRect
            case .nearlyFull:
                rect = self.nearlyFullRect
                rect.origin.x = navigationController?.view.frame.minX ?? self.nearlyFullRect.minX
                rect.size.width = navigationController?.view.frame.size.width ?? self.nearlyFullRect.width
                buttonRect = self.assistButtonMaxRect
            case .hidden:
                ()
            }
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.navigationController?.view.frame = rect
                self.backView.frame = CGRect(origin: CGPoint(x: 0, y: rect.origin.y), size: CGSize(width: self.backView.frame.size.width, height: rect.size.height))
                self.quickKeyboardBtn?.frame = buttonRect
                //self.navigationController?.view.superview?.layoutIfNeeded()
            }, completion: { [weak self] _ in
                self?.navigationController?.preferredContentSize = CGSize(width: rect.width, height: rect.height)
                completed?()
            })
        }
    }

    func currentFloatModel() -> SheetToolkitFloatModel {
        guard let navigationBar = navigationController?.view else { return .hidden }
        if navigationBar.frame.height == defaultRect.height {
            return .middle
        } else if navigationBar.frame.height == nearlyFullRect.height {
            return .nearlyFull
        } else {
            return .hidden
        }
    }
}
