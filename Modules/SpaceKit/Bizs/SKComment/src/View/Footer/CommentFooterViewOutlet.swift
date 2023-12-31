//
//  CommentFooterViewOutlet.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/18.
//  

import Foundation

protocol CommentFooterViewDelegate: AnyObject {
    func changeEditState(_ isEditing: Bool)
    func isShowingAtListView(isShowing: Bool)
}
