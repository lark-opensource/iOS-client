//
//  Bundle+ext.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/30.
//  


import UIKit

extension Bundle {
    static let currentBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkAIInfra", withExtension: "framework"),
           let bundle = Bundle(url: url){
            return bundle
        } else {
            return Bundle.main
        }
    }()

    static var resourceBundle: Bundle = {
        guard let url = currentBundle.url(forResource: "LarkAIInfra", withExtension: "bundle"),
            let bundle = Bundle(url: url) else { return currentBundle }
        return bundle
    }()
}
