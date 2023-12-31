//
//  I18N.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/10/23.
//

import Foundation

public final class I18n {

//    static var currentBundle = Bundle(for: BrowserView.self)
    public static let currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/WebAppContainer", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()

    public static var resourceBundle: Bundle = {
        guard let url = I18n.currentBundle.url(forResource: "WebAppContainer", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return I18n.currentBundle }
        return bundle
    }()
}
