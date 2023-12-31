//
//  ZoomHostSearchResultCell.swift
//  Calendar
//
//  Created by pluto on 2022/11/2.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignColor

final class ZoomHostSearchResultCell: UITableViewCell {

    var deleteCallBack: (() -> Void)?
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private lazy var deleteBtn: UIButton = {
        let deleteButton = UIButton(type: .custom)
        deleteButton.increaseClickableArea()
        deleteButton.setImage(UDIcon.getIconByKeyNoLimitSize(.closeOutlined).scaleInfoSize().renderColor(with: .n3), for: .normal)
        deleteButton.addTarget(self, action: #selector(didDeleteButtonClick), for: .touchUpInside)
        return deleteButton
    }()

    private lazy var topLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    var showTopLine: Bool = true {
        didSet { topLineView.isHidden = !showTopLine }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layoutCellContent()
        selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutCellContent() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(deleteBtn)
        contentView.addSubview(topLineView)

        deleteBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(deleteBtn.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }

        topLineView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func configCellInfo(title: String) {
        titleLabel.text = title
    }

    @objc
    private func didDeleteButtonClick() {
        self.deleteCallBack?()
    }
}
