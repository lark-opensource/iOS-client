//
//  SendDocSelectedViewModel.swift
//  Lark
//
//  Created by lichen on 2018/7/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel

class SendDocSelectedViewModel {

    private var items: [SendDocModel] = []
    private(set) var showItems: [SendDocModel] = []
    private(set) var deleteItems: [SendDocModel] = []

    var deleteBlock: ([SendDocModel]) -> Void

    init(items: [SendDocModel], deleteBlock: @escaping ([SendDocModel]) -> Void) {
        self.items = items
        self.showItems = items
        self.deleteBlock = deleteBlock
    }

    func delete(item: SendDocModel) {
        self.showItems = self.showItems.filter({ (doc) -> Bool in
            return doc.id != item.id
        })
        if !self.deleteItems.contains(where: { (doc) -> Bool in
            return doc.id == item.id
        }) {
            self.deleteItems.append(item)
        }
    }

    func save() {
        self.deleteBlock(self.deleteItems)
    }
}
