//
//  WeakReference.swift
//  SKFoundation
//
//  Created by huayufan on 2021/1/9.
//  

import Foundation

public struct WeakReference<Ref: AnyObject> {
    public weak var ref: Ref?
    
    public init(_ ref: Ref?) {
        self.ref = ref
    }
}
