//
//  Context.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/4/6.
//

public protocol Context: AnyObject {}

public class EmptyContext: Context {
    public init() {}
}
