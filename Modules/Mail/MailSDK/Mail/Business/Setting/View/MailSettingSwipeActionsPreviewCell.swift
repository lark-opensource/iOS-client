//
//  MailSettingSwipeActionsPreviewCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/1/29.
//

import Foundation
import RxSwift
import UniverseDesignIcon

class MailSettingSwipeActionsPreviewCell: UITableViewCell {
    let disposeBag = DisposeBag()
    private let titleLabel: UILabel = UILabel()
    private let detailLabel: UILabel = UILabel()
    private let arrowImageView = UIImageView()
    private var tipView: MailSettingSwipeActionsPreview = MailSettingSwipeActionsPreview()
    private var checkBoxIsSelected = false
    private var checkBoxIsEnabled = false

    weak var dependency: MailSettingStatusCellDependency?
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }
    var superViewWidth: CGFloat = 279

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(tipView)

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(12)
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(22)
        }
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        detailLabel.isHidden = true
        detailLabel.numberOfLines = 0
        
        arrowImageView.image = UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UIColor.ud.iconN3
        contentView.addSubview(arrowImageView)

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
        contentView.backgroundColor = UIColor.ud.bgFloat
    }
    
    func showOnboard() {
        tipView.swipeOnboard()
    }

    @objc
    func didClickCell() {
        if let current = item as? MailSettingSwipeOrientationModel {
            current.switchHandler(current.status)
        }
    }

    func setCellInfo() {
        titleLabel.isHidden = true
        detailLabel.isHidden = true
        tipView.isHidden = true
        if let current = item as? MailSettingSwipeOrientationModel {
            titleLabel.isHidden = false
            titleLabel.text = current.orientation.oriTitle()
            
            detailLabel.isHidden = false
            if !current.status || current.actions.isEmpty {
                detailLabel.text = BundleI18n.MailSDK.Mail_EmailSwipeActions_NotSet_Text
                detailLabel.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.top.equalTo(titleLabel.snp.bottom).offset(4)
                    make.height.equalTo(18)
                    make.bottom.equalTo(-12)
                }
                arrowImageView.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.size.equalTo(CGSize(width: 12, height: 12))
                    make.right.equalTo(-16)
                }
            } else {
                detailLabel.text = current.actions.actionPreviewTitle()
                detailLabel.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.top.equalTo(titleLabel.snp.bottom).offset(4)
                    make.height.equalTo(18)
                }
                tipView.isHidden = false
                tipView.setActionsAndLayoutView(orientation: current.orientation, actions: current.actions)
                tipView.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview().inset(16)
                    make.top.equalTo(detailLabel.snp.bottom).offset(12)
                    make.height.equalTo(80)
                    make.bottom.equalTo(-12)
                }
                arrowImageView.snp.remakeConstraints { (make) in
                    make.top.equalTo(28)
                    make.size.equalTo(CGSize(width: 12, height: 12))
                    make.right.equalTo(-16)
                }
            }
        }
    }
}
