//
//  ZoomCommonSettingHeaderView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation

final class ZoomCommonSettingHeaderView: UIView {

    private lazy var inputHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var headerlabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    init() {
        super.init(frame: .zero)
        layoutHeaderView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutHeaderView() {
        addSubview(headerlabel)
        headerlabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.height.equalTo(22)
            make.left.right.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(4)
        }
    }

    func configHeaderTitle(title: String) {
        headerlabel.text = title
    }
}
