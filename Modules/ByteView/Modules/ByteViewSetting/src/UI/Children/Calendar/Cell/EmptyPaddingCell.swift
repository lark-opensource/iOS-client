//
//  EmptyPaddingCell.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/9/11.
//

import Foundation

extension SettingCellType {
    static let emptyPaddingCell = SettingCellType("emptyPaddingCell", cellType: EmptyPaddingCell.self)
}

final class EmptyPaddingCell: BaseSettingCell {
    let view = {
        let v = UIView()
        v.backgroundColor = .ud.bgFloat
        return v
    }()

    override func setupViews() {
        super.setupViews()
        contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(4)
        }
    }
}
