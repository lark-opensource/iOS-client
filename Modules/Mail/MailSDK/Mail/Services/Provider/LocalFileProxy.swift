//
//  proxy.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/6.
//

import Foundation
import RxSwift
import RustPB

// MARK: model
public protocol MailSendFileInfoProtocol { // 关联
    var name: String { get }
    var fileURL: URL { get }
    var size: UInt? { get }
}

public struct MailSendFileModel: MailSendFileInfoProtocol {
    public var name: String
    public var fileURL: URL
    public var size: UInt?
}

public struct LocalFileParams { // 为了方便扩展接口参数
    public var maxSelectCount: Int?
    /// 本次选择的总文件大小
    public var maxTotalFileSize: Int?
    public var maxSingleFileSize: Int?
    public var chooseLocalFiles: (([MailSendFileInfoProtocol]) -> Void)?
    public var extraPaths: [URL]?
    public var title: String?
    public init() {}
}

// MARK: provider

// MARK: FILE
public protocol LocalFileProxy {
    func presentLocalFilePicker(params: LocalFileParams, wrap: UINavigationController.Type?, fromVC: UIViewController)
    func presentLocalFilePicker(params: LocalFileParams, wrap: UINavigationController.Type?, fromVC: UIViewController, closeCallBack: (() -> Void)?)
}
