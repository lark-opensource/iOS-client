//
//  AppDelegate.swift
//  Calendar
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
#if USE_SWIFTUI // compile with SwiftUI cause CI test startup failed. conditional compile for local test
import SwiftUI
#endif
import LarkLocalizations

// swiftlint:disable all

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        print(Bundle.main.localizations)

        #if USE_SWIFTUI
        if #available(iOS 13.0.0, *) {
            print(Root.environment())
            var langs = (Bundle.main.infoDictionary!["CFBundleLocalizations"] as? [String] ?? [])
            langs = ["en_US", "ja-jp", "zh-cn", "zh-tw", "zh_HK", "it-it", "st-CN"]
            LanguageManager.supportLanguages = langs.map { Lang(rawValue: $0) }
            self.window?.rootViewController = UIHostingController(rootView: Root(lang: Language()))
        } else {
            // Fallback on earlier versions
            self.window?.rootViewController = UIViewController()
        }
        #else
            self.window?.rootViewController = UIViewController()
        #endif

        self.window?.rootViewController?.view.backgroundColor = UIColor.white
        self.window?.makeKeyAndVisible()
        
        let value = NSLocalizedString("pluralkey", comment: "pluralkey")
        print(NSLocalizedString("pluralkey2", comment: "pluralkey"))
        print(value)
        print(String.localizedStringWithFormat(value, 1, 2, 3, 4))
        // test_icu()
        testIcuInSwift()
        return true
    }
}

#if USE_SWIFTUI
@available(iOS 13.0, *)
class Language: ObservableObject {
    var objectWillChange = NotificationCenter.default.publisher(for: .preferLanguageDidChange)
    var patch: Bool = false {
        didSet {
            let cls = NSLocale.self
            let old = class_getClassMethod(cls, #selector(getter: NSLocale.current))!
            let new = class_getClassMethod(cls, #selector(getter: NSLocale.willChangeLocale))!
            method_exchangeImplementations(old, new)
        }
    }
}

@available(iOS 13.0.0, *)
struct Root: View {
    static func environment() -> [(String, String)] {
        [("preferred:", Locale.preferredLanguages.joined(separator: ",")),
         ("current:", Locale.current.identifier),
         ("autocurrent:", Locale.autoupdatingCurrent.identifier),
         ("AppleLanguages:", (UserDefaults.standard.object(forKey: "AppleLanguages") as! [String]).joined(separator: ",")),
         ("AppleLocale:", (UserDefaults.standard.object(forKey: "AppleLocale") as! String)),
         // ("Appnames:", (Bundle.main.localizedInfoDictionary!["CFBundleDisplayName"] as! String)),
         ("i18N Appnames:", LanguageManager.bundleDisplayName),
         ("use:", LanguageManager.currentLanguage.displayName),
         ("system?", LanguageManager.isSelectSystem.description),
         ("systemLang", (CFPreferencesCopyAppValue("AppleLanguages" as CFString, UserDefaults.globalDomain as CFString) as? [String] ?? []).description),
         ("systemLocale", (CFPreferencesCopyAppValue("AppleLocale" as CFString, UserDefaults.globalDomain as CFString) as? String ?? ""))
        ]
    }
    @State var text: String = ""
    @ObservedObject var lang: Language
    var body: some View {
        VStack {
            TextField.init("Input", text: $text).multilineTextAlignment(.center)
            Text(String(describing: ObjectIdentifier(lang)))

            ForEach(Root.environment(), id: \.0) { (title, text) in
                HStack {
                    Text(title).foregroundColor(.red)
                    Text(text)
                }
            }

            Spacer().frame(maxHeight: 30)

            changeLanguage
            if let system = LanguageManager.systemLanguage {
                Button("System") { LanguageManager.setCurrent(language: system, isSystem: true) }
            }

            // runtime patch not work for menu
            Toggle(isOn: $lang.patch) { Text("Patch NSLocale.current: ") }.fixedSize()
        }
    }

    var changeLanguage: some View {
        return ForEach(LanguageManager.supportLanguages, id: \.identifier) { lang in
            Button(lang.displayName) {
                LanguageManager.setCurrent(language: lang, isSystem: false)
            }
        }
    }
}

extension NSLocale {
    @objc dynamic static var willChangeLocale: NSLocale {
        return LanguageManager.currentLanguage as NSLocale
    }
}
#endif

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.ddd(1)//sourcekit-lsp works fine
        // self.ddd()//sourcekit-lsp crashed
    }

    func ddd(_ params: Int) {
    }
}

// swiftlint:enable all
