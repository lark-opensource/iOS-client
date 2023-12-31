//
//  PreviewProcessor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/1/8.
//

import Foundation

protocol PreviewProcessStrategy {
    /// 如果转码中，是否要进行降级处理，下载源文件预览
    var downgradeWhenGenerating: Bool { get }
}

protocol PreviewProcessor: PreviewProcessStrategy {
    /// 异步操作，处理完后需要掉用completion
    func handle(preview: DKFilePreview, completion: @escaping () -> Void)
    func handle(error: Error, completion: @escaping () -> Void)
}

protocol PreviewProcessHandler: AnyObject {
    var isWaitTranscoding: Bool { get }
    func updateState(_ state: DriveProccessState)
}
