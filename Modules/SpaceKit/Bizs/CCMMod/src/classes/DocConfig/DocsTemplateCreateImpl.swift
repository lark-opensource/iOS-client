//
//  DocsTemplateCreateImpl.swift
//  CCMMod
//
//  Created by huayufan on 2022/12/13.
//  

import SpaceInterface
import SKCommon

class DocsTemplateCreateImpl: DocsTemplateCreateProtocol {
    func createDocsByTemplate(docToken: String,
                              docType: Int,
                              templateId: String,
                              result: ((DocsTemplateCreateResult?, Error?) -> Void)?) {
        let req = DocsRequestCenter.createByTemplate(type: DocsType(rawValue: docType),
                                                     in: "",
                                                     parameters: ["token": docToken,
                                                                  "template_id": templateId], from: nil) { res, error in
            result?(DocsTemplateCreateResult(url: res?.url ?? "",
                                            title: res?.title ?? ""), error)
        }
        req.makeSelfReferenced()
    }
}
