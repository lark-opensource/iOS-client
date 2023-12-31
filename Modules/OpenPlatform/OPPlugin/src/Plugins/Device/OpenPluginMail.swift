//
//  OpenPluginMail.swift
//  LarkOpenApis
//
//  Created by yi on 2021/2/4.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import ECOProbe
import ECOInfra
import LarkContainer

class OpenPluginMail: OpenBasePlugin {

    public func mailto(params: OpenAPIMailToParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        let to = mailboxFromArray(array: params.to)
        var headers = [String: String]()
        headers["cc"] = mailboxFromArray(array: params.cc)
        headers["bcc"] = mailboxFromArray(array: params.bcc)
        headers["subject"] = params.subject
        headers["body"] = params.body
        var headersString = ""
        headers.forEach {
            if(!$0.value.isEmpty) {
                headersString.append(headersString.isEmpty ? "?" : "&")
                headersString.append("\(urlEncoded(url: $0.key))=\(urlEncoded(url: $0.value))")
            }
        }
        let mailtoURL = "mailto:\(urlEncoded(url: to))\(headersString)"

        guard let url = URL(string: mailtoURL) else {
            context.apiTrace.warn("mailto url invalid, toLength=\(to.count), headers=\(headersString.count)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("mailto url invalid, toLength=\(to.count), headersString=\(headersString.count), headersKeys=\(headers.keys)")
            callback(.failure(error: error))
            return
        }
        UIApplication.shared.open(url, options: [:]) { (success) in
            if success {
                callback(.success(data: nil))
            } else {
                context.apiTrace.warn("open mailto failed, toLength=\(to.count), headersString=\(headersString.count), headersKeys=\(headers.keys)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("open mailto failed, toLength=\(to.count), headersString=\(headersString.count), headersKeys=\(headers.keys)")
                callback(.failure(error: error))
            }
        }
    }

    func mailboxFromArray(array: [String]?) -> String {
        guard let array = array else {
            return ""
        }
        var mainBox = ""
        for mail in array {
            if mainBox.count > 0 {
                mainBox = mainBox + ","
            }
            mainBox = mainBox + mail
        }
        return mainBox
    }

    public func urlEncoded(url: String) -> String {
        if URLEncodeNormalization(resolver: userResolver).enabled(in: .api_mailTo) {
            do {
                let url = try URL.forceCreateURL(string: url)
                return url.absoluteString
            } catch {
                return ""
            }
        } else {
            let allowedCharacterSet = (CharacterSet(charactersIn: ":/?#@!$&'() {}*+=").inverted)
            
            if let escapedString = url.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                return escapedString
            }
            return ""
        }
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "mailto", pluginType: Self.self, paramsType: OpenAPIMailToParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.mailto(params: params, context: context, callback: callback)
        }

    }

}
