//
//  TreeView + SwipGesture.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/8/17.
//
// disable-lint: magic number

import SKFoundation
import SKUIKit
import SKCommon
import SKWorkspace

extension TreeView {
    func setSwipeGestureRecognizer() {
        gestureHandler.delegate = self
        tableView.addGestureRecognizer(doublePanGesture)
        tableView.addGestureRecognizer(rightSwipeGesture)
    }
    
    // 单指右滑
    @objc
    func rightSwipeDidChange(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: tableView)
        guard translation.x > 0, horizonIndicator.swipeDistance > 0 else {
            return
        }
        swipDidChange(sender)
    }
    
    // 双指滑动
    @objc
    func swipDidChange(_ sender: UIPanGestureRecognizer) {
        mutexHelper.listViewDidScroll()
        let _maxHorizonOffset = horizonIndicator.maxHorizonOffset
        if _maxHorizonOffset <= 0, !horizonIndicator.isSwiped {
            //当前一屏没有超过屏幕宽度的节点，且滚动条未有横向滑动偏移，滑动无效
            showHorizonIndicator.onNext(false)
            return
        }
        let offset = sender.translation(in: tableView)
        let dx = offset.x * -1
        var distance = horizonIndicator.swipeDistance
        distance += dx
        if distance < 0 {
            distance = 0
        } else if distance > _maxHorizonOffset {
            distance = _maxHorizonOffset
        }
        let percent = _maxHorizonOffset > 0 ? distance / _maxHorizonOffset : 0
        
        switch sender.state {
        case .changed:
            horizonIndicator.setValue(value: percent)
            showHorizonIndicator.onNext(true)
        case .ended:
            horizonIndicator.updateSwipDistance(distance)
            horizonIndicator.setValue(value: percent)
            showHorizonIndicator.onNext(false)
            if horizonIndicator.swipeDistance <= 0, offset.x > 0 {
                // 左滑到起始位置后更新一次当前一屏的max offset
                horizonIndicator.updateMaxHorizonOffset(maxHorizonOffset)
            }
            WikiStatistic.wikiTreeViewSlideEvent(spaceId: dataBuilder.spaceID)
        default:
            showHorizonIndicator.onNext(false)
            return
        }
    }
}

extension TreeView: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let currentMaxHorizonOffset = maxHorizonOffset
        self.horizonIndicator.updateMaxHorizonOffset(currentMaxHorizonOffset)
        let horizonSize = horizonIndicator.maxHorizonOffset + self.frame.width
        let percent = horizonSize > 0 ? self.frame.width / horizonSize : 1
        self.horizonIndicator.updateIndicatorWidth(indicatorPercent: percent)
        
        if currentMaxHorizonOffset > 0 {
            //当前一屏节点title长度有超过屏幕最大宽度上报
            WikiStatistic.wikiTriggerSlideEvent(spaceID: dataBuilder.spaceID)
        }
    }
}

extension TreeView: TreeViewHorizonIndicatorDelegate {
    func slideAction(_ value: CGFloat) {
        let offset = horizonIndicator.maxHorizonOffset * value * -1
        horizonIndicator.updateCurrentHorizonOffset(offset)
        let cells = tableView.visibleCells
        cells.forEach { cell in
            if let cell = cell as? TreeTableViewCell {
                cell.updateLayout(offset: offset)
            } else if let cell = cell as? TreeTableViewEmptyCell {
                cell.updateLayout(offset: offset)
            } else {
                return
            }
        }
    }
}

extension TreeView: TreePanGestureDelegate {
    var allowHorizontalScroll: Bool {
        let _maxHorizonOffset = horizonIndicator.maxHorizonOffset
        if _maxHorizonOffset <= 0, !horizonIndicator.isSwiped {
            return false
        }
        return true
    }

    var horizontalOffset: CGFloat {
        horizonIndicator.value
    }
}

protocol TreePanGestureDelegate: AnyObject {
    var allowHorizontalScroll: Bool { get }
    var horizontalOffset: CGFloat { get }
}

class TreePanGestureHandler: NSObject, UIGestureRecognizerDelegate {
    private let singlePanGesture: UIPanGestureRecognizer
    private var singlePanEnable: Bool {
        let velocity = singlePanGesture.velocity(in: singlePanGesture.view)
        guard velocity.x > 0, // 单指只允许右滑
              delegate?.allowHorizontalScroll ?? false, // 必须允许横滑
              delegate?.horizontalOffset ?? 0 > 0, // 已经滑动过
              abs(velocity.x) >= abs(velocity.y) else { // 必须是横滑
            return false
        }
        return true
    }

    private let doublePanGesture: UIPanGestureRecognizer
    private var doublePanEnable: Bool {
        delegate?.allowHorizontalScroll ?? false
    }

    weak var delegate: TreePanGestureDelegate?

    private var doublePanTimer: Timer?

    init(singlePanGesture: UIPanGestureRecognizer, doublePanGesture: UIPanGestureRecognizer) {
        self.singlePanGesture = singlePanGesture
        self.doublePanGesture = doublePanGesture
        super.init()
        singlePanGesture.delegate = self
        doublePanGesture.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == singlePanGesture {
            let velocity = singlePanGesture.velocity(in: singlePanGesture.view)

            guard singlePanEnable else {
                return false
            }
        }

        if gestureRecognizer == doublePanGesture {
            doublePanTimer?.invalidate()
            doublePanTimer = nil
            guard doublePanEnable else {
                return false
            }
        }

        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == singlePanGesture {
            if otherGestureRecognizer.view?.isKind(of: SKCustomSlideContentView.self) == true {
                return true
            }
        }

        if gestureRecognizer == doublePanGesture {
            if otherGestureRecognizer.view?.isKind(of: SKCustomSlideContentView.self) == true,
               otherGestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
                if doublePanTimer == nil {
                    let timer = Timer(timeInterval: 0.1, repeats: false) { [weak self] _ in
                        guard let self else { return }
                        self.doublePanGesture.isEnabled = false
                        self.doublePanGesture.isEnabled = true
                        self.doublePanTimer?.invalidate()
                        self.doublePanTimer = nil
                    }
                    doublePanTimer = timer
                    RunLoop.main.add(timer, forMode: .default)
                }
                return true
            }
        }
        return false
    }
}
