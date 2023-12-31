//
//  i18n.swift
//  SKResource
//
//  Created by lijuyou on 2020/6/18.
//  


import Foundation
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
public final class I18n {

//    static var currentBundle = Bundle(for: BrowserView.self)
    public static let currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/SKResource", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()

    public static var resourceBundle: Bundle = {
        guard let url = I18n.currentBundle.url(forResource: "SKResource", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return I18n.currentBundle }
        return bundle
    }()
}
