//
//  i18nUtil.swift
//  DocsSDK
//
//  Created by vvlong on 2018/11/27.
//

import Foundation
import LarkLocalizations

class I18n {
    static var currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/MailSDK", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()

    static var resourceBundle: Bundle = {
        guard let url = I18n.currentBundle.url(forResource: "MailSDK", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return I18n.currentBundle }
        return bundle
    }()

    class func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self.resourceBundle, compatibleWith: nil)
    }

    class func currentLanguage() -> Lang {
        return LanguageManager.currentLanguage
    }

    class func currentLanguageIdentifier() -> String {
        return LanguageManager.currentLanguage.languageIdentifier
    }

    class func currentLanguageShortIdentifier() -> String {
        let identifier = currentLanguageIdentifier()
        if let shortId = identifier.split(separator: "-").first {
            return String(shortId)
        }
        return identifier
    }

    class func currentIsCn() -> Bool {
        if currentLanguageIdentifier().hasPrefix("zh") {
            return true
        }
        return false
    }
}
