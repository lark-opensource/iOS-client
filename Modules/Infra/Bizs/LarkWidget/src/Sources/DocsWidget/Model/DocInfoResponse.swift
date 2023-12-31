//
//  DocInfoResponse.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/8/18.
//

import Foundation

public struct DocInfoResponse: Codable {

    public var code: Int
    public var msg: String
    public var data: DocInfoData
}

public struct DocInfoData: Codable {

    public var title: String
    public var url: String
}
