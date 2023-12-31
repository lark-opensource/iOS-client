//
//  GuideMarkDefaultBodyView.swift
//  LarkChat
//
//  Created by sniperj on 2018/11/21.
//
/*  Easy way to create HintBubbleView
 *  You can easily control the position of the bubble, the position of the small triangle
 *  You don't even have to set the position of the small triangle, the control can adjust the position for you.
 *
 *  Eg:
 *  var preferences = EasyhintBubbleView.globalPreferences
 *  preferences.drawing.arrowPosition = .left
 *  preferences.drawing.textColor = UIColor.white
 *  preferences.drawing.font = UIFont(name: "HelveticaNeue-Light", size: 14)!
 *  preferences.drawing.textAlignment = NSTextAlignment.justified
 *
 *  let text = "this is the easyhintbubbleview!"
 *  let hintbubbleView = EasyhintBubbleView(text: text, preferences: preferences)
 *  hintbubbleView.show(forView: buttonE, withinSuperview: self.navigationController?.view!)
 *
 *  -------------------------------------------
 *  ⎸                                          ⎸
 *  ⎸    this is the easyhintbubbleview!       ⎸
 *  ⎸                                          ⎸
 *  -------------------------------------------
 *                    \/
 *
 */

import Foundation
import UIKit
import CoreGraphics

public final class EasyhintBubbleView: UIView {
    internal var contentText: String
    public var clickBlock: (() -> Void)?
    public fileprivate(set) var preferences: Preferences
    // NOTE: 1.19.0将arrowView暴露，暂时解决群公告需求问题
    public lazy var arrowView: EasyhintbubbleViewArrow = {
        var arrowView = EasyhintbubbleViewArrow(preference: self.preferences)
        return arrowView
    }()

    private var contentView: UIView = UIView()
    private var contentLabel: UILabel = UILabel()
    private let layoutHelper: CustomViewLayoutHelper = CustomViewLayoutHelper()

    fileprivate weak var presentingView: UIView?

    // MARK: lazy initial
    fileprivate lazy var textSize: CGSize = {
        var attributes = [NSAttributedString.Key.font: self.preferences.drawing.font]

        var textSize = self.contentText.boundingRect(
            with: CGSize(
                width: self.preferences.positioning.maxWidth,
                height: CGFloat.greatestFiniteMagnitude),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: attributes,
            context: nil).size

        textSize.width = ceil(textSize.width)
        textSize.height = ceil(textSize.height)

        if textSize.width < self.preferences.drawing.arrowWidth {
            textSize.width = self.preferences.drawing.arrowWidth
        }

        return textSize
    }()

    fileprivate lazy var contentSize: CGSize = {
        var contentSize = CGSize(
            width: self.textSize.width + self.preferences.positioning.textHInset * 2,
            height: self.textSize.height + self.preferences.positioning.textVInset * 2)

        switch self.preferences.drawing.arrowPosition {
        case .top, .bottom:
            contentSize = CGSize(
                width: contentSize.width,
                height: contentSize.height + self.preferences.drawing.arrowHeight)
        case .right, .left:
            contentSize = CGSize(
                width: contentSize.width + self.preferences.drawing.arrowHeight,
                height: contentSize.height)
        case .any:
            contentSize = CGSize(
                width: contentSize.width + self.preferences.drawing.arrowWidth,
                height: contentSize.height + self.preferences.drawing.arrowHeight)
        }

        return contentSize
    }()

    public static var globalPreferences = Preferences()

