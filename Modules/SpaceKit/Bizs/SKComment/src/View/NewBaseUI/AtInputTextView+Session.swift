//
//  AtInputTextView+Session.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/15.
//  


import Foundation

extension AtInputTextView {
    
    public func updateSession(session: Any) {
        self.atListView.updateSession(session)
    }

    public func update(useOpenID: Bool) {
        self.atListView.update(useOpenID: useOpenID)
    }
}
