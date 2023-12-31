//
//  SettingEmptyHeaderView.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation

extension SettingDisplayHeaderType {
    static let emptyHeader = SettingDisplayHeaderType(reuseIdentifier: "emptyHeader",
                                                      headerViewType: SettingEmptyHeaderView.self)
}

/// V:|[view(4)]|
class SettingEmptyHeaderView: SettingBaseHeaderView {
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
