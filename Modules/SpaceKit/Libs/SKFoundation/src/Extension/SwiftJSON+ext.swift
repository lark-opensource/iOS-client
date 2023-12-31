//
//  SwiftJSON+ext.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/6/17.
//  

import SwiftyJSON

extension JSON {
    public func mapIfExists(_ transform: (JSON) throws -> Void) rethrows {
        if exists() {
            try transform(self)
        }
    }
}
