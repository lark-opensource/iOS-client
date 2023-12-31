//
//  OpenMailModel.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import LarkOpenAPIModel

final class OpenAPIMailToParams: OpenAPIBaseParams {
    @OpenAPIOptionalParam(jsonKey: "to")
    public var to: [String]?
    @OpenAPIOptionalParam(jsonKey: "cc")
    public var cc: [String]?
    @OpenAPIOptionalParam(jsonKey: "bcc")
    public var bcc: [String]?
    @OpenAPIOptionalParam(jsonKey: "subject")
    public var subject: String?
    @OpenAPIOptionalParam(jsonKey: "body")
    public var body: String?
    public convenience init(to: [String]?, cc: [String]?, bcc: [String]?, subject: String?, body: String?) throws {
        var dict: [String: Any] = [:]
        if let to = to {
            dict["to"] = to
        }
        if let cc = cc {
            dict["cc"] = cc
        }
        if let bcc = bcc {
            dict["bcc"] = bcc
        }
        if let subject = subject {
            dict["subject"] = subject
        }
        if let body = body {
            dict["body"] = body
        }
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_to, _cc, _bcc, _subject, _body]
    }

}
