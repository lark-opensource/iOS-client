//
//  TranslateSelectedLanguagesCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/10/15.
//

import UIKit
import Foundation
import LarkUIKit

protocol TranslateSelectedLanguages: AnyObject {
    func languageKeyDidSelect(language: String)
}

final class TranslateSelectedLanguagesCell: BaseTableViewCell, TranslateLanguagesHeaderViewDelegate {
    /// 头部被选中语言列表
    private let headerSelectView = TranslateLanguagesHeaderView()
    weak var delegate: TranslateSelectedLanguages?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.headerSelectView.delegate = self
        self.contentView.addSubview(self.headerSelectView)
        self.headerSelectView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
            make.height.equalTo(54)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTranslateLanguages(languageKeys: [String], languageValues: [String]) {
        self.headerSelectView.updateTranslateLanguages(languageKeys: languageKeys, languageValues: languageValues)
    }

    func languageKeyDidSelect(language: String) {
        self.delegate?.languageKeyDidSelect(language: language)
    }
}
