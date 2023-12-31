//
//  DocDetailCreationInfoCell.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/2/11.
//  


import Foundation
import SKResource
import UniverseDesignColor
import UIKit
import SKUIKit

/// 创建信息
class DocDetailCreationInfoCell: UITableViewCell {
    
    var onAvatarClick: (() -> Void)? {
        get {
            authorInfoView.onClick
        }
        set {
            authorInfoView.onClick = newValue
        }
    }
    
    static let reuseIdentifier = "DocDetailCreationInfoCell"
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    private lazy var authorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    private lazy var authorInfoView = AuthorInfoView()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorTitleLabel)
        contentView.addSubview(authorInfoView)
        contentView.addSubview(timeLabel)
        contentView.addSubview(lineView)
    }
    
    func update(info: DocsDetailInfoBaseInfo) {
        titleLabel.text = info.title
        
        let join = ": "
        if let item = info.rowTexts.first {
            authorTitleLabel.text = item.title + join
            authorInfoView.setName(item.value)
        }
        if info.rowTexts.count > 1 {
            let item = info.rowTexts[1]
            timeLabel.text = item.title + join + item.value
        }
    }
    
    func setAvatarUrl(_ urlString: String?) {
        authorInfoView.setAvatarUrl(urlString)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(16)
        }
        
        authorTitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
        }
        
        authorInfoView.snp.makeConstraints {
            $0.leading.equalTo(authorTitleLabel.snp.trailing)
            $0.centerY.equalTo(authorTitleLabel)
            $0.trailing.lessThanOrEqualToSuperview()
        }
        
        timeLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(authorTitleLabel.snp.bottom).offset(8)
            $0.bottom.equalTo(-16)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
        }
    }
}

private class AuthorInfoView: UIView {
    
    var onClick: (() -> Void)?
    
    private lazy var avatarView: SKAvatar = {
        let avatar = SKAvatar(configuration: .init(backgroundColor: UIColor.ud.N100, style: .circle))
        return avatar
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapped)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        
        addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.size.equalTo(20)
        }
        
        addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(4)
            $0.trailing.top.bottom.equalToSuperview()
        }
    }
    
    @objc
    private func onTapped() {
        onClick?()
    }
    
    func setName(_ name: String?) {
        label.text = name
    }
    
    func setAvatarUrl(_ urlString: String?) {
        let placeholder = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        let url = URL(string: urlString ?? "")
        avatarView.kf.setImage(with: url, placeholder: placeholder)
    }
}
