//
//  Shell.swift
//  Calendar_Cloud
//
//  Created by Rico on 2021/4/21.
//

import Foundation

@discardableResult func shell(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash/"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

    return output
}
