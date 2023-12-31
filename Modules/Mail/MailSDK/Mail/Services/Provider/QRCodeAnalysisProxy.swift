//
//  QRCodeAnalysisProxy.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/11/21.
//

import Foundation

public protocol QRCodeAnalysisProxy {
    func handle(code: String, fromVC: UIViewController, errorHandler: @escaping (String?) -> Void)
}

