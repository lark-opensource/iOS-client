//
//  TemplateCollectionSaveResult.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/6/7.
//  


import Foundation

public struct TemplateCollectionSaveResult: Codable {
    let folderToken: String
    let folderURL: String
    let tokenList: [Token]
    
    struct Token: Codable {
        let templateToken: String
        let newObjToken: String
        enum CodingKeys: String, CodingKey {
            case templateToken = "template_token"
            case newObjToken = "new_obj_token"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case folderToken = "folder_token"
        case folderURL = "folder_url"
        case tokenList = "token_list"
    }
}
