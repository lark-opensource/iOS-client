//
//  MailSettingSigSettingViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/8.
//

import Foundation
import UniverseDesignTabs
import EENavigator
import FigmaKit
import RxSwift

struct MailSettingSigModel {
    var address: String?
    var newMailSig: String?
    var newMailSigId: String?
    var replySig: String?
    var replySigId: String?
    var open: Bool = false
}

protocol MailSettingSigSettingDelegate: AnyObject {
    func shouldRefreshListData()
}

class MailSettingSigSettingViewController: MailBaseViewController,
                                           UITableViewDelegate,
                                           UITableViewDataSource,
                                           MailSettingSigSelectionViewControllerDelegate {
    var accountId: String = ""
    weak var delegate: MailSettingSigSettingDelegate?
    private var uiModelList: [MailSettingSigUIModel] = []
    private var dataList: [MailSettingSigModel] = []
    private var signatures: [MailSignature] = []
    private var usages: [SignatureUsage] = []
    private var canUseSigIds: [String] = []
    private var forceApply = false
    private var signatureBag: DisposeBag = DisposeBag()
    lazy var tableView: UITableView = {
        let table = InsetTableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgFloatBase
        table.separatorStyle = .none
        table.tableFooterView = UIView(frame: .zero)
        table.contentInsetAdjustmentBehavior = .never
        let view = UIView(frame: CGRect(x: 0, y: 0, width: Display.width, height: 16))
        table.tableHeaderView = view
        return table
    }()

    private let accountContext: MailAccountContext

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.bottom.right.equalToSuperview()
        }
    }

    func configSigSettings(usages: [SignatureUsage],
                           signatures: [MailSignature],
                           canUseIds: [String],
                           forceApply: Bool) {
        self.signatures = signatures
        self.canUseSigIds = canUseIds
        self.usages = usages
        self.forceApply = forceApply
        var sigSetting: [MailSettingSigModel] = []
        for usage in usages {
            var model = MailSettingSigModel()
            model.address = usage.address
            model.newMailSigId = usage.newMailSignatureID
            model.newMailSig = findSigNameById(id: usage.newMailSignatureID, sigList: signatures)
            model.replySigId = usage.replyMailSignatureID
            model.replySig = findSigNameById(id: usage.replyMailSignatureID, sigList: signatures)
            MailLogger.info("[mail_client_sign] newMailSigId: \(model.newMailSigId) newMailSig: \(model.newMailSig)")
            MailLogger.info("[mail_client_sign] replySigId: \(model.replySigId) replySig: \(model.replySig)")
            sigSetting.append(model)
        }
        self.dataList = sigSetting
        //self.dataList = self.dataList1
        genUIModelList()
        self.tableView.reloadData()
    }

    func findSigNameById(id: String, sigList: [MailSignature]) -> String {
        if let sig = sigList.first { $0.id == id } {
            return sig.name
        }
        return BundleI18n.MailSDK.Mail_BusinessSignature_NoUse
    }

    func genUIModelList() {
        uiModelList.removeAll()
        if dataList.count == 1 {
            genSection(uiModelList: &uiModelList,
                       data: dataList[0],
                       type: .SigCellRightArrowType)
            return
        }
        for data in dataList {
            let uiModel = MailSettingSigUIModel.genAddressTypeModel(sigModel: data)
            uiModelList.append(uiModel)
            if data.open {
                genSection(uiModelList: &uiModelList, data: data, type: .SigCellRightArrowMoreMarginType)
            }
        }
    }

    func genSection(uiModelList: inout [MailSettingSigUIModel],
                          data: MailSettingSigModel,
                          type: MailSettingSigCellType) {
        var newModel = MailSettingSigUIModel.genNewMailTypeModel(sigModel: data,
                                                              type: type)
        let newSigCnt = genSigSelectionModels(markId: newModel.sigId).count
        newModel.needRightArrow = newSigCnt > 1
        uiModelList.append(newModel)
        var replyModel = MailSettingSigUIModel.genReplyMailTypeModel(sigModel: data, type: type)
        let replySigCnt = genSigSelectionModels(markId: replyModel.sigId).count
        replyModel.needRightArrow = replySigCnt > 1
        uiModelList.append(replyModel)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.uiModelList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < self.uiModelList.count else {
            return UITableViewCell()
        }
        var uiModel = self.uiModelList[indexPath.row]
        let lastCell = indexPath.row == self.uiModelList.count - 1
        var cell = tableView.dequeueReusableCell(withIdentifier: uiModel.styleType.rawValue)
        if let tem = cell as? MailSettingSigCell {
            tem.configModel(model: uiModel, lastCell: lastCell)
        } else {
            let sigCell = MailSettingSigCell(model: uiModel)
            sigCell.configModel(model: uiModel, lastCell: lastCell)
            cell = sigCell
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.row < self.uiModelList.count else {
            return
        }
        var uiModel = self.uiModelList[indexPath.row]
        if uiModel.styleType == .SigCellLeftArrowType {
            // unfold
            let index = self.dataList.firstIndex { tem in
                tem.address == uiModel.title
            }
            if let index = index {
                var data = self.dataList[index]
                self.dataList[index].open = !self.dataList[index].open
                genUIModelList()
                tableView.reloadData()
            }
        } else if uiModel.styleType == .SigCellRightArrowType ||
                    uiModel.styleType == .SigCellRightArrowMoreMarginType {
            if !uiModel.needRightArrow {
                // forceApply no need to go
                return
            }
            // enter siglist page
            let vc = MailSettingSigSelectionViewController(accountContext: accountContext)
            vc.title = uiModel.title
            vc.delegate = self
            vc.uiModelList = genSigSelectionModels(markId: uiModel.sigId)
            vc.sigType = uiModel.sigType
            if let address = uiModel.address, let usage = findSigUsage(by: address) {
                vc.usage = usage
            }
            navigator?.push(vc, from: self)
        }
    }

    func findSigUsage(by address: String) -> SignatureUsage? {
        return self.usages.first { usage in
            usage.address == address
        }
    }

    func genSigSelectionModels(markId: String?) -> [MailSettingSigUIModel] {
        var list: [MailSettingSigUIModel] = []
        // 非强制模式，需要添加无签名的选项
        if !self.forceApply {
            var noSigMarked = false
            if let markId = markId,
               !markId.isEmpty,
               markId.trimmingCharacters(in: .whitespaces) != "0" {
                // 设置了签名
            } else {
                noSigMarked = true
            }

            let noSigModel = MailSettingSigUIModel.genSelectionModel(marked: noSigMarked)
            list.append(noSigModel)
        }

        for id in canUseSigIds {
            if let sig = signatures.first(where: { sig in
                sig.id == id
            }) {
                var flag = false
                if let markId = markId {
                    flag = sig.id == markId
                }
                let model = MailSettingSigUIModel.genSelectionModel(sig: sig,
                                                                    marked: flag)
                list.append(model)
            }
        }
        return list
    }

    func updateSigUsage(usage: SignatureUsage) {
        if let index = self.dataList.firstIndex { model in
            model.address == usage.address
        } {
            // UI refresh
            self.dataList[index].newMailSig = findSigNameById(id: usage.newMailSignatureID, sigList: signatures)
            self.dataList[index].newMailSigId = usage.newMailSignatureID
            self.dataList[index].replySigId = usage.replyMailSignatureID
            self.dataList[index].replySig = findSigNameById(id: usage.replyMailSignatureID, sigList: signatures)
            // usage replace
            for (index, origin) in usages.enumerated() where origin.address == usage.address {
                usages[index].newMailSignatureID = usage.newMailSignatureID
                usages[index].replyMailSignatureID = usage.replyMailSignatureID
            }
            genUIModelList()
            tableView.reloadData()
            self.accountContext.editorLoader.clearEditor(type: .enterpriseFGChange)
            // data update
            MailDataServiceFactory
                .commonDataService?.updateMailSignatureUsage(usage: usage,
                                                            accountId: self.accountId).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (listData) in
                guard let `self` = self else { return }
                MailLogger.info("[mail_client_sign] updateSigUsage success")
                    self.delegate?.shouldRefreshListData() // 得告诉签名首页。。。 简单一点 先让它刷新一次好了
                    self.accountContext.editorLoader.changeNewEditor(type: .settingChange)
            }, onError: { (err) in
                MailLogger.info("[mail_client_sign] updateSigUsage err \(err)")
            }).disposed(by: signatureBag)
        }
    }
}

extension MailSettingSigSettingViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return view
    }
}
