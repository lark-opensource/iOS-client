//
//  MailAttachmentSettingViewController.swift
//  MailSDK
//
//  Created by Ender on 2023/6/6.
//


import FigmaKit
import RxSwift
import UniverseDesignCheckBox
import UniverseDesignIcon
import RustPB


final class MailAttachmentSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    private weak var viewModel: MailSettingViewModel?
    private var attachmentLocation: MailAttachmentLocation {
        didSet {
            guard oldValue != attachmentLocation else { return }
            viewModel?.updateAttachmentSetting(attachmentLocation)
            tableView.reloadData()
        }
    }
    private let disposeBag = DisposeBag()

    init(viewModel: MailSettingViewModel?) {
        self.viewModel = viewModel
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.attachmentLocation = setting.attachmentLocation
        } else {
            self.attachmentLocation = .bottom
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel?.updateAttachmentSwitch(attachmentLocation == .top)
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    lazy var tableView: InsetTableView = {
        let table = InsetTableView(frame: .zero)
        table.rowHeight = 235
        table.separatorStyle = .none
        table.backgroundColor = UIColor.ud.bgFloatBase
        table.dataSource = self
        table.delegate = self
        table.lu.register(cellSelf: MailAttachmentSettingOptionCell.self)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Title
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        reloadData()

        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    private func reloadData() {
        if let setting = viewModel?.getPrimaryAccountSetting()?.setting {
            self.attachmentLocation = setting.attachmentLocation
        } else {
            self.attachmentLocation = .bottom
        }
    }

    // MARK: TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MailAttachmentSettingOptionCell.reuseIdentifier) as? MailAttachmentSettingOptionCell else {
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.type = .top
            cell.isSelected = (attachmentLocation == .top)
            cell.setupViews(isTopAttachment: true)
        } else if indexPath.row == 1 {
            cell.type = .bottom
            cell.isSelected = (attachmentLocation == .bottom)
            cell.setupViews(isTopAttachment: false)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MailAttachmentSettingOptionCell else { return }
        attachmentLocation = cell.type
    }
}


final class MailAttachmentSettingOptionCell: UITableViewCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    private lazy var checkBox: UDCheckBox = {
        let box = UDCheckBox(boxType: .single)
        box.isUserInteractionEnabled = false
        return box
    }()
    private lazy var preview = MailAttachmentSettingPreview()

    override var isSelected: Bool {
        didSet {
            checkBox.isSelected = isSelected
        }
    }

    var type: MailAttachmentLocation = .bottom

    func setupViews(isTopAttachment: Bool) {
        contentView.addSubview(checkBox)
        contentView.addSubview(titleLabel)
        contentView.addSubview(preview)
        checkBox.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.left.equalTo(16)
            make.height.width.equalTo(20)
        }
        titleLabel.text = (type == .top ? BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Above_Checkbox
                                        : BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_Below_Checkbox)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalTo(checkBox.snp.centerY)
        }
        preview.snp.makeConstraints { make in
            make.left.top.equalTo(48)
            make.height.equalTo(171)
            make.width.equalTo(279)
        }
        preview.setupViews(isTopAttachment: isTopAttachment)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat
        self.isSelected = false
    }
}

final class MailAttachmentSettingPreview: UIView {
    private lazy var body = UIView()
    private lazy var attachmentContainer = UIView()
    private lazy var attachment1 = UIView()
    private lazy var attachment1Name = UIView()
    private lazy var attachment1Info = UIView()
    private lazy var attachment2 = UIView()
    private lazy var attachment2Name = UIView()
    private lazy var attachment2Info = UIView()
    private lazy var text1 = UIView()
    private lazy var text2 = UIView()
    private lazy var text3 = UIView()

