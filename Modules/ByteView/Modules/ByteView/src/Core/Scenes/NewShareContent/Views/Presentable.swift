//
//  Settings+Helps.swift
//  ByteView
//
//  Created by huangshun on 2020/4/15.
//

import Foundation

class RowPresentable: Hashable {

    typealias RowAction = (_ element: RowPresentable) -> Void

    var action: RowAction

    init(_ action: @escaping RowAction) {
        self.action = action
    }

    static func == (lhs: RowPresentable, rhs: RowPresentable) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    var type: RowPresentableCell.Type {
        return RowPresentableCell.self
    }

    var height: CGFloat {
        return 56.0
    }

}

class RowPresentableCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = backgroundColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configRowPresentable(_ presentable: RowPresentable) {

    }

}

class SectionPresentable {

    var rowsMap: [RowPresentable: RowPresentableCell] = [:]

    var rows: [RowPresentable] = []

    init(_ rows: [RowPresentable]) {
        self.rows = rows
    }

    func cellForRow(_ row: RowPresentable) -> RowPresentableCell {
        guard self.rowsMap[row] == nil
            else { return self.rowsMap[row]! }

        let cell = row.type.init()
        self.rowsMap[row] = cell
        return cell
    }

}
