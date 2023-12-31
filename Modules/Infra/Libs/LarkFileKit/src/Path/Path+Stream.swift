//
//  Path+Stream.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/9.
//

import Foundation

// MARK: input/output stream
extension Path {

    // MARK: - NSStream

    /// Returns an input stream that reads data from the file at the path, or
    /// `nil` if no file exists.
    public func inputStream() -> InputStream? {
        FileTracker.track(self, operation: .inputStream) {
            InputStream(fileAtPath: absolute.safeRawValue)
        }
    }
}
