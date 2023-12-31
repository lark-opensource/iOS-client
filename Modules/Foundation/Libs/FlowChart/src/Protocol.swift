//
//  Protocol.swift
//  WebViewDemo
//
//  Created by JackZhao on 2022/1/4.
//  Copyright © 2022 JACK. All rights reserved.
//

/// https://bytedance.feishu.cn/docx/doxcnPywWTplKjxYv9tNcPGrzie

// context
import Foundation
public protocol FlowChartContext: AnyObject {
}

public protocol FlowChartInput {
    var extraInfo: [String: String] { get set }
}

public typealias FlowChartOutput = FlowChartInput
