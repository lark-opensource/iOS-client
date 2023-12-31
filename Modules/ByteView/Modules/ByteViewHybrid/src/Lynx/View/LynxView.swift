//
// Created by maozhixiang.lip on 2022/10/19.
//

import Foundation
import BDXLynxKit
import Lynx

typealias LynxKitView = UIView & BDXLynxViewProtocol
typealias LynxViewLifecycleDelegate = BDXKitViewLifecycleProtocol

final class LynxView: UIView {
    struct Context {
        var params: BDXLynxKitParams
        var imageFetcher: LynxImageFetcher?
        var templateProvider: LynxTemplateProvider?
    }

    private let kitView: LynxKitView?
    private let context: Context
    private var theme: String = ""
    private var ready: Bool = false

    override var bounds: CGRect {
        didSet {
            guard bounds != oldValue else { return }
            self.kitView?.frame = CGRect(origin: .zero, size: bounds.size)
            self.kitView?.triggerLayout()
        }
    }

    init(kitView: LynxKitView, context: Context) {
        self.kitView = kitView
        self.context = context
        super.init(frame: .zero)
        self.addSubview(kitView)
        self.updateTheme() // TODO @maozhixiang.lip : init theme?
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: self.traitCollection) ?? false {
                self.updateTheme()
            }
        }
    }

    func sendEvent(name: String, params: [String: Any]) {
        self.kitView?.sendEvent(name, params: params)
    }

    func load() {
        Logger.lynx.info("load view")
        self.kitView?.load()
        self.ready = true
    }

    func updateGlobalProps(_ props: [String: Any], needReload: Bool) {
        let params = self.context.params
        (params.globalProps as? LynxTemplateData)?.update(with: props)
        self.kitView?.config(with: params)
        if needReload { self.reload() }
    }

    private func updateTheme() {
        let themeKey = "appTheme"
        var theme = "light"
        if #available(iOS 12.0, *), self.traitCollection.userInterfaceStyle == .dark { theme = "dark" }
        guard self.theme != theme else { return }
        defer { self.theme = theme }
        Logger.lynx.info("updateTheme, theme = \(theme)")
        (self.context.params.globalProps as? LynxTemplateData)?.update(theme, forKey: themeKey)
        self.kitView?.updateAppTheme?(withKey: themeKey, value: theme)
        self.reload()
    }

    private func reload() {
        guard self.ready else { return }
        Logger.lynx.info("reload view")
        self.kitView?.load()
    }
}
