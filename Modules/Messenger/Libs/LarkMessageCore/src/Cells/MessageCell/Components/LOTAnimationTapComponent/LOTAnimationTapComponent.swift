//
//  LOTAnimationTapComponent.swift
//  LarkThread
//
//  Created by zc09v on 2019/7/22.
//

import Foundation
import UIKit
import AsyncComponent
import EEFlexiable

public final class LOTAnimationTapComponent<C: AsyncComponent.Context>: ASComponent<LOTAnimationTapComponent.Props, EmptyState, LOTAnimationTapView, C> {
    public final class Props: ASComponentProps {
        //filepath lightmode总是用animationFilePath，darkmode有animationFilePathDarkMode则用
        //animationFilePathDarkMode，没有则用animationFilePath
        public var animationFilePath: String = ""
        public var animationFilePathDarkMode: String?
        public var loopAnimation: Bool = false
        public var autoPlayWhenTap: Bool = false
        public var play: Bool = false
        public var playStart: (() -> Void)?
        public var playCompletion: (() -> Void)?
        public var tapHandler: (() -> Void)?
        public var hitTestEdgeInsets: UIEdgeInsets = .zero
        public var isEnabled = true
        public var imageDisabled: UIImage?
        /// 该component的唯一标识符
        public var identifier: String = ""

    }

    public override var isComplex: Bool {
        return true
    }

    public override func update(view: LOTAnimationTapView) {
        super.update(view: view)
        view.animationView.loopAnimation = props.loopAnimation
        if !view.identifier.isEmpty,
           !props.identifier.isEmpty,
            view.identifier != props.identifier {
            if view.animationView.isAnimationPlaying {
                view.animationView.stop()
            }
            view.resetTapGesture()
        }
        view.identifier = props.identifier
        if props.play {
            self.props.playStart?()
            view.animationView.play { [weak self] (_) in
                self?.props.playCompletion?()
            }
        } else {
            view.animationView.stop()
        }
        var tapPlaying = false
        view.onTapped = { [weak self, unowned view] _ in
            if self?.props.autoPlayWhenTap ?? false {
                if tapPlaying {
                    return
                }
                tapPlaying = true
                self?.props.playStart?()
                view.animationView.play { [weak self] (_) in
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

    private var tappedView: LOTAnimationTapView?

    public func play() {
        var tapPlaying = false
        if self.props.autoPlayWhenTap {
            if tapPlaying {
                return
            }
            tapPlaying = true
            props.playStart?()
            tappedView?.animationView.play { [weak self] (_) in
                self?.props.playCompletion?()
                tapPlaying = false
            }
        }
    }

    public override func create(_ rect: CGRect) -> LOTAnimationTapView {
        let view = LOTAnimationTapView(frame: rect, filePathLight: props.animationFilePath, filePathDark: props.animationFilePathDarkMode)
        view.setImageForDisabled(props.imageDisabled)
        view.initEvent(needLongPress: false)
        view.hitTestEdgeInsets = self.props.hitTestEdgeInsets
        self.tappedView = view
        return view
    }
}
