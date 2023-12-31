//
//  HyphenSwitchNormalCell.swift
//  LarkMine
//
//  Created by panbinghua on 2022/1/30.
//

import Foundation
import UIKit
import UniverseDesignColor

public final class HyphenSwitchNormalCell: SwitchNormalCell {
    private lazy var hyphen: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineBorderComponent
        view.snp.makeConstraints {
            $0.width.equalTo(12)
            $0.height.equalTo(1)
        }
        return view
    }()

    public override func getLeadingView() -> UIView? {
        return hyphen
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentContainer.setCustomSpacing(4, after: hyphen)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
