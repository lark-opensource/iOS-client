//
//  I18n.swift
//  LarkEditorJS
//
//  Created by tefeng liu on 2020/5/28.
//

import Foundation
import LarkLocalizations

class I18n {
    static var currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkEditorJS", withExtension: "framework") {
            return Bundle(url: url) ?? Bundle.main
        } else {
            return Bundle.main
        }
    }()

    static var resourceBundle: Bundle = {
        guard let url = I18n.currentBundle.url(forResource: "LarkEditorJS", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return I18n.currentBundle }
        return bundle
    }()

    class func image(named: String) -> UIImage? {
        return UIImage(named: named, in: self.resourceBundle, compatibleWith: nil)
    }

    class func currentLanguage() -> Language {
        return LanguageManager.current
    }

    class func currentLanguageIdentifier() -> String {
        return LanguageManager.current.rawValue
    }
}
