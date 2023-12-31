//
//  FormatRuleApi.swift
//  Todo
//
//  Created by wangwanxin on 2022/1/21.
//

import RxSwift
import RustPB
import LarkLocalizations
import LarkRustClient

/// Todo 显示规则 Api

extension Rust {
    typealias FormatRule = Contact_V1_GetAnotherNameFormatResponse.FormatRule
}

protocol FormatRuleApi {

    /// 获取别名显示规则
    /// - Returns: 规则
    func getAnotherNameFormat() -> Observable<Rust.FormatRule>

    func syncGetParsedRruleText(_ rrule: String) -> String?

}

extension RustApiImpl: FormatRuleApi {

    func getAnotherNameFormat() -> Observable<Rust.FormatRule> {
        var ctx = Self.generateContext()
        // 1283: .same(proto: "GET_ANOTHER_NAME_FORMAT"),
        ctx.cmd = .init(rawValue: 1_283) ?? .unknownCommand
        ctx.logReq("getAnotherNameFormat")

        var request = Contact_V1_GetAnotherNameFormatRequest()
        return client.sendAsyncRequest(request)
            .map { (response: Contact_V1_GetAnotherNameFormatResponse) -> Rust.FormatRule in
                return response.rule
            }
            .log(with: ctx) { result in
                return "\(result.rawValue)"
            }
    }

    func syncGetParsedRruleText(_ rrule: String) -> String? {
        var ctx = Self.generateContext()
        // case 3152: self = .getParsedRruleText
        ctx.cmd = .init(rawValue: 3_152) ?? .unknownCommand
        ctx.logReq("getParsedRruleText")

        var request = Calendar_V1_GetParsedRruleTextRequest()
        request.rrule = rrule
        request.languageType = LanguageManager.currentLanguage.sdkLanguageType

        if let reponse: Calendar_V1_GetParsedRruleTextResponse = try? client.sync(message: request, allowOnMainThread: true) {
            return reponse.parsedRrule
        } else {
            ctx.logReq("getParsedRruleText failed")
            return nil
        }
    }
}
