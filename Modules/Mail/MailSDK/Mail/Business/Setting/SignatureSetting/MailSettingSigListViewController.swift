//
//  MailSettingSigListViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/8.
//

import Foundation
import UniverseDesignTabs
import FigmaKit
import UniverseDesignIcon
import EENavigator
import RxSwift
import LarkAlertController
import UIKit
import RxRelay

protocol MailSettingSigListDelegate: AnyObject {
    func loadingFinish()
    func reloadSigData()
    func deleteSign(_ sigID: String)
    func updateSign(_ sign: MailSignature)
}
class MailSettingSigListViewController: MailBaseViewController,
                              UITableViewDelegate,
                              UITableViewDataSource,
                              UIScrollViewDelegate {
    var accountId: String = ""
    var sigList: [MailSettingSigWebModel] = []
    weak var delegate: MailSettingSigListDelegate?
    var didUpdateHeight: Bool = false
    private let didUpdateHeightCount = BehaviorRelay<Int>(value: 0)
    private var needScrollToBottom: Bool = false
    private var cellHeightCache = [Int: Int]()
    private var lockUpdateCell: Bool = false

    private lazy var headerView = MailClientSignCreateView(reuseIdentifier: "MailClientSignCreateView")

    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgFloatBase
        table.separatorStyle = .none
        if self.mailClient() {
            table.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16 + Display.bottomSafeAreaHeight, right: 0)
            table.contentOffset = CGPoint(x: 0, y: -16)
        }
        table.contentInsetAdjustmentBehavior = .never
        //let headerView = headerView
        if self.mailClient() {
            headerView.frame = CGRect(origin: .zero, size: CGSize(width: self.view?.bounds.width ?? Display.width, height: 48))
            headerView.delegate = self
            table.tableHeaderView = headerView
        }
        if self.mailClient() {
            table.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.view?.bounds.width ?? Display.width, height: 0.01)))
        } else {
            table.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: Display.width, height: Display.bottomSafeAreaHeight + 16))
        }
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        return table
    }()
    let disposeBag = DisposeBag()
    var forceRefreshContent = false

    private let accountContext: MailAccountContext

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func mailClient() -> Bool {
        return Store.settingData.isMailClient(accountId)
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        // 签名列表打开上报
        let event = NewCoreEvent(event: .email_lark_setting_mail_signature_view)
        event.params = ["target": "none"]
        event.post()

        didUpdateHeightCount
            .debounce(.milliseconds(1000), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (count) in
                guard let `self` = self else { return }
                if self.needScrollToBottom && self.didUpdateHeight {
                    //MailLogger.info("[mail_client_sign_scroll] did updateCellHeight and srcoll")
                    //self.scrollToBottom()
                    // 效果仍然不好，5.10继续优化
                }
            }).disposed(by: disposeBag)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setSigDarkModeIfNeeded()
    }

    func configSigList(sigs: [MailSettingSigWebModel],
                       newSigCnt: Int,
                       replySigCnt: Int) {
        self.sigList = sigs
        let temNum = sigs.map({ $0.sigType == 1 }).count
        let forceUse = sigs.map({ $0.forceUse == true }).count
        let customNum = sigs.map({ $0.sigType == 0 }).count
        // 签名列表打开拉取到数据后上报
        let event = NewCoreEvent(event: .email_lark_setting_mail_signature_click)
        event.params = ["target": "none",
                        "click": "signature_setting",
                        "signature_num": sigs.count,
                        "template_num": temNum,
                        "assign_num": forceUse,
                        "custom_num": customNum,
                        "new_mail_signature_num": newSigCnt,
                        "reply_forward_signature_num": replySigCnt]
        event.post()
    }

    func setupViews() {
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
//            make.edges.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }
    
    func setSigDarkModeIfNeeded() {
        for cell in tableView.visibleCells {
            if let webCell = cell as? MailSettingSigWebCell {
                webCell.setDarkModeIfNeeded()
            }
        }
    }
    
    func refreshList() {
        forceRefreshContent = true
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sigList.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let webCell = cell as? MailSettingSigWebCell {
            webCell.setDarkModeIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < self.sigList.count else {
            return UITableViewCell()
        }
        var sigModel = self.sigList[indexPath.section]
        var cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSigWebCell.identifier + sigModel.sigId)
        if let tem = cell as? MailSettingSigWebCell {
            if mailClient() {
                sigModel.canUse = true
            }
            tem.configModel(model: sigModel, forceLoad: true, vcWidth: self.view.bounds.width)
            tem.delegate = self
        } else {
            let sigCell = MailSettingSigWebCell(model: sigModel,
                                                vcWidth: self.view.bounds.width,
                                                accountId: self.accountId,
                                                accountContext: self.accountContext)
            cell = sigCell
            sigCell.delegate = self
        }
        return cell!
    }
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < self.sigList.count else {
            return 0.0
        }
        return self.sigList[indexPath.section].cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < self.sigList.count else {
            return
        }
        var sigModel = self.sigList[indexPath.section]
        signClickHandler(model: sigModel)
    }

    func signClickHandler(model: MailSettingSigWebModel) {
        if mailClient() {
            let editVC = MailClientSignEditViewController(accountID: accountId, accountContext: accountContext)
            editVC.scene = .editSign
            editVC.signModel = model
            editVC.existSignNames = sigList.map({ $0.title ?? "" })
            editVC.delegate = self
            navigator?.push(editVC, from: self)
        } else {
            if model.canUse {
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_Settings_EditSignatureInDesktop,
                                        on: self.view)
            } else {
                MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_Signature_UnableToUseNonMandatorySig_Hover,
                                        on: self.view)
            }
        }
    }
    // swiftlint:enable did_select_row_protection
}

