//
//  IterableAdapter.swift
//  ByteView
//
//  Created by huangshun on 2020/4/15.
//

import Foundation

class IterableAdapter {

    weak var tableView: UITableView?

    let sections: [SectionPresentable]

    init(_ sections: [SectionPresentable]) {
        self.sections = sections
    }

}
