//
//  MailThreadMultiSelectAble.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/9/20.
//

import Foundation

protocol MailThreadListMultiActionAble {
    /// you can just return isEditing of tableView
    var isMultiSelecting: Bool { get }

    func updateThreadActionBar()
}
