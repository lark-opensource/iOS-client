//
//  GroupModeView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2019/2/26.
//

import UIKit
import Foundation
import LarkUIKit

protocol GroupModeDescViewDelegate: AnyObject {
    func didSelected(_ view: GroupModeDescView, isSelected: Bool)
}

final class GroupModeDescView: UIView {
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        return titleLabel
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.numberOfLines = 0
        return descriptionLabel
    }()

    private lazy var selectedImageView: UIImageView = {
        let selectedImageView = UIImageView(image: Resources.language_select)
        selectedImageView.isHidden = true
        return selectedImageView
    }()

    var isSelected: Bool = false {
        didSet {
            selectedImageView.isHidden = !isSelected
        }
    }

    weak var delegate: GroupModeDescViewDelegate?

    convenience init(title: String, desc: String) {
        self.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgBody
        titleLabel.text = title
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(13)
            make.right.lessThanOrEqualToSuperview()
        }

        descriptionLabel.text = desc
        self.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.equalToSuperview().offset(-79)
            make.bottom.equalToSuperview().offset(-13)
        }

        self.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapped))
        self.addGestureRecognizer(tap)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapped() {
        if isSelected == false {
            self.delegate?.didSelected(self, isSelected: self.isSelected)
        }
    }
}
