//
//  FileWriter.swift
//  ExtensionMessenger
//
//  Created by mochangxing on 2019/7/26.
//

import Foundation

public final class FileWriteLock: FileLock {

    private var signal: DispatchSemaphore?

    let filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }

    public func getFileLock(processor: (URL, @escaping () -> Void) -> Void, retry: Int = 1) -> NSError? {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        let fileURL = URL(fileURLWithPath: filePath)

        signal = DispatchSemaphore(value: 1)
        var error: NSError?

        var times = retry
        repeat {
            if times < retry {
                error = nil
            }
            fileCoordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &error) { (newURL) in
                self.signal?.wait()
                processor(newURL, unlock)
                self.signal?.wait()
            }
            times -= 1
        } while times >= 0 && error != nil

        return error
    }

    public func unlock() {
        if let signal = signal {
            signal.signal()
            self.signal = nil
        }
    }
}
