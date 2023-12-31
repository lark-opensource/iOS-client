//
//  CommentServiceType.swift
//  SKBrowser
//
//  Created by huayufan on 2021/7/5.
//  


import Foundation

public protocol CommentServiceType: AnyObject {

    func callFunction(for action: CommentEventListenerAction, params: [String: Any]?)
    
}