    public init(text: String, preferences: Preferences = EasyhintBubbleView.globalPreferences) {
        self.preferences = preferences
        self.contentText = text
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
        setupSubviews()
        layoutCustomViews()
        lu.addTapGestureRecognizer(action: #selector(clicked), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding.")
    }

    // MARK: setupsubviews
    private func setupSubviews() {
        contentLabel.text = contentText
        contentLabel.textAlignment = self.preferences.drawing.textAlignment
        contentLabel.textColor = self.preferences.drawing.textColor
        contentLabel.font = self.preferences.drawing.font
        contentLabel.numberOfLines = 0

        contentView.backgroundColor = self.preferences.drawing.backgroundColor
        contentView.layer.cornerRadius = self.preferences.drawing.cornerRadius
        contentView.layer.masksToBounds = true
        contentView.addSubview(contentLabel)
        self.addSubview(contentView)
    }

    private func layoutCustomViews() {
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: contentSize.width,
                            height: contentSize.height)
        contentLabel.frame = CGRect(x: self.preferences.positioning.textHInset,
                                    y: self.preferences.positioning.textVInset,
                                    width: textSize.width,
                                    height: textSize.height)
        contentView.bounds = CGRect(x: 0,
                                    y: 0,
                                    width: contentLabel.frame.width + self.preferences.positioning.textHInset * 2,
                                    height: contentLabel.frame.height + self.preferences.positioning.textVInset * 2)
    }

    // MARK: tipview show logic
    public func show(forView view: UIView, withinSuperview superview: UIView) {
        presentingView = view
        if !isValidArrowPosition(forView: view, arrowPosition: self.preferences.drawing.arrowPosition, superview: superview) {
            setRandomArrowPositionWithSuperview(superview: superview, view: view)
        }
        setShadowIfNeed()
    }

    public func show(forRect rect: CGRect, withinSuperview superview: UIView) {
        if !isValidArrowPosition(refViewFrame: rect, arrowPosition: self.preferences.drawing.arrowPosition, superview: superview) {
            setRandomArrowPositionWithSuperview(superview: superview, rect: rect)
        }
        setShadowIfNeed()
    }

    public func show(focusPosition: CGPoint, withinSuperview superview: UIView) {
        if !show(focusPosition: focusPosition, arrowPosition: self.preferences.drawing.arrowPosition, withinSuperview: superview) {
            setRandomArrowPositionWithSuperview(superview: superview, focusPosition: focusPosition)
        }
        setShadowIfNeed()
    }

    private func setShadowIfNeed() {
        if self.preferences.drawing.isNeedShadow {
            setShadow(
                view: self,
                color: self.preferences.shadow.shadowColor,
                opacity: self.preferences.shadow.shadowOpacity,
                offset: self.preferences.shadow.shadowOffset,
                radius: self.preferences.shadow.shadowRadius)
        }
    }

    public func dismiss() {
        self.removeFromSuperview()
    }

    @discardableResult
    private func show(focusPosition: CGPoint, arrowPosition: ArrowPosition, withinSuperview superview: UIView) -> Bool {
        superview.addSubview(self)

        if isValidArrowPosition(focusPosition: focusPosition, arrowPosition: arrowPosition, superview: superview) {
            // 在这儿才添加arrowview的原因是在show的时候无法确定arrow的方向
            self.addSubview(self.arrowView)
            return true
        } else {
            self.removeFromSuperview()
            return false
        }
    }

    @discardableResult
    private func setRandomArrowPositionWithSuperview(superview: UIView, focusPosition: CGPoint) -> Bool {
        for value in ArrowPosition.allValues where value != self.preferences.drawing.arrowPosition {
            if show(focusPosition: focusPosition, arrowPosition: value, withinSuperview: superview) {
                return true
            }
        }
        return false
    }

    @discardableResult
    private func setRandomArrowPositionWithSuperview(superview: UIView, view: UIView) -> Bool {
        for value in ArrowPosition.allValues where value != self.preferences.drawing.arrowPosition {
            if isValidArrowPosition(forView: view, arrowPosition: value, superview: superview) {
                return true
            }
        }
        return false
    }

    @discardableResult
    private func setRandomArrowPositionWithSuperview(superview: UIView, rect: CGRect) -> Bool {
        for value in ArrowPosition.allValues where value != self.preferences.drawing.arrowPosition {
            if isValidArrowPosition(refViewFrame: rect, arrowPosition: value, superview: superview) {
                return true
            }
        }
        return false
    }

    private func isValidArrowPosition(forView: UIView, arrowPosition: ArrowPosition, superview: UIView) -> Bool {
        let refViewFrame = forView.convert(forView.bounds, to: superview)
        return isValidArrowPosition(refViewFrame: refViewFrame, arrowPosition: arrowPosition, superview: superview)
    }

