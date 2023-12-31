//
//  DocsJSServiceHandler.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/13.
//  


import Foundation

// From DocsJSServicesManager.swift
public protocol DocsJSServiceHandler: JSServiceHandler {}


public enum DocsJSServiceType {
    case base                 //基础Service，切换文档时一直在
    case commonBusiness       //公共业务Service，切换文档时会重新注册
    case individualBusiness   //某文档类型业务Service，切换文档时会重新注册
}
