//
//  MailSendSignatureListVC.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/17.
//

import Foundation
protocol MailSendSignatureListVCDelegate: AnyObject {
    func didSelectSig(sigId: String)
    func getSignatureListByAddress(sigData: SigListData) -> ([MailSignature], String, Bool)
}
class MailSendSignatureListVC: MailBaseViewController,
                              UITableViewDelegate,
                              UITableViewDataSource {
    let tableHeaderHeight: CGFloat = 48
    let cellHeight: CGFloat = 48
    var tableViewHeight: CGFloat = 0.0
    static let bottomMargin: CGFloat = 12
    let tableBottomMargin: CGFloat = bottomMargin + Display.bottomSafeAreaHeight
    var markedIndex: Int = -1
    var model: [MailSettingSigUIModel] = []
    weak var delegate: MailSendSignatureListVCDelegate?
    lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgBody
        table.separatorStyle = .none
        table.tableFooterView = UIView(frame: .zero)
        table.contentInsetAdjustmentBehavior = .never
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: tableBottomMargin)
        table.tableFooterView = view
        view.backgroundColor = UIColor.ud.bgBody
        return table
    }()
    lazy var bgMask: UIButton = {
        let view = UIButton()
        view.addTarget(self, action: #selector(didClickBgView), for: .touchUpInside)
        view.backgroundColor = UIColor.ud.bgMask
        view.alpha = 0.0
        return view
    }()
    lazy var tableHeader: UIView = {
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 48)
        let closeButton = UIButton()
        closeButton.setImage(Resources.mail_signature_close.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(didClickBgView), for: .touchUpInside)
        closeButton.tintColor = UIColor.ud.iconN1
        closeButton.frame = CGRect(x: 22, y: 17, width: 14, height: 14)
        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        view.addSubview(closeButton)
        let label = UILabel()
        label.text = BundleI18n.MailSDK.Mail_BusinessSignature_SelectSignature
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        view.addSubview(label)
        label.sizeToFit()
        label.center = view.center
        // bottomline
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        view.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    private let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        genData()
        setupViews()
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    func genData() {
        if let data = Store.settingData.getCachedCurrentSigData() {
            var array: [MailSettingSigUIModel] = []
            guard let sigDelegate = self.delegate else {
                return
            }
            let (list, markedId, forceApply) = sigDelegate.getSignatureListByAddress(sigData: data)
            for signature in list {
                var m = MailSettingSigUIModel()
                m.title = signature.name
                if signature.id == markedId {
                    m.marked = true
                }
                m.styleType = .SigCellMarkType
                m.sigId = signature.id
                array.append(m)
            }
            let editableFgOpen = accountContext.featureManager.open(.signatureEditable)
            if editableFgOpen || (array.count > 0 && !forceApply) {
                // 无签名构造
                var m = MailSettingSigUIModel()
                m.title = BundleI18n.MailSDK.Mail_BusinessSignature_NoUse
                if markedId.isEmpty || markedId.trimmingCharacters(in: .whitespaces) == "0" {
                    m.marked = true
                }
                m.disableStyle = editableFgOpen && forceApply
                m.styleType = .SigCellMarkType
                m.sigId = ""
                array.insert(m, at: 0)
            }
            self.model = array
        } else {
            MailLogger.error("empty sig data")
        }
    }

    @objc
    func didClickBgView() {
        self.animatedView(isShow: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.animatedView(isShow: true)
    }

    func animatedView(isShow: Bool) {
        let alpha: CGFloat = isShow ? 1.0 : 0
        let animationDuration = 0.15
        /// show or dismiss backgroud mask view animation
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       animations: { [weak self]  in
                        guard let `self` = self else { return }
                        self.bgMask.alpha = alpha
                        if isShow {
                            self.tableView.frame = CGRect(x: 0,
                                                          y: UIScreen.main.bounds.height - self.tableViewHeight,
                                                          width: self.view.bounds.width,
                                                          height: self.tableViewHeight)
                            self.tableHeader.frame = CGRect(x: 0,
                                                            y: UIScreen.main.bounds.height - self.tableViewHeight - self.tableHeaderHeight,
                                                            width: self.view.bounds.width,
                                                            height: self.tableHeaderHeight)
                        } else {
                            self.tableView.frame = CGRect(x: 0,
                                                          y: UIScreen.main.bounds.height + self.tableHeaderHeight,
                                                          width: self.view.bounds.width,
                                                          height: self.tableViewHeight)
                            self.tableHeader.frame = CGRect(x: 0,
                                                            y: UIScreen.main.bounds.height,
                                                            width: self.view.bounds.width,
                                                            height: self.tableHeaderHeight)
                        }
        }, completion: { [weak self](_) in
            guard let `self` = self else { return }
            if !isShow {
                self.dismiss(animated: true, completion: nil)
            }
        })

    }

    func setupViews() {
        self.view.backgroundColor = .clear
        self.view.addSubview(bgMask)
        self.view.addSubview(tableView)
        self.view.addSubview(tableHeader)
        bgMask.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalToSuperview()
        }
        var totalHeight = tableBottomMargin + cellHeight * CGFloat(model.count)
        var tableHeight = totalHeight
        let heightRate: CGFloat = 0.8
        if Display.height * heightRate < tableHeight {
            tableHeight = Display.height * heightRate
        }
        self.tableViewHeight = tableHeight
        tableView.frame = CGRect(x: 0,
                                 y: self.view.bounds.height + tableHeaderHeight,
                                 width: self.view.bounds.size.width,
                                 height: tableHeight)
        tableHeader.frame = CGRect(x: 0,
                                   y: self.view.bounds.height,
                                   width: self.view.bounds.size.width,
                                   height: tableHeaderHeight)
        let radius: CGFloat = 12
        tableHeader.addCorner([.topLeft, .topRight], radius, withRadii: CGSize(width: self.view.bounds.width, height: tableHeaderHeight))
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.model.count else {
            return UITableViewCell()
        }
        var uiModel = self.model[indexPath.row]
        if uiModel.marked {
            self.markedIndex = indexPath.row
        }
        let lastCell = indexPath.row == self.model.count - 1
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
        guard indexPath.row < self.model.count else {
            return
        }
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if self.markedIndex != indexPath.row {
            if self.model[indexPath.row].disableStyle {
                // disable态不响应点击
                return
            }
            self.markedIndex = indexPath.row
            let index = self.model.firstIndex { tem in
                tem.marked == true
            }
            if let index = index {
                self.model[index].marked = false
            }
            self.model[self.markedIndex].marked = true
            tableView.reloadData()
            if let sigId = self.model[self.markedIndex].sigId {
                delegate?.didSelectSig(sigId: sigId)
                self.didClickBgView()
            }
        }

    }
}
