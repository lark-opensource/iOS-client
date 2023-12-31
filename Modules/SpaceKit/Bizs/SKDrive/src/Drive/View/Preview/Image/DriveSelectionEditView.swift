//
//  DriveSelectionCommentView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/5.
//

import UIKit
import UniverseDesignColor

class DriveSelectionEditView: UIView {
    var activeAreaView: DriveSelectionView?
    var activeArea: DriveAreaComment.Area?
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.staticBlack.withAlphaComponent(0.7)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        if let view = activeAreaView, let area = activeArea {
            view.selectionFrame = area.areaFrame(in: self)
            mask(rect: view.selectionFrame.insetBy(dx: 2, dy: 2))
        }
    }
    func addArea(_ area: DriveAreaComment.Area, view: DriveSelectionView) {
        if let view = activeAreaView {
            view.removeFromSuperview()
        }
        activeAreaView = view
        let originFrame = area.areaFrame(in: self)
        var newFrame = constrainMoveRect(originFrame)
        newFrame = constrainResizeRect(newFrame)
        activeArea = newFrame.relativeArea(in: self.frame)
        view.selectionFrame = newFrame
        view.delegate = self
        self.addSubview(view)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = activeAreaView else {
            return nil
        }
        if view.frame.contains(point) {
            return view
        }
        return nil
    }
}

extension DriveSelectionEditView: DriveSelectionViewDelegate {
    func selectionView(_ view: DriveSelectionView,
                       panPositon: PanPosition,
                       gesture: UIPanGestureRecognizer) {
        let vector = gesture.translation(in: self)
        switch panPositon {
        case .center:
            var newFrame = view.selectionFrame
            newFrame.center = CGPoint(x: view.center.x + vector.x,
                                      y: view.center.y + vector.y)
            view.selectionFrame = constrainMoveRect(newFrame)
        case .topLeft:
            var changeVector = vector
            if view.selectionFrame.size.height - vector.y < view.minSize.height {
                changeVector.y = 0
            }
            if view.selectionFrame.size.width - vector.x < view.minSize.width {
                changeVector.x = 0
            }
            let origin = CGPoint(x: view.selectionFrame.origin.x + changeVector.x,
                                 y: view.selectionFrame.origin.y + changeVector.y)
            let size = CGSize(width: view.selectionFrame.size.width - changeVector.x,
                              height: view.selectionFrame.size.height - changeVector.y)
            let newFrame = CGRect(origin: origin, size: maxSize(size, view.minSize))
            view.selectionFrame = constrainResizeRect(newFrame)
        case .topRight:
            var changeVector = vector
            if view.selectionFrame.size.height - vector.y < view.minSize.height {
                changeVector.y = 0
            }
            if view.selectionFrame.size.width + vector.x < view.minSize.width {
                changeVector.x = 0
            }
            let origin = CGPoint(x: view.selectionFrame.origin.x,
                                 y: view.selectionFrame.origin.y + changeVector.y)
            let size = CGSize(width: view.selectionFrame.size.width + changeVector.x,
                              height: view.selectionFrame.size.height - changeVector.y)
            let newFrame = CGRect(origin: origin, size: maxSize(size, view.minSize))
            view.selectionFrame = constrainResizeRect(newFrame)
        case .bottomLeft:
            var changeVector = vector
            if view.selectionFrame.size.height + vector.y < view.minSize.height {
                changeVector.y = 0
            }
            if view.selectionFrame.size.width - vector.x < view.minSize.width {
                changeVector.x = 0
            }

            let origin = CGPoint(x: view.selectionFrame.origin.x + changeVector.x,
                                 y: view.selectionFrame.origin.y)
            let size = CGSize(width: view.selectionFrame.size.width - changeVector.x,
                              height: view.selectionFrame.size.height + changeVector.y)
            let newFrame = CGRect(origin: origin, size: maxSize(size, view.minSize))
            view.selectionFrame = constrainResizeRect(newFrame)
        case .bottomRight:
            var changeVector = vector
            if view.selectionFrame.size.height + vector.y < view.minSize.height {
                changeVector.y = 0
            }
            if view.selectionFrame.size.width + vector.x < view.minSize.width {
                changeVector.x = 0
            }

            let origin = CGPoint(x: view.selectionFrame.origin.x,
                                 y: view.selectionFrame.origin.y)
            let size = CGSize(width: view.selectionFrame.size.width + changeVector.x,
                              height: view.selectionFrame.size.height + changeVector.y)
            let newFrame = CGRect(origin: origin, size: maxSize(size, view.minSize))
            view.selectionFrame = constrainResizeRect(newFrame)
        default:
            break
        }
        activeArea = view.selectionFrame.relativeArea(in: self.frame)
        mask(rect: view.selectionFrame.insetBy(dx: 2, dy: 2))
        gesture.setTranslation(CGPoint.zero, in: self)
    }
}

// MARK: - Helper
extension DriveSelectionEditView {
    func maxSize(_ x: CGSize, _ y: CGSize) -> CGSize {
        let minWidth = max(x.width, y.width)
        let minHeight = max(x.height, y.height)
        return CGSize(width: minWidth, height: minHeight)
    }
    func constrainMoveRect(_ originRect: CGRect) -> CGRect {
        var newRect = originRect
        if newRect.origin.x < 0 {
            newRect.origin.x = 0
        } else if newRect.origin.x + newRect.width > self.frame.width {
            newRect.origin.x = self.frame.width - newRect.width
        }
        if newRect.origin.y < 0 {
            newRect.origin.y = 0
        } else if newRect.origin.y + newRect.height > self.frame.height {
            newRect.origin.y = self.frame.height - newRect.height
        }
        return newRect
    }

    /// 保证拖动四个角调整大小不超出图片区域
    func constrainResizeRect(_ originRect: CGRect) -> CGRect {
        guard activeAreaView?.minSize != nil else {
            return originRect
        }
        var newRect = originRect
        if newRect.origin.x < 0 {
            newRect.origin.x = 0
        }
        if newRect.width > self.frame.width {
            newRect.size.width = self.frame.width
        }

        if newRect.origin.x + newRect.width > self.frame.width {
            newRect.origin.x = self.frame.width - newRect.width
        }
        if newRect.origin.y < 0 {
            newRect.origin.y = 0
        }
        if newRect.height > self.frame.height {
            newRect.size.height = self.frame.height
        }
        if newRect.origin.y + newRect.height > self.frame.height {
            newRect.origin.y = self.frame.height - newRect.height
        }
        return newRect
    }
}

extension UIView {
    func mask(rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()
        path.append(UIBezierPath(rect: self.bounds))
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }
    func clearMask() {
        self.layer.mask = nil
    }
}
