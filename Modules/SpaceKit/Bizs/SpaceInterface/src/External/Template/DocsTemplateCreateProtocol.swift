//
//  DocsTemplateCreateProtocol.swift
//  SpaceInterface
//
//  Created by huayufan on 2022/12/13.
//  

import Foundation

public struct DocsTemplateCreateResult {

    public let url: String
    public let title: String

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}

public protocol DocsTemplateCreateProtocol {
    /// 根据模版docToken、docType创建文档
    /// - Parameters:
    ///   - docToken: 模版token
    ///   - docType: 模版type
    ///   - templateId: 模版Id,  如果这个Id不为空优先以模版Id创建文档
    ///   - result: 创建文档请求返回的结果，成功时第一个参数不为nil，第二个参数为nil；失败时第一个参数为nil，第二个参数不为nil
    func createDocsByTemplate(docToken: String, docType: Int, templateId: String, result: ((DocsTemplateCreateResult?, Error?) -> Void)?)
}
