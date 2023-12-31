//
//  MailDocShareLinkViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/5/4.
//

import UIKit
import FigmaKit
import UniverseDesignFont
import UniverseDesignNotice
import UniverseDesignColor
import UniverseDesignIcon
import RustPB
import UniverseDesignToast
import RxSwift
import LarkUIKit

protocol MailDocShareLinkVCDelegate: AnyObject {
    func fetchManagerMeta(model: DocShareModel) -> Observable<Bool>
    func docPageSendMail(models: [DocShareModel],
                         sendHandler: ((_ content: MailContent) -> Bool)?,
                         content: MailContent)
}

struct DocShareModel {
    let token: String
    let docUrl: String
    var title: String
    var author: String
    var docType: Email_Client_V1_DocStruct.ObjectType
    var permission: Email_Client_V1_DocsPermissionConfig.ShareLinkAction
    var changePermission: Bool = false // 是否有权限修改权限
    var manageCollaborator: Bool = false // 是否有共享权限
    var forbidReason: String = ""    //无法修改的原因
    var sortNum: Int = Int.max  //用于排序
    let uuid: String
    init(title: String,
         author: String,
         docType: Email_Client_V1_DocStruct.ObjectType,
         permission: Email_Client_V1_DocsPermissionConfig.ShareLinkAction,
         manageCollaborator: Bool,
         token: String,
         docUrl: String) {
        self.token = token
        self.docUrl = docUrl
        self.title = title
        self.author = author
        self.docType = docType
        self.permission = permission
        self.manageCollaborator = manageCollaborator
        self.uuid = UUID().uuidString
    }
}

class MailDocShareLinkViewController: MailBaseViewController,
                                        UITableViewDataSource,
                                        UITableViewDelegate {
    
    var dataSource: [DocShareModel] = []
    let headerHeight = 16.0
    private(set) var disposeBag = DisposeBag()
    weak var delegate: MailDocShareLinkVCDelegate?
    var sendHandler: ((_ content: MailContent) -> Bool)? = nil
    let mailContent: MailContent
    /// 创建表格视图
    lazy var tableView: UITableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 16 + Display.bottomSafeAreaHeight, right: 0)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: Display.bottomSafeAreaHeight + 16))
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault

        /// registerCell
        tableView.lu.register(cellSelf: MailDocShareLinkCell.self)
        
        return tableView
    }()
    
    lazy var tipsView: UDNotice = {
        let config = self.genTipsConfig(text: BundleI18n.MailSDK.Mail_MobileLink_EnableExternalAccess_Banner(1))
        let view = UDNotice(config: config)
        view.clipsToBounds = true
        return view
    }()
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgFloat
        let config = genTipsConfig(text: BundleI18n.MailSDK.Mail_MobileLink_EnableExternalAccess_Banner(self.dataSource.count))
        self.tipsView.updateConfigAndRefreshUI(config)
        self.title = BundleI18n.MailSDK.Mail_MobileLink_EnableExternalLinkSharing_Title
        setupView()
        setupRightBarItem()
    }
    private func genTipsConfig(text: String) -> UDNoticeUIConfig {
        let attributedString = NSAttributedString(string: text,
                                      attributes: [.foregroundColor: UIColor.ud.textTitle])
        let config = UDNoticeUIConfig(type: .warning, attributedText: attributedString)
        return config
    }
    private func setupRightBarItem() {
        let item = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_LinkSharing_Enable_ConfirmSend_Button)
        item.button.addTarget(self, action: #selector(sendMail), for: .touchUpInside)
        item.setBtnColor(color: UDColor.primaryPri500)
        navigationItem.rightBarButtonItem = item
    }
    let accountContext: MailAccountContext
    
    init(mailContent: MailContent, accountContext: MailAccountContext) {
        self.mailContent = mailContent
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.view.addSubview(tipsView)
        self.view.addSubview(tableView)
        let tipsHeight = self.tipsView.heightThatFitsOrActualHeight(containerWidth: self.view.bounds.size.width)
        tipsView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(tipsHeight)
        }
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(tipsView.snp.bottom)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < dataSource.count else { return 0 }
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < dataSource.count else {
            return UITableViewCell()
        }
        let model = dataSource[indexPath.section]
        guard let linkCell = tableView.dequeueReusableCell(withIdentifier: MailDocShareLinkCell.lu.reuseIdentifier) as? MailDocShareLinkCell else {
            return MailDocShareLinkCell()
        }
        linkCell.selectionStyle = .none
        linkCell.delegate = self
        linkCell.updateModel(model: model)
        
        return linkCell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < dataSource.count else {
            return 0.0
        }
        return headerHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < dataSource.count else {
            return 0.0
        }
        let model = dataSource[indexPath.section]
        if model.permission == .shareEdit || model.permission == .shareRead {
            return MailDocShareLinkCell.openHeight
        } else {
            return MailDocShareLinkCell.closeHeight
        }
    }
    @objc func sendMail() {
        self.delegate?.docPageSendMail(models: self.dataSource,
                                       sendHandler: self.sendHandler,
                                       content: self.mailContent)
    }
}

extension MailDocShareLinkViewController: MailDocShareLinkCellDelegate {
    func linkCellStatusChange(model: DocShareModel) {
        if let index = self.dataSource.firstIndex(where: {$0.uuid == model.uuid}) {
            self.dataSource[index] = model
            self.tableView.reloadData()
        }
    }
    func showNoChangeToast(text: String) {
        UDToast.showFailure(with: text, on: self.view)
    }
}
