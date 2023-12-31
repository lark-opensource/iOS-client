//
//  CellReuseIdentifier.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/7.
//  

import Foundation

protocol CellReuseIdentifier {
    static var reuseId: String { get }
}

extension CellReuseIdentifier {
    static var reuseId: String {
        return String(describing: self)
    }
}
