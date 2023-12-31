//
//  AbsPath+Unarchive.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public extension AbsPath {

    func unarchive() -> Any? {
        return anyPath().unarchive()
    }

}
