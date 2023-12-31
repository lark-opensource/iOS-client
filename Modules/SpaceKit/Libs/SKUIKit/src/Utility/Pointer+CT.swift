//
//  Pointer+CT.swift
//  SKUIKit
//
//  Created by 邱沛 on 2021/1/9.
//

import LarkInteraction
import SKFoundation
import RxSwift
import RxCocoa

extension DocsExtension where BaseType: UIView {

    /// default hover
    public func addStandardHover() {
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(style: .init(effect: .hover(prefersScaledContent: false)))
            self.base.addLKInteraction(pointer)
        }
    }

    /// hover with color, shadow, scale
    /// - Parameters:
    ///   - color: background color
    ///   - prefersShadow: should show shadow
    ///   - prefersScaledContent: should be scaled
    ///   - disposeBag: managered by view life cycle
    public func addHover(with color: UIColor,
                         disposeBag: DisposeBag) {
        if #available(iOS 13.4, *) {
            let ges = UIHoverGestureRecognizer()
            let uiState = self.base.backgroundColor
            let view = self.base
            ges.rx.event.subscribe(onNext: { [weak view] (ges) in
                switch ges.state {
                case .began, .changed:
                    view?.backgroundColor = color
                case .ended, .cancelled:
                    view?.backgroundColor = uiState
                default:
                    break
                }
            }).disposed(by: disposeBag)
            self.base.addGestureRecognizer(ges)
        }
    }

    /// custom hover. Not recommended!
    /// - Parameter interaction: give a custom pointer interaction
    /// - Returns: the action of hover gesture
    @available(iOS 13.0, *)
    public func addHover(with interaction: Interaction) -> Observable<UIHoverGestureRecognizer> {
        let ges = UIHoverGestureRecognizer()
        self.base.addGestureRecognizer(ges)
        self.base.addLKInteraction(interaction)
        return ges.rx.event.asObservable()
    }

    /// default highlight with 8px padding, used by element with border
    public func addStandardHighlight() {
        self.base.addPointer(
            PointerInfo(effect: .highlight,
                        shape: { (size) -> PointerInfo.ShapeSizeInfo in
                            (CGSize(width: size.width + 16, height: size.height + 16), 8)
                        })
        )
    }

    /// custom highlight with edgeInsets, radius
    /// - Parameters:
    ///   - edgeInsets: custom the additional area size
    ///   - radius: custom the radius size
    public func addHighlight(with edgeInsets: UIEdgeInsets,
                             radius: CGFloat) {
        self.base.addPointer(
            PointerInfo(effect: .highlight,
                        shape: { (size) -> PointerInfo.ShapeSizeInfo in
                            (CGSize(width: size.width - edgeInsets.left - edgeInsets.right,
                                    height: size.height - edgeInsets.top - edgeInsets.bottom),
                             radius)
                        })
        )
    }

//    /// custom highlight. Not recommended!
//    /// - Parameters:
//    ///   - shape: custom the pointer shape
//    ///   - targetView: custom the highlighted view
//    public func addHighlight(shape: @escaping (_ origin: CGSize) -> PointerInfo.ShapeSizeInfo,
//                             targetView: ((UIView) -> UIView)?) {
//        self.base.addPointer(
//            PointerInfo(effect: .highlight,
//                        shape: shape,
//                        targetView: targetView)
//        )
//    }

    /// default lift
    public func addStandardLift() {
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(style: .init(effect: .lift))
            self.base.addLKInteraction(pointer)
        }
    }

//    /// custom lift. Not recommended!
//    /// - Parameters:
//    ///   - shape: custom the pointer shape
//    ///   - targetView: custom the lifted view
//    public func addLift(shape: @escaping (_ origin: CGSize) -> PointerInfo.ShapeSizeInfo,
//                        targetView: ((UIView) -> UIView)?) {
//        self.base.addPointer(
//            PointerInfo(effect: .lift,
//                        shape: shape,
//                        targetView: targetView)
//        )
//    }

    public func removeAllPointer() {
        self.base.lkInteractions.forEach({
            self.base.removeLKInteraction($0)
        })
    }
}
