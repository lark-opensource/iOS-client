//
//  TemplateDataProvider+GroupNotice.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/22.
//  


import SKFoundation
import RxSwift
import SwiftyJSON
import SKInfra

extension TemplateDataProvider {
    func fetchGroupNoticeRecommendTemplates(objToken: String) -> Observable<[TemplateModel]> {
        let params: [String: Any] = [
            "platform": "group_announcement",
            "obj_type": 2,
            "scene": "",
            "obj_token": objToken,
            "version": 4
        ]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.templateRecommendBottom,
                     params: params,
                     method: .GET,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (result) -> Observable<[TemplateModel]> in
                if let result = result,
                   let dataString = result["data"]["templates"].rawString(),
                   let data = dataString.data(using: .utf8) {
                    do {
                        let models = try JSONDecoder().decode([TemplateModel].self, from: data)
                        return .just(models)
                    } catch {
                        spaceAssertionFailure("cannot parse templateRecommendBottom \(error)")
                        return .error(TemplateError.parseDataError)
                    }
                } else {
                    spaceAssertionFailure("cannot parse templateRecommendBottom")
                    return .error(TemplateError.parseDataError)
                }
            }
    }
    
    func insertTemplate(_ templateToken: String, toDocs docsToken: String, docsType: Int, baseRev: Int, extra: String) -> Observable<Bool> {
        let params: [String: Any] = [
            "obj_type": docsType,
            "obj_token": docsToken,
            "template_obj_token": templateToken,
            "base_rev": baseRev,
            "extra": extra
        ]
        return RxDocsRequest<JSON>()
            .request(OpenAPI.APIPath.templateInsert,
                     params: params,
                     method: .POST,
                     callbackQueue: parseDataQueue,
                     timeout: timeout)
            .flatMap { (result) -> Observable<Bool> in
                if let result = result,
                   let code = result["code"].int {
                    return .just(code == 0)
                } else {
                    spaceAssertionFailure("cannot parse templateInsert")
                    return .error(TemplateError.parseDataError)
                }
            }
    }
}
