//
//  AdditionalTimeZoneHeaderCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/24.
//

import Foundation
import UniverseDesignColor

class AdditionalTimeZoneHeaderCell: UITableViewHeaderFooterView {
    static let identifier = String(describing: AdditionalTimeZoneHeaderCell.self)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let divideLine = EventBasicDivideView()
        self.contentView.addSubview(divideLine)
        divideLine.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.contentView.backgroundColor = UDColor.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