extension MailSettingSigListViewController: MailClientSignCreateViewDelegate, MailClientSignEditViewControllerDelegate {
    func headerViewDidClickedCreate(_ footerView: MailClientSignCreateView) {
        let editVC = MailClientSignEditViewController(accountID: accountId, accountContext: accountContext)
        editVC.scene = .newSign
        editVC.signNewID = sigList.last?.sigId
        editVC.existSignNames = sigList.map({ $0.title ?? "" })
        editVC.delegate = self
        navigator?.push(editVC, from: self)
    }

    func needShowToastAndRefreshSignList(_ toast: String, inNewScene: Bool, sign: MailSignature) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
        let signModel = MailSettingSigWebModel(sign, true, false, cacheService: accountContext.cacheService)
        if inNewScene {
            let needReload = sigList.isEmpty
            sigList.append(signModel)
            if needReload {
                delegate?.reloadSigData()
                delegate?.loadingFinish()
            } else {
                tableView.insertSections([sigList.count - 1], with: .none)
                delegate?.updateSign(sign)
                //MailLogger.info("[mail_client_sign_scroll] needShowToastAndRefreshSignList setContentOffset")
                //tableView.setContentOffset(CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude), animated: false)
                tableView.scrollToRow(at: IndexPath.init(row: 0, section: self.sigList.count - 1),
                                      at: .bottom, animated: false)
                needScrollToBottom = true
                didUpdateHeightCount.accept(self.sigList.count - 1)
            }
        } else {
            if let index = sigList.firstIndex(where: { $0.sigId == signModel.sigId }) {
                sigList[index] = signModel
                UIView.performWithoutAnimation { [weak self] in
                    self?.tableView.reloadSections([index], with: .none)
                    self?.delegate?.updateSign(sign)
                }
            }
        }
    }
}

extension MailSettingSigListViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return view
    }
}

extension MailSettingSigListViewController: MailSettingSigWebCellDelegate {

    func updateCellHeight(model: MailSettingSigWebModel) {
        let index = self.sigList.firstIndex { iter in
            iter.sigId == model.sigId
        }
        if let index = index {
            self.sigList[index] = model
            UIView.performWithoutAnimation { [weak self] in
                guard let `self` = self else { return }
                self.updateCellHeight(index: index)
                if !self.didUpdateHeight {
                    self.didUpdateHeight = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                        guard let `self` = self else { return }
                        self.delegate?.loadingFinish()
                        //MailLogger.info("[mail_client_sign_scroll] didUpdateHeight callback needScrollToBottom: \(self.needScrollToBottom)")
                        if self.needScrollToBottom && index == self.sigList.count - 1 {
                            self.didUpdateHeightCount.accept(index)
                        }
                    }
                }
            }
        }
    }

    func updateCellHeight(index: Int) {
        //MailLogger.info("[mail_client_sign_scroll] updateCellHeight index: \(index)")
        self.tableView.beginUpdates()
        self.tableView.delegate?.tableView?(tableView, heightForRowAt: IndexPath.init(row: 0, section: index))
        self.tableView.endUpdates()
        self.didUpdateHeightCount.accept(index)
    }

    func clickWebView(model: MailSettingSigWebModel) {
        signClickHandler(model: model)
    }

    func deleteSign(model: MailSettingSigWebModel) {
        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_DeleteSignatureDialog)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Cancel, dismissCompletion: {
            //self.delegate?.didCancelEdit(from: self)
        })
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_ThirdClient_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            MailDataServiceFactory
                .commonDataService?
                .deleteSignature(accountID: self.accountId, signatureId: model.sigId)
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThirdClient_SignatureDeleted, on: self.view)
                    self.deleteRow(model.sigId)
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_ThirdClient_FailedToDelete, on: self.view)
                    MailLogger.error("[mail_client_sign] deleteSignature fail error:\(error)")
                }).disposed(by: self.disposeBag)
        })
        navigator?.present(alert, from: self)
    }

    func deleteRow(_ sigID: String) {
        if let index = sigList.firstIndex(where: { $0.sigId == sigID }) {
            sigList.remove(at: index)
            tableView.deleteSections([index], with: .automatic)
            if sigList.isEmpty {
                self.delegate?.reloadSigData() // 为空需要刷新空页面
            }
            self.delegate?.deleteSign(sigID)
        }
    }
}
