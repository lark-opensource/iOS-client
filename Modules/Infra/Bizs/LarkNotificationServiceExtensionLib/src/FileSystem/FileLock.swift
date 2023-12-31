//
//  FileLock.swift
//  ExtensionMessenger
//
//  Created by mochangxing on 2019/7/26.
//

import Foundation

protocol FileLock {

    var filePath: String { get }

    func getFileLock(processor: (URL, @escaping () -> Void) -> Void, retry: Int) -> NSError?

    func unlock()

}
