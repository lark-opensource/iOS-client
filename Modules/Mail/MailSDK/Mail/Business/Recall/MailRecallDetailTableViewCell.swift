//
//  MailRecallDetailTableViewCell.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/5/12.
//

import UIKit
import RxSwift
import UniverseDesignIcon

class MailRecallDetailTableViewCell: UITableViewCell {

    static let identifier = "RecallDetailCell"

    private let avatarImageView = UIImageView()
    private let statusIconView = UIImageView()
    private let statusLabel = UILabel()
    private let nameAddressLabel = UILabel()
    private let bottomLine = UIView()
    private var disposeBag = DisposeBag()

    var setImageTask: SetImageTask?

    private lazy var avatarThumbnailView: UILabel = {
        let view = UILabel(frame: .zero)
        view.backgroundColor = UIColor.clear
        view.textAlignment = .center
        view.textColor = UIColor.ud.primaryOnPrimaryFill
        view.font = UIFont.boldSystemFont(ofSize: 11.5)
        return view
    }()
    private lazy var gradientThumbnailContainer: UIView = {
        let view = UIView(frame: .zero)
        view.layer.addSublayer(gradientLayer)
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = .zero
        gradientLayer.colors = [UIColor.ud.color(97, 150, 255).cgColor, UIColor.ud.color(64, 127, 255).cgColor]
        return gradientLayer
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameAddressLabel)
        contentView.addSubview(statusIconView)
        contentView.addSubview(statusLabel)
        contentView.addSubview(bottomLine)
        contentView.addSubview(gradientThumbnailContainer)
        gradientThumbnailContainer.addSubview(avatarThumbnailView)

        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.left.equalTo(16)
            make.top.equalTo(15)
        }
        avatarImageView.layer.cornerRadius = 16
        avatarImageView.layer.masksToBounds = true
        avatarImageView.backgroundColor = UIColor.ud.N300

        gradientThumbnailContainer.snp.makeConstraints { (make) in
            make.edges.equalTo(avatarImageView)
        }
        gradientThumbnailContainer.layer.cornerRadius = 16
        gradientThumbnailContainer.layer.masksToBounds = true
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 32, height: 32)

        avatarThumbnailView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        nameAddressLabel.textColor = UIColor.ud.textTitle
        nameAddressLabel.font = UIFont.systemFont(ofSize: 14)
        nameAddressLabel.snp.makeConstraints { (make) in
            make.top.equalTo(11)
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }

        statusIconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.centerY.equalTo(statusLabel.snp.top).offset(8.5)
            make.left.equalTo(nameAddressLabel)
        }

        statusLabel.textColor = UIColor.ud.textTitle
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.numberOfLines = 0
        statusLabel.snp.makeConstraints { (make) in
            make.left.equalTo(statusIconView.snp.right).offset(4)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-13)
            make.top.equalTo(nameAddressLabel.snp.bottom).offset(6)
        }

        bottomLine.backgroundColor = UIColor.ud.lineBorderCard
        bottomLine.snp.makeConstraints { (make) in
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(17)
        }
    }
    func setupNameAddressLabel(name: String, address: String) {
        let attributedString = NSMutableAttributedString(string: "\(name) <\(address)>",
                                                     attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.ud.textPlaceholder, .kern: -0.3])
        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                        .foregroundColor: UIColor.ud.textTitle],
                                       range: NSRange(location: 0, length: name.count))
        nameAddressLabel.attributedText = attributedString
    }
    func updateAddressName(vm: MailRecallDetailCellViewModel) {
        guard MailAddressChangeManager.shared.addressNameOpen() else { return }
        var item = AddressRequestItem()
        item.address =  vm.address
        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
            guard let `self` = self else { return }
            if let newItem = MailAddressNameResponse.addressNameList.first {
                if !newItem.name.isEmpty &&
                    newItem.name != vm.name &&
                    !MailAddressChangeManager.shared.noUpdate(type: newItem.addressType) {
                    // update name
                    self.setupNameAddressLabel(name: newItem.name, address: vm.address)
                }
            }
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.error("recall getAddressNames resp error \(error)")
        }).disposed(by: disposeBag)
    }

    func setup(with vm: MailRecallDetailCellViewModel) {
        setupNameAddressLabel(name: vm.name, address: vm.address)
        updateAddressName(vm: vm)
        if let task = setImageTask {
            task.cancel()
        }

        if !vm.avatarKey.isEmpty {
            setImageTask = ProviderManager.default.imageProvider?.setAvatar(avatarImageView,
                                                                            key: vm.avatarKey,
                                                                            entityId: "",
                                                                            avatarImageParams: nil,
                                                                            placeholder: I18n.image(named: "avatar_placeholder"),
                                                                            progress: nil, completion: nil)

            avatarImageView.isHidden = false
            gradientThumbnailContainer.isHidden = true
        } else {
            avatarThumbnailView.text = vm.initial
            gradientThumbnailContainer.isHidden = false
            avatarImageView.isHidden = true
        }

        switch vm.status {
        case .recalling:
            statusIconView.image = Resources.mail_recalling
        case .success:
            if vm.isMaillingList, vm.numberOfFailure > 0 {
                statusIconView.image = Resources.mail_recall_fail
            } else {
                statusIconView.image = UDIcon.succeedColorful
            }
        case .failed:
            statusIconView.image = Resources.mail_recall_fail
        }
        statusLabel.text = vm.statusText
    }

}
