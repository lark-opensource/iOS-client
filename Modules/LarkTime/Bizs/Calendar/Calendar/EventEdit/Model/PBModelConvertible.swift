//
//  PBModelConvertible.swift
//  Calendar
//
//  Created by 张威 on 2020/4/22.
//

import SwiftProtobuf

protocol PBModelConvertible {
    associatedtype PBModel: SwiftProtobuf.Message

    init(from pb: PBModel)

    func getPBModel() -> PBModel
}
