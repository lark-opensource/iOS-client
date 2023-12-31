//
//  ResultExtensions.swift
//  ByteView
//
//  Created by kiri on 2020/10/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default:
            return nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}
