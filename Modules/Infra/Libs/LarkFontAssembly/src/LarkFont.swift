//
//  LarkFontAssembly.swift
//  LarkFont
//
//  Created by 白镜吾 on 2023/3/9.
//

import UniverseDesignFont
import LarkLocalizations
import LarkFeatureGating
import LarkSetting

public final class LarkFont: NSObject {
    public static var shared: LarkFont = LarkFont()

    public override init() {
        super.init()
    }

    static func isNewFontEnabled(fg: FeatureGatingService) -> Bool {
        #if DEBUG
        return false
        #else
        return fg.staticFeatureGatingValue(with: "core.font.check_font_swizzle")
        #endif
    }

    static func isUDTrackerEnabled(fg: FeatureGatingService) -> Bool {
        #if DEBUG
        return true
        #else
        return fg.staticFeatureGatingValue(with: "core.ud.component.tracker")
        #endif
    }

    static func isIconFontEnabled(fg: FeatureGatingService) -> Bool {
        #if DEBUG
        return true
        #else
        return fg.staticFeatureGatingValue(with: "core.ud.component.iconfont")
        #endif
    }

    /// 添加通知监听
    public func addObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateFontAppearanceIfNeeded),
            name: .preferLanguageChange,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBoldTextStatusIfNeeded),
            name: UIAccessibility.boldTextStatusDidChangeNotification,
            object: nil)
    }

    @objc
    func updateFontAppearanceIfNeeded() {
        let circularBanList: [Lang] = [.ja_JP, .vi_VN]
        if circularBanList.contains(LanguageManager.currentLanguage), UDFontAppearance.isCustomFont {
            LarkFont.swizzleFocus()
            LarkFont.removeFontAppearance()
            LarkFont.setComponentFontIfNeeded()
            NotificationCenter.default.post(name: LarkFont.systemFontDidChange, object: nil)
        } else {
            guard !UDFontAppearance.isCustomFont else { return }
            guard !circularBanList.contains(LanguageManager.currentLanguage) else { return }
            LarkFont.setFontAppearance()
            LarkFont.swizzleIfNeeded()
            LarkFont.setComponentFontIfNeeded()
            NotificationCenter.default.post(name: LarkFont.systemFontDidChange, object: nil)
        }
    }

    @objc
    func updateBoldTextStatusIfNeeded() {
        guard UDFontAppearance.isBoldTextEnabled != UIAccessibility.isBoldTextEnabled else { return }
        UDFontAppearance.isBoldTextEnabled = UIAccessibility.isBoldTextEnabled
        NotificationCenter.default.post(name: LarkFont.boldTextStatusDidChange, object: nil)
    }

    /// 设置 UDFont 中的 UIFont.ud.font 的字体为自定义字体
    public static func setFontAppearance() {
        guard #available(iOS 12.0, *) else { return }
        guard let bundle = BundleConfig.LarkFontAssemblyBundle else { return }
        let fontInfo = CustomFontInfo(bundle: bundle,
                                      customFontName: Self.customFontName,
                                      regularFilePath: Self.regularFileName,
                                      mediumFilePath: Self.mediumFileName,
                                      semiBoldFilePath: Self.semiFileName,
                                      boldFilePath: Self.boldFileName)

        UDFontAppearance.customFontInfo = fontInfo
    }

    /// 移除自定义字体
    public static func removeFontAppearance() {
        UDFontAppearance.customFontInfo = nil
    }

    /// 设置系统控件默认字体为自定义字体
    public static func setComponentFontIfNeeded() {
//        Self.setTextFieldFontIfNeeded()
//        Self.setTextViewFontIfNeeded()
        Self.setSearchBarFontIfNeeded()
        Self.setNavigatonFontIfNeeded()
//        Self.setTabBarFontIfNeeded()
        Self.setTableViewFontIfNeeded()
    }

    static func setTextFieldFontIfNeeded() {
        UITextField.appearance().font = Self.defaultTextFieldFont
        UITextField.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font = Self.defaultTextFieldFont
    }

    static func setTextViewFontIfNeeded() {
        UITextView.appearance().font = Self.defaultTextViewFont
        UITextView.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font = Self.defaultTextViewFont
    }

    static func setSearchBarFontIfNeeded() {
        if #available(iOS 13.0, *) {
            UISearchBar.appearance().searchTextField.font = Self.defaultSearchBarFont
        }
    }

    static func setNavigatonFontIfNeeded() {
        let naviAttributes = [NSAttributedString.Key.font: Self.defaultNavigationBarFont]
        let barButtonItemAttributes = [NSAttributedString.Key.font: Self.defaultBarButtonItemFont]
        UINavigationBar.appearance().titleTextAttributes = naviAttributes
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .highlighted)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .disabled)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .selected)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .focused)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .application)
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemAttributes, for: .reserved)
    }

    static func setTabBarFontIfNeeded() {
        let tabBarItemAttributes = [NSAttributedString.Key.font: Self.defaultTabBarItemFont]
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .highlighted)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .disabled)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .focused)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .application)
        UITabBarItem.appearance().setTitleTextAttributes(tabBarItemAttributes, for: .reserved)
    }

    static func setTableViewFontIfNeeded() {
        UITableViewCell.appearance().textLabel?.font = Self.defaultTableTextLabelFont
        UITableViewCell.appearance().detailTextLabel?.font = Self.defaultTableDetailTextLabelFont
        UITableViewHeaderFooterView.appearance().textLabel?.font = Self.defaultTableViewHeaderFooterViewFont
    }
}

public extension LarkFont {
    /// 当前 App 字体发生改变
    static let systemFontDidChange: Notification.Name = Notification.Name("systemFontDidChangeNotification")
    /// 当前设置 粗体文本 设置改变
    static let boldTextStatusDidChange: Notification.Name = Notification.Name("boldTextStatusDidChangeNotification")

    /// Custom Font  Name
    private static var customFontName: String = "LarkCircular-Regular"

    /// weight: 400 .regular Font File Name
    private static var regularFileName: String = "LarkCircular-Regular.woff2"

    /// weight: 500 .medium Font File Name
    private static var mediumFileName: String = "LarkCircular-Medium.woff2"

    /// weight: 600 .semiBold Font File Name
    private static var semiFileName: String = "LarkCircular-SemiBold.woff2"

    /// weight: 700 .bold Font File Name
    private static var boldFileName: String = "LarkCircular-Bold.woff2"

    private static var defaultLabelFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultButtonFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultTextFieldFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultTextViewFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultSearchBarFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultBarButtonItemFont: UIFont = UDFont.systemFont(ofSize: 16)
    private static var defaultNavigationBarFont: UIFont = UDFont.boldSystemFont(ofSize: 17)
    private static var defaultTabBarItemFont: UIFont = UDFont.systemFont(ofSize: 10)
    private static var defaultTableTextLabelFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultTableDetailTextLabelFont: UIFont = UDFont.systemFont(ofSize: 17)
    private static var defaultTableViewHeaderFooterViewFont: UIFont = UDFont.systemFont(ofSize: 13)
}
