//
//  PadSceneSettingBaseCell.swift
//  ByteView
//
//  Created by kiri on 2023/3/3.
//

import Foundation

class PadSceneSettingBaseCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var item: PadSceneSettingItem? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "no override inherit empty function")
    }
}

struct PadSceneSettingItem {
    var cellType: CellType
    var title: String
    var status: Bool = false
    var displayMode: VCSwitchDisplayMode = .normal
    var switchHandler: ((Bool) -> Void)?
    var detailAction: ((UIViewController) -> Void)?

    enum CellType: String {
        case switchCell
        case detailCell
    }
}
