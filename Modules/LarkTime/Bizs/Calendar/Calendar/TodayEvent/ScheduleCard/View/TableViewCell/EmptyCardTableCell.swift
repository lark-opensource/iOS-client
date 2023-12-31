//
//  EmptyCardTableCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/17.
//

import UniverseDesignColor

class EmptyCardTableCell: UITableViewCell {

    static let identifier = String(describing: EmptyCardTableCell.self)

    private lazy var view = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(8)
        }
        self.contentView.backgroundColor = UDColor.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
