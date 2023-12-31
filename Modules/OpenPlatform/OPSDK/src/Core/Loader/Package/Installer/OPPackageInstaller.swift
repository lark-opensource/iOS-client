//
//  OPPackageInstaller.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/19.
//

import Foundation

protocol OPPackageInstaller: AnyObject {
    /// 安装包文件：zip包为解压到对应目录，流式包为拷贝到对应目录，返回包安装路径：zip包为dir，流式包为file
    /// - Parameters:
    ///   - sourceFilePath: 下载后的临时包文件
    ///   - destDir: 需要安装的目标目录地址
    func installPackage(from sourceFilePath: String, to destDir: String) throws -> String

}
