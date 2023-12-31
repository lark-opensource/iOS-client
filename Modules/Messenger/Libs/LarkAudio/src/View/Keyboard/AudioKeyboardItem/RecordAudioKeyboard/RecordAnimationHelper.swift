//
//  RecordAnimationHelper.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/6/12.
//

import UIKit
import Foundation
import LarkContainer

final class RecordAnimationHelper {

    var floatView: RecordFloatView?
    var deleteIcon: UIImageView?

    let deleteIconWidth: CGFloat = 50
    let floatBarHeight: CGFloat = 60
    let gestureOffset: CGFloat = 60
    let cancelOffset: CGFloat = 40

    var centerOffset: CGFloat {
        return gestureOffset + floatBarHeight / 2
    }
    var deleteIconOffset: CGFloat = 250

    private func deleteIconRect(gestureView: UIView, gesture: UILongPressGestureRecognizer) -> CGRect {
        guard let floatView = self.floatView,
            let superView = floatView.superview else { return .zero }
        let buttonRect = gestureView.convert(gestureView.bounds, to: superView)
        let point = gesture.location(in: superView)
        let floatRect = floatView.frame

        if self.readyToCancel {
            return floatRect
        } else {
            let centerOffset = self.centerOffset
            let floatBarMaxCenterY: CGFloat = buttonRect.top - centerOffset
            let floatBarCenterY: CGFloat = point.y - centerOffset

            let deleteIconOffsetY: CGFloat = max(
                CGFloat(0),
                CGFloat(floatBarMaxCenterY - min(floatBarCenterY, floatBarMaxCenterY)) / CGFloat(2)
            )

            return CGRect(
                x: buttonRect.centerX - deleteIconWidth / 2,
                y: buttonRect.top + deleteIconOffsetY - deleteIconOffset,
                width: deleteIconWidth,
                height: deleteIconWidth)
        }
    }
    private var deleteAnimationDuration: TimeInterval = 0.3
    fileprivate var readyToCancel: Bool = false
    func setReadyToCancel(readyToCancel: Bool, gestureView: UIView, gesture: UILongPressGestureRecognizer) {
        if readyToCancel == self.readyToCancel { return }
        self.readyToCancel = readyToCancel
        if readyToCancel {
            self.floatView?.state = .cancel
            UIView.animate(withDuration: deleteAnimationDuration) {
                self.deleteIcon?.alpha = 0
                self.deleteIcon?.frame = self.floatView?.frame ?? .zero
                self.deleteIcon?.layer.cornerRadius = (self.deleteIcon?.frame.size.height ?? 0) / 2
                self.deleteIcon?.backgroundColor = UIColor.ud.colorfulRed
            }
        } else {
            self.floatView?.state = .normal
            let iconRect = self.deleteIconRect(gestureView: gestureView, gesture: gesture)
            UIView.animate(withDuration: deleteAnimationDuration) {
                self.deleteIcon?.frame = iconRect
                self.deleteIcon?.layer.cornerRadius = iconRect.size.height / 2
                self.deleteIcon?.alpha = 1
                self.deleteIcon?.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.8)
            }
        }
    }

    func showFloatBarView(in superView: UIView, gestureView: UIView, gesture: UILongPressGestureRecognizer, userResolver: UserResolver) {
        let floatView = RecordFloatView(userResolver: userResolver)
        let deleteIcon = self.initDeleteIcon()
        self.floatView = floatView
        self.deleteIcon = deleteIcon
        superView.addSubview(deleteIcon)
        superView.addSubview(floatView)

        let buttonRect = gestureView.convert(gestureView.bounds, to: superView)
        let point = gesture.location(in: superView)
        self.floatView?.snp.makeConstraints({ (maker) in
            maker.center.equalTo(
                CGPoint(
                    x: buttonRect.centerX,
                    y: buttonRect.centerY
                )
            )
        })
        superView.layoutIfNeeded()
        self.floatView?.alpha = 0
        self.floatView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.deleteIcon?.alpha = 0
        self.deleteIcon?.layer.cornerRadius = deleteIconWidth / 2
        self.deleteIcon?.frame = CGRect(
            x: buttonRect.centerX - deleteIconWidth / 2,
            y: buttonRect.top - deleteIconOffset - 40,
            width: deleteIconWidth,
            height: deleteIconWidth
        )
        let center = self.floatViewCenter(buttonRect: buttonRect, gestureInView: point)
        self.floatView?.snp.updateConstraints({ (maker) in
            maker.center.equalTo(center)
        })

        UIView.animate(withDuration: 0.3) {
            self.floatView?.alpha = 1
            self.floatView?.transform = .identity
            self.deleteIcon?.alpha = 1
            self.deleteIcon?.frame = self.deleteIconRect(gestureView: gestureView, gesture: gesture)
            superView.layoutIfNeeded()
        }
    }

    func handleGestureMove(gestureView: UIView, gesture: UILongPressGestureRecognizer) {
        guard let superView = self.floatView?.superview else { return }
        let buttonRect = gestureView.convert(gestureView.bounds, to: superView)
        let point = gesture.location(in: superView)
        let center = self.floatViewCenter(buttonRect: buttonRect, gestureInView: point)
        self.floatView?.snp.updateConstraints({ (maker) in
            maker.center.equalTo(center)
        })
        self.deleteIcon?.frame = self.deleteIconRect(gestureView: gestureView, gesture: gesture)
    }

    func checkReadyToCancel(gestureView: UIView, gesture: UILongPressGestureRecognizer) -> Bool {
        let point = gesture.location(in: gestureView)
        if point.y < -cancelOffset {
            return true
        } else {
            return false
        }
    }

    func removeFloatView() {
        self.floatView?.removeFromSuperview()
        self.deleteIcon?.removeFromSuperview()
        self.floatView = nil
        self.deleteIcon = nil
    }

    private func initDeleteIcon() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.layer.masksToBounds = true
        imageView.image = Resources.recordCancelIcon.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.ud.N200
        imageView.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.8)
        return imageView
    }

    private func floatViewCenter(
        buttonRect: CGRect,
        gestureInView point: CGPoint
    ) -> CGPoint {

        let floatViewY: CGFloat = point.y - centerOffset
        let maxFloatViewY: CGFloat = buttonRect.top - centerOffset
        let minFloatViewY: CGFloat = buttonRect.top - centerOffset - cancelOffset

        return CGPoint(
            x: buttonRect.centerX,
            y: max(min(floatViewY, maxFloatViewY), minFloatViewY)
        )
    }
}
