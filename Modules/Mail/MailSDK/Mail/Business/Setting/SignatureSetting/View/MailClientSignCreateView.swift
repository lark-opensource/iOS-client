//
//  MailClientSignCreateView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/12/15.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import UniverseDesignIcon

protocol MailClientSignCreateViewDelegate: AnyObject {
    func headerViewDidClickedCreate(_ footerView: MailClientSignCreateView)
}

class MailClientSignCreateView: UITableViewHeaderFooterView {

    weak var delegate: MailClientSignCreateViewDelegate?

    private let disposeBag = DisposeBag()
    private lazy var titleLabel = self.makeTitleLabel()
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.primaryContentDefault
        label.textAlignment = .left
        label.text = BundleI18n.MailSDK.Mail_ThirdClient_AddSignature
        return label
    }
    
    private lazy var addIcon = self.makeAddIcon()
    private func makeAddIcon() -> UIImageView {
        let icon = UIImageView()
        icon.image = UDIcon.addOutlined.withRenderingMode(.alwaysTemplate)
        icon.tintColor = UIColor.ud.primaryContentDefault
        return icon
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCreate)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(addIcon)
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        addIcon.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(addIcon.snp.right).offset(4)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func didClickCreate() {
        delegate?.headerViewDidClickedCreate(self)
    }
}
