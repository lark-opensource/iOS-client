//
//  CertError.swift
//  ByteViewLiveCert
//
//  Created by kiri on 2023/2/14.
//

import Foundation

enum CertError: Error {
    case unknown(code: Int, message: String)
    case livenessFailed(errorMsg: String?)
    case twoEleFailed(type: Int, errMsg: String?)
    case noElements
    case cannotPresent
}
