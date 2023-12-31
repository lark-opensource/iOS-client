//
//  i18n.swift
//  mail-native-template
//
//  Created by verehu on 2023/7/26.
//  


import Foundation
#if USE_DYNAMIC_RESOURCE

#endif
public final class I18n {

    public static let currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/MailNativeTemplate", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()

    public static var resourceBundle: Bundle = {
        guard let url = I18n.currentBundle.url(forResource: "MailNativeTemplate", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return I18n.currentBundle }
        return bundle
    }()
}
