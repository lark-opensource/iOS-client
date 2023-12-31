//
//  MailSettingSigSelectionViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/11.
//

import Foundation
import FigmaKit
import EENavigator

protocol MailSettingSigSelectionViewControllerDelegate: AnyObject {
    func updateSigUsage(usage: SignatureUsage)
}

class MailSettingSigSelectionViewController: MailBaseViewController,
                                             UITableViewDelegate,
                                             UITableViewDataSource {
    weak var delegate: MailSettingSigSelectionViewControllerDelegate?
    var usage: SignatureUsage?
    var sigType: Int = 0 // 0: newMail 1: reply
    var uiModelList: [MailSettingSigUIModel] = []

    lazy var tableView: UITableView = {
        let table = InsetTableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.ud.bgBase
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

    var markedIndex: Int = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        self.tableView.reloadData()
    }

    func setupViews() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.bottom.right.top.equalToSuperview()
        }
    }

    func configData() {
        for index in 0 ..< self.uiModelList.count where markedIndex != -1 {
            let flag = index == markedIndex ? true : false
            self.uiModelList[index].marked = flag
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.uiModelList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard indexPath.row < self.uiModelList.count else {
            return UITableViewCell()
        }
        var uiModel = self.uiModelList[indexPath.row]
        if uiModel.marked {
            self.markedIndex = indexPath.row
        }
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
        guard indexPath.row < self.uiModelList.count else {
            return
        }
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if self.markedIndex != indexPath.row {
            self.markedIndex = indexPath.row
            configData()
            tableView.reloadData()
            // update Sig
            let model = self.uiModelList[markedIndex]
            if var usage = self.usage {
                if sigType == 0 {
                    usage.newMailSignatureID = model.sigId ?? ""
                } else {
                    usage.replyMailSignatureID = model.sigId ?? ""
                }
                self.delegate?.updateSigUsage(usage: usage)
            }
        }

    }
}
