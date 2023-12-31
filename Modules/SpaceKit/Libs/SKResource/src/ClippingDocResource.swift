//
//  ClippingDocResource.swift
//  SKResource
//
//  Created by huayufan on 2022/6/27.
//  


import Foundation

public struct ClippingDocResource {

    public init() {}
    
    public var zipPath: String {
        let bundle = I18n.resourceBundle
        return bundle.path(forResource: "clip", ofType: "7z") ?? ""
    }

    public let version = "2.0.3"
}
