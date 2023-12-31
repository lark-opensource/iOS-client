//
//  RichViewComponent.swift
//  AsyncComponent
//
//  Created by 白言韬 on 2021/9/28.
//

import UIKit
import Foundation
import LKRichView
import UniverseDesignTheme

public final class RichViewComponentProps: SafeASComponentProps {
    private var _element: LKRichElement?
    public var element: LKRichElement? {
        get {
            return safeRead { self._element }
        }
        set(newValue) {
            safeWrite {
                self._element = newValue
            }
        }
    }
    private var _styleSheets: [CSSStyleSheet] = []
    public var styleSheets: [CSSStyleSheet] {
        get {
            return safeRead {
                self._styleSheets
            }
        }
        set(newValue) {
            safeWrite {
                self._styleSheets = newValue
            }
        }
    }
    public var configOptions: ConfigOptions?
    public weak var delegate: LKRichViewDelegate?
    public var propagationSelectors: [[CSSSelector]] = [] // 冒泡事件，第一维表示有层级关系的标签结构
    public var catchSelectors: [[CSSSelector]] = [] // 捕获事件，第一维表示有层级关系的标签结构
    // 复用时如果需要unbind selector，需要设置true；bind & unbind涉及加锁，大部分情况下需要监听的selector相同，不需要unbind
    public var selectorsNeedUnbind: Bool = false
    public var tag: Int = 0
    public var displayMode: DisplayMode = .auto
}

public final class RichViewComponent<C: Context>: ASComponent<RichViewComponentProps, EmptyState, LKRichContainerView, C> {

    private var core = LKRichViewCore()
    private var coreRWLock = pthread_rwlock_t()

    public override init(props: RichViewComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        pthread_rwlock_init(&coreRWLock, nil)
        core.load(styleSheets: props.styleSheets)
        if let element = props.element {
            let renderer = core.createRenderer(element)
            core.load(renderer: renderer)
        } else {
            core.load(renderer: nil)
        }
        if let configOptions = props.configOptions {
            core.setRendererDebugOptions(configOptions)
        }
    }

    public override func create(_ rect: CGRect) -> LKRichContainerView {
        let container = LKRichContainerView(frame: rect, options: props.configOptions ?? ConfigOptions())
        container.richView.displayMode = props.displayMode
        container.richView.delegate = props.delegate
        container.richView.clipsToBounds = true
        if !props.propagationSelectors.isEmpty {
            container.richView.bindEvent(selectorLists: props.propagationSelectors, isPropagation: true)
        }
        if !props.catchSelectors.isEmpty {
            container.richView.bindEvent(selectorLists: props.catchSelectors, isPropagation: false)
        }
        return container
    }

    public override func update(view: LKRichContainerView) {
        if #available(iOS 13.0, *) {
            view.richView.overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
        }
        super.update(view: view)
        view.richView.displayMode = props.displayMode
        pthread_rwlock_rdlock(&self.coreRWLock)
        let core = self.core
        pthread_rwlock_unlock(&self.coreRWLock)
        let fixSize = self.fixSize(size: core.size)
        core.isTiledCacheValid = (fixSize ~= view.bounds.size)
        view.richView.setRichViewCore(core)
        view.richView.delegate = props.delegate
        view.richView.tag = props.tag
        if props.selectorsNeedUnbind {
            view.richView.unbindAllEvent(isPropagation: true)
            view.richView.unbindAllEvent(isPropagation: false)
            if !props.propagationSelectors.isEmpty {
                view.richView.bindEvent(selectorLists: props.propagationSelectors, isPropagation: true)
            }
            if !props.catchSelectors.isEmpty {
                view.richView.bindEvent(selectorLists: props.catchSelectors, isPropagation: false)
            }
        }
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func willReceiveProps(_ old: RichViewComponentProps, _ new: RichViewComponentProps) -> Bool {
        let core = LKRichViewCore()
        core.load(styleSheets: new.styleSheets)
        if let element = new.element {
            let renderer = core.createRenderer(element)
            core.load(renderer: renderer)
        } else {
            core.load(renderer: nil)
        }
        core.setRendererDebugOptions(new.configOptions)
        pthread_rwlock_wrlock(&self.coreRWLock)
        self.core = core
        pthread_rwlock_unlock(&self.coreRWLock)
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        pthread_rwlock_rdlock(&self.coreRWLock)
        let core = self.core
        pthread_rwlock_unlock(&self.coreRWLock)
        var selfSize = core.layout(size) ?? .zero
        selfSize = fixSize(size: selfSize)
        return selfSize
    }

    // 向上保留一位小数：sizeToFit会调用多次，可能会把上一次计算的size作为container size传入重新计算
    // 在这过程中可能有精度损失，导致文本有折断的中间态而看到闪烁；此处向上保留一位小数兜底
    private func fixSize(size: CGSize) -> CGSize {
        // 最小1，yoga布局问题导致如果返回宽度0，会导致新的一轮计算，进而得到不确定性结果。fix：https://meego.feishu.cn/larksuite/issue/detail/6379821
        return .init(width: max(ceil(size.width * 10) / 10, 1), height: ceil(size.height * 10) / 10)
    }
}

infix operator ~=
func ~= (_ lhs: CGSize, _ rhs: CGSize) -> Bool {
    return abs(lhs.width - rhs.width) <= 1 && abs(lhs.height - rhs.height) <= 1
}
