//
//  main.swift
//  EncryptId
//
//  Created by huahuahu on 2019/1/20.
//  Copyright © 2019 郭腾虎. All rights reserved.
//

import Foundation

func encrypt(id: String) -> String {
    let md5str = "ee".md5()
    let prefix = md5str[md5str.startIndex..<md5str.index(md5str.startIndex, offsetBy: 6)]
    let subfix = md5str[md5str.index(md5str.endIndex, offsetBy: -6)..<md5str.endIndex]
    let uniqueID = (String(prefix) + (id + String(subfix)).md5()).sha1()
    return uniqueID
}

let ids = CommandLine.arguments
if ids.count == 1 {
    print("please input id to encrypt")
}

ids.dropFirst().forEach { (id) in
    print("\(id) ------> \(encrypt(id: id))")
}
