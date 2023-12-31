//
//  TranslateAnimationTapComponent.swift
//  LarkMessageCore
//
//  Created by Patrick on 3/11/2022.
//

import Foundation
import UIKit
import AsyncComponent
import EEFlexiable

public final class TranslateAnimationTapComponent<C: AsyncComponent.Context>: ASComponent<TranslateAnimationTapComponent.Props, EmptyState, TranslateAnimationTapView, C> {
    public final class Props: ASComponentProps {
        public var loopAnimation: Bool = false
        public var autoPlayWhenTap: Bool = false
        public var play: Bool = false
        public var playStart: (() -> Void)?
        public var playCompletion: (() -> Void)?
        public var tapHandler: (() -> Void)?
        public var hitTestEdgeInsets: UIEdgeInsets = .zero
        public var isEnabled = true
        /// 该component的唯一标识符
        public var identifier: String = ""

    }

    public override var isComplex: Bool {
        return true
    }

    public override func update(view: TranslateAnimationTapView) {
        super.update(view: view)
        if !view.identifier.isEmpty,
           !props.identifier.isEmpty,
            view.identifier != props.identifier {
            if view.isAnimationPlaying {
                view.stop()
            }
            view.resetTapGesture()
        }
        view.identifier = props.identifier
        if props.play {
            self.props.playStart?()
            view.play { [weak self] in
                self?.props.playCompletion?()
            }
        } else {
            view.stop()
        }
        var tapPlaying = false
        view.onTapped = { [weak self, unowned view] _ in
            if self?.props.autoPlayWhenTap ?? false {
                if tapPlaying {
                    return
                }
                tapPlaying = true
                self?.props.playStart?()
                view.play { [weak self] in
                    self?.props.playCompletion?()
                    tapPlaying = false
                }
                self?.props.tapHandler?()
            } else {
                self?.props.tapHandler?()
            }
        }
        view.isUserInteractionEnabled = props.isEnabled
    }

    private var tappedView: TranslateAnimationTapView?

    public func play() {
        var tapPlaying = false
        if self.props.autoPlayWhenTap {
            if tapPlaying {
                return
            }
            tapPlaying = true
            props.playStart?()
            tappedView?.play { [weak self] in
                self?.props.playCompletion?()
                tapPlaying = false
            }
        }
    }

    public override func create(_ rect: CGRect) -> TranslateAnimationTapView {
        let view = TranslateAnimationTapView()
        view.initEvent(needLongPress: false)
        view.hitTestEdgeInsets = self.props.hitTestEdgeInsets
        self.tappedView = view
        return view
    }
}
