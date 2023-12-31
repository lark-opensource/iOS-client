//
//  InvokeNativeAppAPIError.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/23.
//

import Foundation

///abstract [简述]三方API调用失败时，错误数据封装类
@objc
@objcMembers
public class InvokeNativeAppAPIError: NSError {
    public let errorMes: String?
    
    public init(errorMsg: String?) {
        self.errorMes = errorMsg
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

