//
//  FileConfig+Docs.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKCommon

// FileConfig+Docs
extension FileConfig {
    var docBrowserType: BrowserViewController.Type {
        if let docType = browserType as? BrowserViewController.Type {
            return docType
        }
        return BrowserViewController.self
    }

    mutating func addExtra(key: String, value: String, overwrite: Bool = false) {
        if extraInfos == nil {
            extraInfos = [key: value]
        } else {
            if extraInfos?[key] == nil || overwrite {
                extraInfos?[key] = value
            }
        }
    }
}
