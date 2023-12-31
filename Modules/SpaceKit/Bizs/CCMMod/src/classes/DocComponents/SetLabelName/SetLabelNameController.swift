//
//  SetLabelNameController.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/27.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import LarkModel
import LarkContainer
import UniverseDesignColor
import UniverseDesignToast
import LarkOpenChat
import Homeric
import LKCommonsTracker
import RustPB

/** 设置标签名称Controller */
public final class SetLabelNameController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    /**tableView*/
    let setLabelNameTableView: UITableView = UITableView()
    /**数据源*/
    private let setLabelNameViewModel: SetLabelNameViewModel

    public weak var chatOpenTabService: ChatOpenTabService?

    private let rightItem = LKBarButtonItem(title: BundleI18n.CCMMod.Lark_Legacy_Save)

    public init(viewModel: SendDocModel,
                chat: Chat,
                chatOpenTabService: ChatOpenTabService? = nil) {
        self.setLabelNameViewModel = SetLabelNameViewModel(sendDocModel: viewModel, chat: chat)
        self.chatOpenTabService = chatOpenTabService
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBase

        titleString = BundleI18n.CCMMod.Lark_Groups_DocumentName

        self.addNavigationBarRightItem()

        self.view.addSubview(setLabelNameTableView)
        setLabelNameTableView.backgroundColor = UDColor.bgBase
        setLabelNameTableView.lu.register(cellSelf: SetLabelNameTitleCell.self)
        setLabelNameTableView.lu.register(cellSelf: SetLabelNameDocCell.self)
        setLabelNameTableView.lu.register(cellSelf: SetLabelNameInputCell.self)
        setLabelNameTableView.delegate = self
        setLabelNameTableView.dataSource = self
        setLabelNameTableView.separatorStyle = .none
        setLabelNameTableView.keyboardDismissMode = .onDrag
        setLabelNameTableView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }

        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_NAME_SETTING_VIEW, params: [ "view": "im_chat_doc_page_name_setting_view" ]))
    }

    fileprivate func addNavigationBarRightItem() {
        let inputModel = self.setLabelNameViewModel.setLabelDataArray[3] as? SetLabelNameInputModel
        self.rightItem.setProperty(alignment: .right)
        if inputModel?.textViewInputString.count ?? 0 > 0 {
            self.rightItem.button.setTitleColor(UDColor.textLinkNormal, for: .normal)
        } else {
            self.rightItem.button.setTitleColor(UDColor.textPlaceholder, for: .normal)
        }
        self.rightItem.button.addTarget(self, action: #selector(rightBarButtonEvent), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = self.rightItem
    }

    @objc
    /**导航右侧按钮Event*/
    func rightBarButtonEvent() {
        let setLabelNameInputModel = self.setLabelNameViewModel.setLabelDataArray.last as? SetLabelNameInputModel
        if setLabelNameInputModel?.textViewInputString.count ?? 0 > 0 {
            //输入不为空才能保存
            self.preservationEvent(inputModel: setLabelNameInputModel!)
            self.rightItem.button.isEnabled = false
        }
    }

    ///保存按钮方法
    private func preservationEvent(inputModel: SetLabelNameInputModel) {
        let setLabelNameDocModel = self.setLabelNameViewModel.setLabelDataArray[1] as? SetLabelNameDocModel
        let params: [String: Any] = [
            "click": "save_doc_page",
            "target": "ccm_docs_page_view",
            "file_id": setLabelNameDocModel?.sendDocModel.id ?? "",
            "is_title_added": inputModel.textViewInputString.isEmpty ? "false" : "true"
        ]
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_PAGE_NAME_SETTING_CLICK, params: params))
        let jsonDic: [String: String] = ["name": inputModel.textViewInputString,
                                         "url": setLabelNameDocModel?.sendDocModel.url ?? ""]
        var jsonPayload: String?
        if let data = try? JSONEncoder().encode(jsonDic) {
            jsonPayload = String(data: data, encoding: .utf8)
        }
        self.chatOpenTabService?.addTab(type: .doc, name: inputModel.textViewInputString, jsonPayload: jsonPayload, success: { [weak self] _ in
            self?.rightItem.button.isEnabled = true
            self?.navigationController?.dismiss(animated: false, completion: nil)
        }, failure: { _, _ in
            self.rightItem.button.isEnabled = true
        })
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let cellModel = self.setLabelNameViewModel.setLabelDataArray[indexPath.row]

        if cellModel is SetLabelNameTitleModel {
            //（1）（3）title楼层
            return 38
        } else if cellModel is SetLabelNameDocModel {
            //（2）doc楼层
            return 68
        } else if cellModel is SetLabelNameInputModel {
            //（4）textView楼层
            return 148
        } else {
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.setLabelNameViewModel.setLabelDataArray.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = self.setLabelNameViewModel.setLabelDataArray[indexPath.row]

        if cellModel is SetLabelNameTitleModel {
            //（1）（3）title楼层
            let setLabelNameTitleModel = cellModel as? SetLabelNameTitleModel
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetLabelNameTitleCell.lu.reuseIdentifier, for: indexPath) as? SetLabelNameTitleCell {
                cell.setCellModel(setLabelNameTitleModel!)
                return cell
            } else {
                return UITableViewCell()
            }
        } else if cellModel is SetLabelNameDocModel {
            //（2）doc楼层
            let setLabelNameDocModel = cellModel as? SetLabelNameDocModel
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetLabelNameDocCell.lu.reuseIdentifier, for: indexPath) as? SetLabelNameDocCell {
                cell.setCellModel(setLabelNameDocModel!, self.setLabelNameViewModel.chat!)
                return cell
            } else {
                return UITableViewCell()
            }
        } else if cellModel is SetLabelNameInputModel {
            //（4）textView楼层
            let setLabelNameInputModel = cellModel as? SetLabelNameInputModel
            if let cell = tableView.dequeueReusableCell(withIdentifier: SetLabelNameInputCell.lu.reuseIdentifier, for: indexPath) as? SetLabelNameInputCell {
                cell.setCellModel(setLabelNameInputModel!)
                cell.editInputStatusBlock = { [weak self] (_ setInputContentStatus: SetInputContentStatus) in
                    guard let self = self else { return }
                    switch setInputContentStatus {
                    case .editEmpty:
                        self.rightItem.button.setTitleColor(UDColor.textPlaceholder, for: .normal)
                    case .editWithContent:
                        self.rightItem.button.setTitleColor(UDColor.textLinkNormal, for: .normal)
                    }
                }
                return cell
            } else {
                return UITableViewCell()
            }
        }
        return UITableViewCell()
    }
}
