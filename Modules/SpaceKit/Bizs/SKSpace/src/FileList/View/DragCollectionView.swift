//
//  DragCollectionView.swift
//  FileList
//
//  Created by vanvanj on 2018/6/22.
//

import UIKit
import SKCommon
import SKFoundation
import SKUIKit

public protocol DragEventDelegate: AnyObject {
    func dragBegin(collectionView: DragCollectionView, fromIndexPath: IndexPath) -> Bool
    func dragEnd(collectionView: DragCollectionView, fromIndexPath: IndexPath, toIndexPath: IndexPath, completion: @escaping ((_ animated: Bool) -> Void))
}

public final class DragCollectionView: UICollectionView {

    let duration = 0.2
    public var edgeScrollRange: CGFloat = 0.0

    public var draggable: Bool = false {
        didSet {
            draggable ? addGestureRecognizer(longPressgesture) : removeGestureRecognizer(longPressgesture)
        }
    }

    weak var dragCell: UIImageView?
    weak var shadowView: UIView?
    weak var previousCell: UICollectionViewCell?
    var edgeScrollDetectTimer: CADisplayLink?
    var dragFromIndexPath: IndexPath?
    lazy fileprivate var longPressgesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(processGesture))
    }()

    public weak var dragCellDelegate: DragEventDelegate?

    public override init(frame: CGRect, collectionViewLayout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)
        backgroundColor = UIColor.ud.N00
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = UIColor.ud.N00
    }

    @objc
    func processGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            gestureBegan(gesture: gesture)
        case .changed:
            if edgeScrollDetectTimer == nil {
                edgeScrollDetectTimer = initTimer()
            }
            edgeScrollDetectTimer?.isPaused = false
            gestureChange(gesture: gesture)
        case .ended:
            stopDetect()
            removeDragCell()
            gestureEnd(gesture: gesture)
        case .failed, .cancelled:
            stopDetect()
            removeDragCell()
            recoverUI(animated: true)
        case .possible:
            DocsLogger.verbose("possible")
        @unknown default:
            stopDetect()
            removeDragCell()
        }
    }

    func initTimer() -> CADisplayLink {
        let link = CADisplayLink(target: self, selector: #selector(processEdgeScroll))
        link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        return link
    }

    // MARK: Gesture Logic handle

    func gestureBegan(gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        guard let indexPath = self.indexPathForItem(at: point),
            let cell = self.cellForItem(at: indexPath) else { return }

        if dragCellDelegate?.dragBegin(collectionView: self, fromIndexPath: indexPath) == false {
            return
        }

        dragFromIndexPath = indexPath

        var imgSize = cell.bounds.size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0)
        UIGraphicsGetCurrentContext().flatMap { cell.layer.render(in: $0) }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        shadowView = {
            let v = UIView(frame: cell.frame)
            v.backgroundColor = UIColor.ud.N00
            v.alpha = 0.5
            addSubview(v)
            return v
        }()

        dragCell = {
            let v = UIImageView(image: img)
            v.alpha = 0.8
            v.layer.shadowColor = UIColor.ud.G300.cgColor // 颜色可能需要调整
            v.layer.masksToBounds = false
            v.layer.cornerRadius = 0
            v.layer.shadowOffset = CGSize(width: -5, height: 0)
            v.layer.shadowOpacity = 0.4
            v.layer.shadowRadius = 5
            v.frame = cell.frame
            addSubview(v)
            return v
        }()

        guard let dragCell = dragCell else { return }

        UIView.animate(withDuration: duration) {
            dragCell.center = CGPoint(x: dragCell.center.x, y: point.y)
        }
    }

    func gestureChange(gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: gesture.view)

        changeCellUI(cell: previousCell, select: false)

        guard let selectedIndexPath = self.indexPathForItem(at: point),
            let dragCell = dragCell else { return }

        //move
        dragCell.center = CGPoint(x: dragCell.center.x, y: point.y)

        //ui update
        if let currentCell = self.cellForItem(at: selectedIndexPath), let dragFromIndexPath = dragFromIndexPath, currentCell != self.cellForItem(at: dragFromIndexPath) {
            changeCellUI(cell: currentCell, select: true)
            previousCell = currentCell
        }
    }

    func gestureEnd(gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        guard let toIndexPath = self.indexPathForItem(at: point), let fromIndexPath = dragFromIndexPath, fromIndexPath != toIndexPath else {
            recoverUI(animated: true)
            return
        }
        dragCellDelegate?.dragEnd(collectionView: self, fromIndexPath: fromIndexPath, toIndexPath: toIndexPath, completion: {[weak self] (animated) in
            self?.recoverUI(animated: animated)
        })
    }

    @objc
    func processEdgeScroll() {
        guard let dragCell = dragCell else { return }
        var edgeScrollRange = self.edgeScrollRange
        if edgeScrollRange == 0 {
            spaceAssertionFailure("edgeScrollRange 不能为 0, 一般为：edgeScrollRange = SKDisplay.realTopBarHeight()")
            // 这么写是为了兜底，不至于线上crash，最多UI顶部有点多余的空白;
            // 防止以后其他人在使用这个View的时候，忘记设置 edgeScrollRange 的初始值
            // 为了不影响写这个View的人的设计初衷，所以没有把 edgeScrollRange 的默认值改为 SKDisplay.realTopBarHeight()
            // by wuwenjian: 没看懂这个值的意义，似乎是防crash，首页重构后，不再使用 DragCollectionView，暂不处理
            edgeScrollRange = 44 + self.safeAreaInsets.top
        }
        gestureChange(gesture: longPressgesture)
        let minOffsetY = contentOffset.y + edgeScrollRange
        let maxOffsetY = contentOffset.y + bounds.size.height - edgeScrollRange
        let touchPoint = dragCell.center
        let maxMoveDistance: CGFloat = 20
        if touchPoint.y < minOffsetY {
            //cell is moving up
            let moveDistance = (minOffsetY - touchPoint.y) / edgeScrollRange * maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - moveDistance), animated: false)
            if contentOffset.y <= 0 ||
                contentOffset.y - 1 < 0 {} else {
                dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y - moveDistance))
            }
        } else if touchPoint.y > maxOffsetY {
            //cell is moving down
            let moveDistance = (touchPoint.y - maxOffsetY) / edgeScrollRange * maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + moveDistance), animated: false)
            if contentOffset.y >= contentSize.height - bounds.size.height ||
                contentOffset.y + 1 > contentSize.height - bounds.size.height {} else {
                dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y + moveDistance))
            }
        }
        if touchPoint.y < edgeScrollRange {
            if contentOffset.y <= 0 ||
                contentOffset.y - 1 < 0 { return }
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - 1), animated: false)
            dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y - 1))
        }
        if touchPoint.y > contentSize.height - edgeScrollRange {
            if contentOffset.y >= contentSize.height - bounds.size.height ||
                contentOffset.y + 1 > contentSize.height - bounds.size.height { return }

            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + 1), animated: false)
            dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y + 1))
        }
        if touchPoint.y < minOffsetY {
            //cell is moving up
            let moveDistance = (minOffsetY - touchPoint.y) / edgeScrollRange * maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y - moveDistance), animated: false)
            dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y - moveDistance))
        } else if touchPoint.y > maxOffsetY {
            //cell is moving down
            let moveDistance = (touchPoint.y - maxOffsetY) / edgeScrollRange * maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y + moveDistance), animated: false)
            dragCell.center = CGPoint(x: dragCell.center.x, y: calculateTargetY(targetY: dragCell.center.y + moveDistance))
        }
    }

    func changeCellUI(cell: UICollectionViewCell?, select: Bool) {
        guard let cell = cell else { return }

        cell.layer.borderWidth = select ? 2 : 0
        cell.layer.borderColor = select ? UIColor.ud.colorfulBlue.withAlphaComponent(0.75).cgColor : UIColor.clear.cgColor
    }

    func removeDragCell() {
        UIView.animate(withDuration: duration, animations: {
            self.dragCell?.alpha = 0
        }, completion: { _ in
            self.dragCell?.removeFromSuperview()
        })
    }

    func recoverUI(animated: Bool) {
        changeCellUI(cell: previousCell, select: false)
        UIView.animate(withDuration: duration, animations: {
            self.shadowView?.alpha = 0
        }, completion: { _ in
            self.shadowView?.removeFromSuperview()
        })
    }

    func stopDetect() {
        edgeScrollDetectTimer?.isPaused = true
        edgeScrollDetectTimer?.invalidate()
        edgeScrollDetectTimer = nil
    }

    func calculateTargetY(targetY: CGFloat) -> CGFloat {
        guard let dragCell = dragCell else { return 0 }
        let minValue = dragCell.bounds.size.height / 2.0
        let maxValue = self.contentSize.height - minValue
        return min(maxValue, max(minValue, targetY))
    }
}
