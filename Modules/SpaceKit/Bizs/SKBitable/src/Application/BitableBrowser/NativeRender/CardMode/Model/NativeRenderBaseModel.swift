//
//  NativeRenderBaseModel.swift
//  SKBitable
//
//  Created by zoujie on 2023/11/7.
//  


import Foundation
import SKInfra

protocol NativeRenderBaseModel: SKFastDecodable {
    var empty: EmptyModel? { get set }
}
