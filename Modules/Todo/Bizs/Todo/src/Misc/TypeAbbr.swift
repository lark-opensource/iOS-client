//
//  TypeAbbr.swift
//  Todo
//
//  Created by 张威 on 2021/1/15.
//

/// 简化常用类型的书写

let void = Void()

typealias UrlStr = String

typealias RichText = Rust.RichText
typealias AttrText = NSAttributedString
typealias MutAttrText = NSMutableAttributedString

typealias UserResponse<R> = Result<R, UserError>