    private lazy var avatar: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 14
        view.image = Resources.avatar_person
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_UserName("UX Daily")
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 10)
        label.text = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_EmailAddress(emailAddress: "uxdaily@company.com")
        return label
    }()

    private lazy var attachmentIconWord: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.fileWordColorful
        return view
    }()

    private lazy var attachmentIconVideo: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.fileVideoColorful
        return view
    }()

    func setupViews(isTopAttachment: Bool) {
        self.backgroundColor = UIColor.ud.bgFloatOverlay
        self.layer.cornerRadius = 8

        addSubview(body)
        body.backgroundColor = UIColor.ud.bgBody
        body.layer.cornerRadius = 6
        body.layer.borderWidth = 1
        body.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        body.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        body.addSubview(avatar)
        body.addSubview(nameLabel)
        body.addSubview(addressLabel)
        body.addSubview(attachmentContainer)
        body.addSubview(text1)
        body.addSubview(text2)
        body.addSubview(text3)

        avatar.snp.makeConstraints { make in
            make.height.width.equalTo(28)
            make.top.equalTo(11)
            make.left.equalTo(10)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(10)
            make.left.equalTo(avatar.snp.right).offset(6)
            make.height.equalTo(18)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(27)
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(13)
        }

        attachmentContainer.backgroundColor = UIColor.ud.B200
        attachmentContainer.layer.cornerRadius = 6
        text1.backgroundColor = UIColor.ud.N300
        text1.layer.cornerRadius = 2
        text2.backgroundColor = UIColor.ud.N300
        text2.layer.cornerRadius = 2
        text3.backgroundColor = UIColor.ud.N300
        text3.layer.cornerRadius = 2

        if isTopAttachment {
            attachmentContainer.snp.makeConstraints { make in
                make.top.equalTo(avatar.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(34)
            }
            text1.snp.makeConstraints { make in
                make.top.equalTo(attachmentContainer.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(8)
            }
            text2.snp.makeConstraints { make in
                make.top.equalTo(text1.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(8)
            }
            text3.snp.makeConstraints { make in
                make.top.equalTo(text2.snp.bottom).offset(6)
                make.left.equalTo(10)
                make.width.equalTo(94)
                make.height.equalTo(8)
            }
        } else {
            text1.snp.makeConstraints { make in
                make.top.equalTo(avatar.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(8)
            }
            text2.snp.makeConstraints { make in
                make.top.equalTo(text1.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(8)
            }
            text3.snp.makeConstraints { make in
                make.top.equalTo(text2.snp.bottom).offset(6)
                make.left.equalTo(10)
                make.width.equalTo(94)
                make.height.equalTo(8)
            }
            attachmentContainer.snp.makeConstraints { make in
                make.top.equalTo(text3.snp.bottom).offset(10)
                make.left.right.equalToSuperview().inset(10)
                make.height.equalTo(34)
            }
        }

        attachmentContainer.addSubview(attachment1)
        attachmentContainer.addSubview(attachment2)

        attachment1.backgroundColor = UIColor.ud.bgBody
        attachment1.layer.cornerRadius = 4
        attachment1.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(4)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-6.5)
        }
        attachment2.backgroundColor = UIColor.ud.bgBody
        attachment2.layer.cornerRadius = 4
        attachment2.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(4)
            make.width.equalToSuperview().multipliedBy(0.5).offset(-6.5)
        }

        attachment1.addSubview(attachmentIconWord)
        attachment1.addSubview(attachment1Name)
        attachment1.addSubview(attachment1Info)
        attachmentIconWord.snp.makeConstraints { make in
            make.height.width.equalTo(16)
            make.top.equalTo(5)
            make.left.equalTo(4)
        }
        attachment1Name.backgroundColor = UIColor.ud.B200
        attachment1Name.layer.cornerRadius = 2
        attachment1Name.snp.makeConstraints { make in
            make.top.equalTo(7)
            make.left.equalTo(attachmentIconWord.snp.right).offset(4)
            make.right.equalTo(-17)
            make.height.equalTo(4)
        }
        attachment1Info.backgroundColor = UIColor.ud.B200
        attachment1Info.layer.cornerRadius = 2
        attachment1Info.snp.makeConstraints { make in
            make.top.equalTo(attachment1Name.snp.bottom).offset(4)
            make.left.equalTo(attachment1Name.snp.left)
            make.height.equalTo(4)
            make.width.equalTo(33)
        }

        attachment2.addSubview(attachmentIconVideo)
        attachment2.addSubview(attachment2Name)
        attachment2.addSubview(attachment2Info)
        attachmentIconVideo.snp.makeConstraints { make in
            make.height.width.equalTo(16)
            make.top.equalTo(5)
            make.left.equalTo(4)
        }
        attachment2Name.backgroundColor = UIColor.ud.B200
        attachment2Name.layer.cornerRadius = 2
        attachment2Name.snp.makeConstraints { make in
            make.top.equalTo(7)
            make.left.equalTo(attachmentIconVideo.snp.right).offset(4)
            make.right.equalTo(-17)
            make.height.equalTo(4)
        }
        attachment2Info.backgroundColor = UIColor.ud.B200
        attachment2Info.layer.cornerRadius = 2
        attachment2Info.snp.makeConstraints { make in
            make.top.equalTo(attachment2Name.snp.bottom).offset(4)
            make.left.equalTo(attachment2Name.snp.left)
            make.height.equalTo(4)
            make.width.equalTo(33)
        }
    }
}
