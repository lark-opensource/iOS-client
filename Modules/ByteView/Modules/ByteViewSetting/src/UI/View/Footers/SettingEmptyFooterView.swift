//
//  SettingEmptyFooterView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation

extension SettingDisplayFooterType {
    static let emptyFooter = SettingDisplayFooterType(reuseIdentifier: "emptyFooter",
                                                      footerViewType: SettingEmptyFooterView.self)
}

/// V:|[view(12)]|
class SettingEmptyFooterView: SettingBaseFooterView {
    private let view: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        addSubview(view)
        view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
