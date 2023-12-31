//
//  MailSendPickerDetailController.swift
//  MailSDK
//
//  Created by raozhongtao on 2023/9/5.
//

import Foundation
import RxSwift
import LarkBizAvatar
import UniverseDesignButton

class MailSendPickerDetailController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {
    let headerViewHeight: CGFloat = 42
    var viewModel: MailSendPickerViewModel
    private var disposeBag = DisposeBag()
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MailPickerDetailCell.self, forCellReuseIdentifier: MailPickerDetailCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.rowHeight = MailPickerDetailCell.cellHeight
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        return tableView
    }()

    lazy var headerViewText: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    lazy var headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: headerViewHeight))
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(headerViewText)
        headerViewText.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalTo(view.snp.centerY)
        }
        return view
    }()

    init(pickerItems: [MailContactPickerResItem]) {
        self.viewModel = MailSendPickerViewModel(pickerItems: pickerItems)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N300
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(0.5)
            make.left.right.equalToSuperview()
            make.height.equalTo(headerViewHeight)
        }
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        self.title = BundleI18n.MailSDK.Mail_ContactPicker_ContactsFailToAdd_Details_Title
        self.headerViewText.text = BundleI18n.MailSDK.Mail_ContactPicker_ContactsFailToAdd_Details_Desc(viewModel.getCellNumber())
    }


// MARK: - tableView delegate & dataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MailPickerDetailCell.identifier, for: indexPath as IndexPath)
        if let pickerCell = cell as? MailPickerDetailCell {
            pickerCell.isUserInteractionEnabled = false
            guard let model = self.viewModel.getCellInfo(index: indexPath.row) else { return UITableViewCell() }
            pickerCell.updateUI(model)
            return pickerCell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.getCellNumber()
    }

}


// MARK: - MailPickerDetailCell
class MailPickerDetailCell: UITableViewCell {
    static let cellHeight: CGFloat = 64
    private let avatarSize: CGFloat = 40
    let labelTagDistance: CGFloat = 8
    let rightMargin: CGFloat = 16 + 16 + 16
    class var identifier: String {
        return String(describing: MailPickerDetailCell.self)
    }

    lazy var avatarView: BizAvatar = {
        let avatar = BizAvatar()
        avatar.backgroundColor = UIColor.ud.N300
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = CGFloat(self.avatarSize / 2)
        avatar.layer.masksToBounds = true
        return avatar
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.text = "-"
        return label
    }()

    private lazy var defaultNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = .clear
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(avatarView)
        self.contentView.addSubview(nameLabel)

        self.avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: self.avatarSize, height: self.avatarSize))
        }
        self.avatarView.addSubview(defaultNameLabel)
        defaultNameLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
        self.nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(68)
            make.right.lessThanOrEqualTo(-16)
        }


    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(_ cellViewModel: MailPickerDetailCellViewModel) {
        self.nameLabel.text = cellViewModel.displayName

        let Id = cellViewModel.Id
        let fixedKey = cellViewModel.avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        if !fixedKey.isEmpty {
            defaultNameLabel.isHidden = true
            self.avatarView.setAvatarByIdentifier(Id, avatarKey: fixedKey,
                                                  scene: .MailRead,completion: { [weak self] result in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    if let image = (try? result.get())?.image {
                        self.avatarView.image = image
                    } else if case let .failure(error) = result {
                        MailLogger.error("MailSendPickerDetail get image faile chatterId: \(Id) with error: \(error)")
                    }
                }
            })
        } else {
            self.avatarView.image = I18n.image(named: "member_avatar_background")
            let name = cellViewModel.displayName
            if let firstName = name.first {
                defaultNameLabel.text = String(firstName)
            } else {
                defaultNameLabel.text = ""
            }
            defaultNameLabel.isHidden = false
        }

    }

}

// MARK: - MailSendPickerViewModel
class MailSendPickerViewModel {
    private var dataSource: [MailPickerDetailCellViewModel] = []
    init(pickerItems: [MailContactPickerResItem]) {
        for item in pickerItems {
            let cellVM = MailPickerDetailCellViewModel(displayName: item.displayName,
                                                       avatarKey: item.avatarKey ?? "",
                                                       Id: item.entityId)
            dataSource.append(cellVM)
        }
    }
    public func getCellNumber() -> Int {
        return dataSource.count
    }
    public func getCellInfo(index: Int) -> MailPickerDetailCellViewModel? {
        guard index < dataSource.count else { return nil }
        return dataSource[index]
    }
}

// MARK: - MailPickerDetailCellViewModel
struct MailPickerDetailCellViewModel {
    var displayName: String = ""
    var avatarKey: String = ""
    var Id: String = ""

    init(displayName: String,
         avatarKey: String,
         Id: String) {
        self.displayName = displayName
        self.avatarKey = avatarKey
        self.Id = Id
    }
    init() {}
}
