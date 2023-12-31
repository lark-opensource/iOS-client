//
//  OPPackageReader.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/10/29.
//


import Foundation

// 文件读取器：包括流式文件、zip文件等的读取
// 对外只暴露同步读取方法，以避免外部需要根据文件状态来判断同步或异步调用
// 内部，zip包在下载完成后调用，返回文件data，反之报错；
// 流式包下头文件解析完成后调用，若文件在下载中，则异步变同步，文件下载完成后返回；若文件已经下载，直接返回文件内容；其他情况报错
@objc
public protocol OPPackageReaderProtocol: AnyObject {

    func syncRead(file: String) throws -> Data

}
