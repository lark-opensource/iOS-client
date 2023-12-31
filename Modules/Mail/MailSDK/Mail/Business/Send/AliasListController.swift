//
//  AliasListController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/1.
//

import Foundation
import EENavigator
import RustPB
import LarkUIKit
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont
import FigmaKit
import SnapKit

protocol AliasListDelegate: AnyObject {
    func selectedAlias(address: Email_Client_V1_Address)
    func showAliasEditPage()
    func cancel()
}

protocol TranslateTargetListDelegate: AnyObject {
    func selectedTargetLan(targetLan: MailTranslateLanguage, messageId: String)
}

enum MailPanelListType {
    case alias
    case translate
    case emailSign
    case addAlias
}

class AliasListController: WidgetViewController, UITableViewDelegate, UITableViewDataSource {

    struct Layout {
        static let cellHeight: CGFloat = 54.0
    }

    weak var delegate: AliasListDelegate?
    weak var transDelegate: TranslateTargetListDelegate?

    lazy var headerView: UIView = self.createHeaderView()
    lazy var aliasList: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.lu.register(cellSelf: MailAliasListCell.self)
        return tableView
    }()

    var type: MailPanelListType = .alias

    private lazy var addresses = [Email_Client_V1_Address]()
    private lazy var selectedAddress = String()

    private lazy var targetLanguages = [MailTranslateLanguage]()
    private lazy var selectedLan = String()
    private lazy var messageId = String()
    private var showEditButton = false
    private var aliasListHeightConstraint: Constraint?

    init(_ addresses: [Email_Client_V1_Address], _ currentAddress: MailAddress, type: MailPanelListType, showEditButton: Bool = false) {
        super.init(contentHeight: AliasListController.contentHeightWith(itemsCount: addresses.count))
        modalPresentationStyle = .overCurrentContext
        self.type = type
        self.addresses = addresses
        self.showEditButton = showEditButton
        self.selectedAddress = aliasString(currentAddress.name, currentAddress.address)
        setupViews()
    }

    init(_ lans: [MailTranslateLanguage], messageId: String) {
        super.init(contentHeight: AliasListController.contentHeightWith(itemsCount: lans.count))
        modalPresentationStyle = .overCurrentContext
        self.type = .translate
        self.targetLanguages = lans
        self.messageId = messageId
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private static func contentHeightWith(itemsCount: Int) -> CGFloat {
        return Layout.cellHeight * CGFloat(itemsCount) + Display.bottomSafeAreaHeight
    }

    func setupViews() {
        contentView.backgroundColor = .clear
        contentView.addSubview(headerView)
        contentView.addSubview(aliasList)
        aliasList.snp.makeConstraints { (make) in
            make.width.left.bottom.equalToSuperview()
            let contentHeight = AliasListController.contentHeightWith(itemsCount: dataSourceCount())
            aliasListHeightConstraint = make.height.equalTo(min(contentHeight, Display.height * 0.8)).constraint
        }
        headerView.snp.makeConstraints { make in
            make.width.left.equalToSuperview()
            make.bottom.equalTo(aliasList.snp.top)
            make.height.equalTo(48)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { context in
            let contentHeight = AliasListController.contentHeightWith(itemsCount: self.dataSourceCount())
            self.resetHeight(contentHeight)
            self.aliasListHeightConstraint?.update(offset: min(contentHeight, size.height * 0.8))
        }
    }

    func createHeaderView() -> UIView {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody

        if showEditButton {
            let editButton = UIButton()
            editButton.setTitle(BundleI18n.MailSDK.Mail_ManageSenders_Edit_Button, for: .normal)
            editButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            editButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            editButton.addTarget(self, action: #selector(editButtonClicked), for: .touchUpInside)
            headerView.addSubview(editButton)
            editButton.snp.makeConstraints { make in
                make.right.equalTo(-16)
                make.centerY.equalToSuperview()
            }
        }

        let closeButton = UIButton()
        closeButton.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = UIColor.ud.iconN1
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        headerView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        let titleLabel = UILabel()
        switch type {
        case .alias, .addAlias :
            titleLabel.text = BundleI18n.MailSDK.Mail_Edit_SelectSendAddress
        case .translate:
            titleLabel.text = BundleI18n.MailSDK.Mail_Translate_SelectTranslateLanguage
        default:
            break
        }
        titleLabel.tintColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(52)
            make.right.equalTo(-52)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
        let sep = UIView()
        sep.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        headerView.addSubview(sep)
        sep.snp.makeConstraints { make in
            make.left.bottom.width.equalToSuperview()
            make.height.equalTo(0.5)
        }
        let maskPath = UIBezierPath.squircle(
          forRect: CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: 48)),
          cornerRadii: [12.0, 12.0, 0, 0],
          cornerSmoothness: .natural
        )
        headerView.layer.ux.setMask(by: maskPath)
        return headerView
    }

    func dataSourceCount() -> Int {
        switch type {
        case .alias, .addAlias:
            return addresses.count
        case .translate:
            return targetLanguages.count
        default:
            return 0
        }
    }

    @objc
    func closeButtonClicked() {
        dismiss(animated: false, completion: nil)
//        animatedView(isShow: false)
    }

    @objc
    func editButtonClicked() {
        dismiss(animated: false, completion: nil)
        delegate?.showAliasEditPage()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        delegate?.cancel()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceCount()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MailAliasListCell.self), for: indexPath) as? MailAliasListCell else { return UITableViewCell() }
        switch type {
        case .alias, .addAlias:
            let addressName = aliasString(addresses[indexPath.row].name, addresses[indexPath.row].address)
            cell.setAddress(addressName)
            cell.isSelected = addressName == selectedAddress
        case .translate:
            let targetLan = targetLanguages[indexPath.row].sheetDisplayName
            cell.setAddress(targetLan)
            cell.isSelected = targetLan == selectedLan
        default:
            break
        }
        cell.needBorder = indexPath.row != dataSourceCount() - 1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        switch type {
        case .alias, .addAlias:
            selectedAddress = aliasString(addresses[indexPath.row].name, addresses[indexPath.row].address)
            aliasList.reloadData()
            delegate?.selectedAlias(address: addresses[indexPath.row])
            dismiss(animated: false, completion: nil)
        case .translate:
            selectedLan = targetLanguages[indexPath.row].sheetDisplayName
            aliasList.reloadData()
            transDelegate?.selectedTargetLan(targetLan: targetLanguages[indexPath.row], messageId: messageId)
            dismiss(animated: false, completion: nil)
        default:
            break
        }
    }

    private func aliasString(_ name: String, _ address: String) -> String {
        return name + " <" + address + ">"
    }
}

class MailAliasListCell: UITableViewCell {

    let checkbox = LKCheckbox(boxType: .list)
    let addressLabel = UILabel()
    let bottomBorder = UIView()

    func setAddress(_ address: String) {
        addressLabel.text = address
    }

    var needBorder = false {
        didSet {
            bottomBorder.isHidden = !needBorder
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = nil
        contentView.addSubview(checkbox)
        contentView.addSubview(addressLabel)
        bottomBorder.isHidden = !needBorder
        bottomBorder.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        contentView.addSubview(bottomBorder)
        bottomBorder.snp.makeConstraints { (maker) in
            maker.right.bottom.equalToSuperview()
            maker.height.equalTo(0.5)
            maker.left.equalTo(16)
        }

        backgroundColor = UIColor.ud.bgBase
        addressLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        addressLabel.textColor = UIColor.ud.textTitle
        setLayout()
    }

    override var isSelected: Bool {
        didSet {
            checkbox.isSelected = isSelected
            //addressLabel.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: false)
        contentView.backgroundColor = isHighlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgBody
    }

    func setLayout() {
        checkbox.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
        addressLabel.snp.makeConstraints({ (make) in
            make.height.equalTo(24)
            make.right.equalTo(checkbox.snp.left).offset(-10)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
