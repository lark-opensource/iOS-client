//
//  DocsContentInterceptor.swift
//  SKCommon
//
//  Created by huayufan on 2021/1/11.
//  


import Foundation

class DocsContentInterceptor: DocsMagicInterceptor {
   
    override func currentIsTopMost() -> Bool {
        let topMost = UIViewController.docs.topMost(of: presentController)
        guard topMost == presentController || topMost == presentController?.parent else {
            return false
        }
        return true
    }
}
