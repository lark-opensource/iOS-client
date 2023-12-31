//
//  PasswordSettingFooterView.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SKResource
import UniverseDesignColor

class PasswordSettingFooterView: UIView {

    private let isFolder: Bool

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.N500
        return label
    }()

    init(isFolder: Bool) {
        self.isFolder = isFolder
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // 文档和文件夹的文案不同
        titleLabel.text = isFolder ? BundleI18n.SKResource.Doc_Share_FolderCreatePasswordTip : BundleI18n.SKResource.Doc_Share_CreatePasswordTip
        backgroundColor = UDColor.bgBase
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(16)
            make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-16)
            make.top.equalToSuperview().offset(2)
        }
    }
}
