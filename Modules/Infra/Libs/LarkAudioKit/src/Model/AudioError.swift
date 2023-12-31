//
//  AudioError.swift
//  LarkAudioKit
//
//  Created by 李晨 on 2021/7/21.
//

import Foundation

public enum AudioError: Error {
    case fileInvalid

    case systemError(Error)
}
