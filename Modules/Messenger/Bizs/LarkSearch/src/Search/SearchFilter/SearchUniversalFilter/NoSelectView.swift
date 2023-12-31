//
//  NoSelectView.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/9/12.
//

import UIKit
import Foundation
import LarkSearchCore
import UniverseDesignEmpty

//临时，之后做推荐页后删掉
final class NoSelectView: UIView {
    let textLabel = UILabel()
    let icon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
    }

    convenience init(pickType: UniversalPickerType) {
        self.init()
        setupView()
        self.icon.image = UDEmptyType.noFile.defaultImage()
        switch pickType {
        case .folder:
            self.textLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_DocsTabFilters_InFolder_MobileEmptyState
        case .workspace:
            self.textLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_DocsTabFilters_InWorkspace_MobileEmptyState
        case .filter:
            self.textLabel.text = BundleI18n.LarkSearch.Lark_Search_NewSearch_Common_EnterKeywordToSearch_EmptyState
        case .chat, .defaultType:
            break
        default: break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(icon)
        addSubview(textLabel)

        textLabel.textAlignment = .center
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = .ud.textCaption
        textLabel.lineBreakMode = .byTruncatingMiddle

        icon.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(108)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        })
        textLabel.snp.makeConstraints({ make in
            make.top.equalTo(icon.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
//            make.bottom.equalToSuperview()
        })
    }
}
