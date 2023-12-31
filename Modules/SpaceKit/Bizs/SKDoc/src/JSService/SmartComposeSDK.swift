//
//  SmartComposeSDK.swift
//  SKBrowser
//
//  Created by zoujie on 2020/11/9.
//  


import Foundation

public final class SmartComposeSDK {

    public var smartComposeSetting: () -> Bool

    public init(smartComposeSetting: @escaping () -> Bool) {
        self.smartComposeSetting = smartComposeSetting
    }
}
