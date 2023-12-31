//
//  Extensions.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/28.
//

import UIKit
import Foundation
import ByteWebImage // CheckError
@testable import LarkSendMessage // VideoPassError

// MARK: - CGSize
extension CGSize {
    /// 把width、height放大scale倍
    func scale(_ scale: CGFloat) -> CGSize {
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
}

// MARK: - CheckError
extension CheckError: Equatable {
    public static func == (lhs: CheckError, rhs: CheckError) -> Bool {
        if case .fileTypeInvalid = lhs, case .fileTypeInvalid = rhs { return true }
        if case .imageFileSizeExceeded = lhs, case .imageFileSizeExceeded = rhs { return true }
        if case .imagePixelsExceeded = lhs, case .imagePixelsExceeded = rhs { return true }
        return false
    }
}

// MARK: - VideoPassError
extension VideoPassError: Equatable {
    public static func == (lhs: VideoPassError, rhs: VideoPassError) -> Bool {
        if case .noNeedPassthrough = lhs, case .noNeedPassthrough = rhs { return true }
        if case .videoParseInfoError = lhs, case .videoParseInfoError = rhs { return true }
        if case .fileSizeLimit = lhs, case .fileSizeLimit = rhs { return true }
        if case .videoBitrateLimit = lhs, case .videoBitrateLimit = rhs { return true }
        if case .videoSizeLimit = lhs, case .videoSizeLimit = rhs { return true }
        if case .videoHDRLimit = lhs, case .videoHDRLimit = rhs { return true }
        if case .videoEncodeLimit = lhs, case .videoEncodeLimit = rhs { return true }
        if case .remuxLimit = lhs, case .remuxLimit = rhs { return true }
        if case .interleaveLimit = lhs, case .interleaveLimit = rhs { return true }
        if case .canntPassResult = lhs, case .canntPassResult = rhs { return true }
        if case .createIESMMTranscoderParamError = lhs, case .createIESMMTranscoderParamError = rhs { return true }
        return false
    }
}
