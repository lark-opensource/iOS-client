//
//  WikiUploadCell.swift
//  SKWikiV2
//
//  Created by bupozhuang on 2021/7/29.
//

import Foundation
import SKSpace
import UIKit
import SKCommon
import UniverseDesignColor

class WikiUploadCell: UITableViewCell {

    private lazy var uploadView = DriveUploadContentView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(uploadView)
        uploadView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(48)
        }
    }

    func update(_ model: DriveStatusItem) {
        uploadView.update(model)
    }
}
