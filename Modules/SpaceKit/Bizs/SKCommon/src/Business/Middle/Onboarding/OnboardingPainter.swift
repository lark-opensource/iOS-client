//
// Created by duanxiaochen.7 on 2019/11/4.
// Affiliated with SpaceKit.
//
// Description: OnboardingPainter is responsible for the assembly, display and disposal of an onboarding view.
//

import Lottie
import SKUIKit
import SKFoundation

enum OnboardingPainter {
    static func generateTitleAttrString(titled str: String?, maxWidth: CGFloat) -> NSAttributedString? {
        guard let str = str else { return nil }
        let (attrTitleString, _) = str.attrString(withAttributes: OnboardingStyle.titleAttributes, boundedBy: maxWidth)
        return attrTitleString
    }

    static func generateHintAttrString(titled str: String?, maxWidth: CGFloat) -> NSAttributedString? {
        guard let str = str else { return nil }
        let (attrHintString, _) = str.attrString(withAttributes: OnboardingStyle.hintAttributes, boundedBy: maxWidth)
        return attrHintString
    }

    static func generateHollow(withStyle style: OnboardingStyle.Hollow?,
                               rect: CGRect?,
                               bleeding: CGFloat?) -> (rect: CGRect, cornerRadius: CGFloat) {
        guard let style = style, let rect = rect, let bleeding = bleeding else { return (.zero, .zero) }
        var targetRect = CGRect(
            x: rect.origin.x - bleeding,
            y: rect.origin.y - bleeding,
            width: rect.size.width + bleeding * 2,
            height: rect.size.height + bleeding * 2
        )
        let targetCornerRadius: CGFloat
        switch style {
        case .circle:
            let minLength = min(targetRect.width, targetRect.height)
            var square = CGRect(x: 0, y: 0, width: minLength, height: minLength)
            square.center = targetRect.center
            targetRect = square
            targetCornerRadius = minLength / 2
        case .capsule:
            targetCornerRadius = targetRect.height / 2
        case .roundedRect(let cornerRadius):
            targetCornerRadius = cornerRadius
        }
        return (targetRect, targetCornerRadius)
    }

    static func determineTargetPoint(targetRect: CGRect?,
                                     hostViewBounds: CGRect?,
                                     designatedPointingDirection: OnboardingStyle.ArrowDirection?) -> (CGPoint, OnboardingStyle.ArrowDirection) {
        guard let targetRect = targetRect,
              let hostViewBounds = hostViewBounds,
              let designatedPointingDirection = designatedPointingDirection else {
            return (.zero, .targetTopEdge)
        }
        // 溢出屏幕边界处理
        let targetPointMaxX = hostViewBounds.maxX - OnboardingStyle.arrowLayoutMargin - OnboardingStyle.arrowSize.width / 2
        let targetPointMinX = hostViewBounds.minX + OnboardingStyle.arrowLayoutMargin + OnboardingStyle.arrowSize.width / 2
        let targetPointMaxY = hostViewBounds.maxY - OnboardingStyle.arrowLayoutMargin - OnboardingStyle.arrowSize.width / 2
        let targetPointMinY = hostViewBounds.minY + OnboardingStyle.arrowLayoutMargin + OnboardingStyle.arrowSize.width / 2

        func bottomEdge(_ rect: CGRect, _ hostBounds: CGRect) -> (CGPoint, OnboardingStyle.ArrowDirection) {
            if rect.midX > hostBounds.maxX { // target rect 超出 host view 右边界
                let boundedPoint = CGPoint(x: targetPointMaxX, y: rect.maxY)
                return (boundedPoint, .targetBottomEdge)
            } else if rect.midX < hostBounds.minX { // target rect 超出 host view 左边界
                let boundedPoint = CGPoint(x: targetPointMinX, y: rect.maxY)
                return (boundedPoint, .targetBottomEdge)
            } else {
                return (rect.bottomCenter, .targetBottomEdge)
            }
        }

        func topEdge(_ rect: CGRect, _ hostBounds: CGRect) -> (CGPoint, OnboardingStyle.ArrowDirection) {
            if rect.midX > hostBounds.maxX { // target rect 超出 host view 右边界
                let boundedPoint = CGPoint(x: targetPointMaxX, y: rect.minY)
                return (boundedPoint, .targetTopEdge)
            } else if rect.midX < hostBounds.minX { // target rect 超出 host view 左边界
                let boundedPoint = CGPoint(x: targetPointMinX, y: rect.minY)
                return (boundedPoint, .targetTopEdge)
            } else {
                return (rect.topCenter, .targetTopEdge)
            }
        }

        func trailingEdge(_ rect: CGRect, _ hostBounds: CGRect) -> (CGPoint, OnboardingStyle.ArrowDirection) {
            if rect.midY > hostBounds.maxY { // target rect 超出 host view 下边界
                let boundedPoint = CGPoint(x: rect.maxX, y: targetPointMaxY)
                return (boundedPoint, .targetTrailingEdge)
            } else if rect.midY < hostBounds.minY { // target rect 超出 host view 上边界
                let boundedPoint = CGPoint(x: rect.maxX, y: targetPointMinY)
                return (boundedPoint, .targetTrailingEdge)
            } else {
                return (rect.centerRight, .targetTrailingEdge)
            }
        }

        func leadingEdge(_ rect: CGRect, _ hostBounds: CGRect) -> (CGPoint, OnboardingStyle.ArrowDirection) {
            if rect.midY > hostBounds.maxY { // target rect 超出 host view 下边界
                let boundedPoint = CGPoint(x: rect.minX, y: targetPointMaxY)
                return (boundedPoint, .targetLeadingEdge)
            } else if rect.midY < hostBounds.minY { // target rect 超出 host view 上边界
                let boundedPoint = CGPoint(x: rect.minX, y: targetPointMinY)
                return (boundedPoint, .targetLeadingEdge)
            } else {
                return (rect.centerLeft, .targetLeadingEdge)
            }
        }

        switch designatedPointingDirection {
        case .targetBottomEdge:
            return bottomEdge(targetRect, hostViewBounds)
        case .targetTopEdge:
            return topEdge(targetRect, hostViewBounds)
        case .targetTrailingEdge:
            return trailingEdge(targetRect, hostViewBounds)
        case .targetLeadingEdge:
            return leadingEdge(targetRect, hostViewBounds)
        }
    }
}
