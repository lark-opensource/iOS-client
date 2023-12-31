//
//  UDActionSheet+TableView.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/11/2.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignFont

class UDActionSheetTableCell: UITableViewCell {
    static var identifier: String = String(describing: UDActionSheetTableCell.self)

    private var padding = 12

    private var title: UILabel = {
        let title = UILabel()
        title.font = UIFont.ud.title4(.fixed)
        title.textAlignment = .center
        return title
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(title)
        // cell的背景设为透明，只有点击时有颜色
        self.backgroundColor = .clear
        let selectBackground = UIView()
        selectBackground.backgroundColor = UDActionPanelColorTheme.acPrimaryBgPressedColor
        self.selectedBackgroundView = selectBackground

        title.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-padding)
            make.leading.equalToSuperview().offset(padding)
            make.top.equalToSuperview().offset(padding)
            make.bottom.equalToSuperview().offset(-padding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(item: UDActionSheetItem) {
        self.isUserInteractionEnabled = item.isEnable

        self.title.text = item.title

        switch item.style {
        case .default:
            self.title.textColor = UDActionPanelColorTheme.acPrimaryBtnNormalColor
        case .cancel:
            self.title.textColor = UDActionPanelColorTheme.acPrimaryBtnCancleColor
        case .destructive:
            self.title.textColor = UDActionPanelColorTheme.acPrimaryBtnErrorColor
        }

        if let color = item.titleColor {
            self.title.textColor = color
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.separatorInset = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
        self.title.text = nil
    }
}
