//
//  ShowMoreMaskViewComponent.swift
//  LarkThread
//
//  Created by qihongye on 2019/3/5.
//

import UIKit
import Foundation
import AsyncComponent

public final class ShowMoreMaskViewComponent<C: AsyncComponent.Context>: ASComponent<ShowMoreMaskViewComponent.Props, EmptyState, ShowMoreMaskView, C> {
    public final class Props: ASComponentProps {
        private var unfairLock = os_unfair_lock_s()
        private var _backgroundColors: [UIColor] = []
        public var backgroundColors: [UIColor] {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _backgroundColors
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _backgroundColors = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _showMoreHandler: (() -> Void)?
        public var showMoreHandler: (() -> Void)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _showMoreHandler
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _showMoreHandler = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return ShowMoreButton.caculatedSize
    }

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    public override func update(view: ShowMoreMaskView) {
        super.update(view: view)
        view.setBackground(colors: props.backgroundColors)
    }
}
