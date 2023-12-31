//
//  ShareLinkPasswordSettingCell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/4/9.
//

import Foundation
import UIKit
import SKResource
import UniverseDesignIcon

struct PasswordSettingCellViewModel: EditLinkInfoProtocol {
    var type: EditLinkInfoCellType {
        return .password
    }
    var rightLabelContent: String
}

class ShareLinkPasswordSettingCell: SKGroupTableViewCell {

    private lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.N300
        return v
    }()

   private var contentLabel: UILabel = {
       let label = UILabel()
       label.textColor = UIColor.ud.N900
       label.font = UIFont.systemFont(ofSize: 16)
       label.text = BundleI18n.SKResource.Doc_Share_NeedPasswordAccess
       return label
    }()

    private var rightLabel: UILabel = {
       let label = UILabel()
       label.textColor = UIColor.ud.N900
       label.font = UIFont.systemFont(ofSize: 16)
       return label
    }()

    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        let image = UDIcon.getIconByKey(.rightOutlined, renderingMode: .alwaysOriginal, size: .init(width: 16, height: 16))
        view.image = image.withColor(UIColor.ud.N600)
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        containerView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(44)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-22)
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
        }

        containerView.addSubview(rightLabel)
        rightLabel.snp.makeConstraints { (make) in
            make.right.equalTo(arrowImageView.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }

        containerView.addSubview(seprateLine)
        seprateLine.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalToSuperview().offset(16)
        }
    }

    func config(rightLabelText: String) {
        self.rightLabel.text = rightLabelText
    }
}