    private func isValidArrowPosition(refViewFrame: CGRect, arrowPosition: ArrowPosition, superview: UIView) -> Bool {
        switch arrowPosition {
        case .bottom:
            return show(focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width / 2,
                                               y: refViewFrame.origin.y),
                        arrowPosition: arrowPosition,
                        withinSuperview: superview)
        case .top:
            return show(focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width / 2,
                                               y: refViewFrame.origin.y + refViewFrame.height),
                        arrowPosition: arrowPosition,
                        withinSuperview: superview)
        case .right:
            return show(focusPosition: CGPoint(x: refViewFrame.origin.x,
                                               y: refViewFrame.origin.y + refViewFrame.height / 2),
                        arrowPosition: arrowPosition,
                        withinSuperview: superview)
        case .left:
            return show(focusPosition: CGPoint(x: refViewFrame.origin.x + refViewFrame.width,
                                               y: refViewFrame.origin.y + refViewFrame.height / 2),
                        arrowPosition: arrowPosition,
                        withinSuperview: superview)
        case .any:
            return false
        }
    }

    private func isValidArrowPosition(focusPosition: CGPoint, arrowPosition: ArrowPosition, superview: UIView) -> Bool {
        let result = layoutHelper.isValidArrowPosition(targetView: self,
                                                       focusPosition: focusPosition,
                                                       arrowPosition: arrowPosition,
                                                       superview: superview,
                                                       otherInset: self.preferences.positioning.bubbleVInset,
                                                       railingOffset: self.preferences.positioning.railingOffset,
                                                       layoutFinish: { [weak self] in

            guard let self = self else { return }
            switch arrowPosition {
            case .bottom:
                self.preferences.drawing.arrowPosition = arrowPosition
                self.contentView.frame = CGRect(x: 0,
                                                y: 0,
                                                width: self.contentView.frame.width,
                                                height: self.contentView.frame.height)
                let focusPoint = superview.convert(focusPosition, to: self)
                self.arrowView.frame = CGRect(x: focusPoint.x - self.arrowView.frame.width / 2,
                                              y: self.contentView.frame.height,
                                              width: self.arrowView.frame.width,
                                              height: self.arrowView.frame.height)
            case .top:
                self.preferences.drawing.arrowPosition = arrowPosition
                self.contentView.frame = CGRect(x: 0,
                                                y: self.arrowView.frame.height,
                                                width: self.contentView.frame.width,
                                                height: self.contentView.frame.height)
                let focusPoint = superview.convert(focusPosition, to: self)
                self.arrowView.frame = CGRect(x: focusPoint.x - self.arrowView.frame.width / 2,
                                              y: 0,
                                              width: self.arrowView.frame.width,
                                              height: self.arrowView.frame.height)
            case .left:
                self.preferences.drawing.arrowPosition = arrowPosition
                self.contentView.frame = CGRect(x: self.arrowView.frame.width,
                                                y: 0,
                                                width: self.contentView.frame.width,
                                                height: self.contentView.frame.height)
                let focusPoint = superview.convert(focusPosition, to: self)
                self.arrowView.frame = CGRect(x: 0,
                                              y: focusPoint.y - self.arrowView.frame.height / 2,
                                              width: self.arrowView.frame.width,
                                              height: self.arrowView.frame.height)
            case .right:
                self.preferences.drawing.arrowPosition = arrowPosition
                self.contentView.frame = CGRect(x: 0,
                                                y: 0,
                                                width: self.contentView.frame.width,
                                                height: self.contentView.frame.height)
                let focusPoint = superview.convert(focusPosition, to: self)
                self.arrowView.frame = CGRect(x: self.contentView.frame.width,
                                              y: focusPoint.y - self.arrowView.frame.height / 2,
                                              width: self.arrowView.frame.width,
                                              height: self.arrowView.frame.height)
            case .any:
                break
            }
        })

        return result
    }

    // 设置阴影
    func setShadow(view: UIView, color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        view.layer.shadowOffset = offset
        view.layer.shadowOpacity = opacity
        view.layer.shadowColor = color.cgColor
        view.layer.shadowRadius = radius
    }

    @objc
    func clicked() {
        self.clickBlock?()
    }
}
