//
//  ThemeMonitor.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/6/9.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignFont
import UniverseDesignTheme

public struct ThemeConfig {
    let backgroundColor: UIColor
    let foregroundFontColor: UIColor
    let linkColor: UIColor
    let listMarkerColor: UIColor
    public init(backgroundColor: UIColor,
                foregroundFontColor: UIColor,
                linkColor: UIColor,
                listMarkerColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.foregroundFontColor = foregroundFontColor
        self.linkColor = linkColor
        self.listMarkerColor = listMarkerColor
    }
}

/// 监听主题变化（Light/Dark）Mode，属于过渡方案，之后逻辑都应该放在DocSDK里面
public final class ThemeMonitor {

    private typealias RGBComponents = (red: CGFloat, green: CGFloat, blue: CGFloat)
    private typealias RGBAComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)

    private weak var webView: RichTextWebViewType?
    private weak var editor: RichTextEditorInterface?

    public var themeConfig: ThemeConfig {
        didSet {
            refreshStyle()
        }
    }
    let bag = DisposeBag()

    init(webView: RichTextWebViewType,
         editor: RichTextEditorInterface,
         themeConfig: ThemeConfig? = nil) {
        self.webView = webView
        self.editor = editor
        self.themeConfig = themeConfig ?? ThemeConfig(backgroundColor: UIColor.clear,
                                                      foregroundFontColor: UIColor.ud.textTitle,
                                                      linkColor: .ud.textLinkNormal,
                                                      listMarkerColor: .ud.primaryContentDefault)

        observeThemeChanged()
    }

    /// 这个通知不靠谱，在app设置跟随系统下，直接切换系统的Light/Dark并不会走这个通知
    private func observeThemeChanged() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.rx
                .notification(UDThemeManager.didChangeNotification)
                .observeOn(MainScheduler.instance)
                .delay(0.2, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.refreshStyle()
                }).disposed(by: bag)
        }
    }

    func refreshStyle() {
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            correctTrait.performAsCurrent {
                var style = DocsRichTextParam.AditStyle()
                style.color = Self.transformToRGBStr(from: self.themeConfig.foregroundFontColor)
                style.background = Self.transformToRGBAStr(from: self.themeConfig.backgroundColor)
                style.linkColor = Self.transformToRGBStr(from: self.themeConfig.linkColor)
                style.listMarkerColor = Self.transformToRGBStr(from: self.themeConfig.listMarkerColor)
                style.isSysBold = UDFontAppearance.isBoldTextEnabled
                self.editor?.setStyle(style, success: nil, fail: { _ in })

                self.webView?.evaluateJavaScript("document.body.style.backgroundColor=\"\(webViewBackgroundColorHex)\"", completionHandler: nil)
            }
        }
        webView?.backgroundColor = self.themeConfig.backgroundColor
        webView?.isOpaque = false
    }

    private static func transformToRGBStr(from color: UIColor) -> String {
        var components: RGBComponents = (0, 0, 0)
        color.getRed(&components.red, green: &components.green, blue: &components.blue, alpha: nil)
        let rgbStr = "rgb(\(components.red * 255.0),\(components.green * 255.0),\(components.blue * 255.0))"
        return rgbStr
    }

    private static func transformToRGBAStr(from color: UIColor) -> String {
        var components: RGBAComponents = (0, 0, 0, 0)
        color.getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)
        let rgbaStr = "rgba(\(components.red * 255.0),\(components.green * 255.0),\(components.blue * 255.0),\(components.alpha * 255.0))"
        return rgbaStr
    }

    var webViewBackgroundColorHex: String {
        self.themeConfig.backgroundColor.hex8 ?? "#ffffffff"
    }
}
