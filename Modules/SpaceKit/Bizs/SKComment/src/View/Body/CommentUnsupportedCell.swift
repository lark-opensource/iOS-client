//
//  CommentUnsupportedCell.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/21.
//  


import SKUIKit
import SnapKit
import UniverseDesignIcon
import SKResource

class CommentUnsupportedCell: CommentShadowBaseCell {

    static let reusePadIdentifier = "CommentUnsupportedPadCell"
    
    static let reusePhoneIdentifier = "CommentUnsupportedPhoneCell"
    
    private(set) lazy var avatarImageView: UIImageView = _setupAvatarImageView()

    private(set) lazy var titleLabel: UILabel = _setupTitleLabel()
    
    var avatarImagWidth: CGFloat = 24.0
    
    var margin: CGFloat = 12.0
    
    private(set) lazy var bgView: UIView = _setupBgView()
    
    private func _setupAvatarImageView() -> UIImageView {
        let imageView = SKAvatar(configuration: .init(style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.image = UDIcon.fileRoundDocColorful
        return imageView
    }
    
    private func _setupTitleLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        setupUI(reuseIdentifier: reuseIdentifier)
    }
    
    func setupUI(reuseIdentifier: String?) {
        titleLabel.text = BundleI18n.SKResource.LarkCCM_Docs_Feed_VersionCompatibility
        let isPad = reuseIdentifier == CommentUnsupportedCell.reusePadIdentifier
        if isPad {
            contentView.addSubview(bgShadowView)
        } else {
            contentView.addSubview(bgView)
        }
        contentView.addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = avatarImagWidth / 2.0
        contentView.addSubview(titleLabel)
        
        
        if isPad {
            bgShadowView.snp.remakeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.top.equalToSuperview()
                make.left.equalToSuperview().offset(bgShadowLeftRightGap)
                make.right.equalToSuperview().offset(-bgShadowLeftRightGap)
            }
        } else {
            bgView.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview().offset(-3)
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(3)
            }
        }
        
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarImagWidth, height: avatarImagWidth))
            if isPad {
                make.left.equalTo(bgShadowView.snp.left).offset(margin)
            } else {
                make.left.equalToSuperview().offset(margin)
            }
            make.top.equalToSuperview().offset(margin)
            
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(margin)
            make.right.equalToSuperview().inset(margin)
            make.top.equalTo(avatarImageView.snp.top).offset(4)
            make.bottom.equalToSuperview().inset(margin)
        }
    }
    
}
