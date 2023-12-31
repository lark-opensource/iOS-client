//
//  LynxTemplataModel.swift
//  LarkLynxKit
//
//  Created by bytedance on 2022/11/7.
//

import Foundation
import Lynx

public struct LynxTemplataModel {
    public var template: Data?
    public var templateUrl: String?
    public var templatePathForResourceLoader: String?
    public var lynxTemplateData: LynxTemplateData?
    
    public init(template: Data? = nil,
                templateUrl: String? = nil,
                templatePathForResourceLoader: String? = nil,
                lynxTemplateData: LynxTemplateData? = nil) {
        self.template = template
        self.templateUrl = templateUrl
        self.templatePathForResourceLoader = templatePathForResourceLoader
        self.lynxTemplateData = lynxTemplateData
    }
}
