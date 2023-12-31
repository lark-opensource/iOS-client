//
//  MailSendController+InputView.swift
//  DocsSDKDemo
//
//  Created by majx on 2019/6/7.
//

import Foundation
import RxSwift
import EENavigator
import RustPB
import Homeric
import LarkUIKit
import LarkGuideUI
import LarkAlertController
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignActionPanel
import UIKit

// MARK: - UITableViewDataSource & Delegate
// MARK: - UITableViewDataSource & Delegate
extension MailSendController {

    func _tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableHeaderView
    }

    func _tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        editionInputView == nil ? mentionHeaderHeight : 0
    }

    func _tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredArray.count
    }

    func _tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MailAddressCellConfig.identifier, for: indexPath as IndexPath)
        if cell is MailAddressCell {
            if let temCell = cell as? MailAddressCell {
                temCell.delegate = self
            }
            if indexPath.row < self.viewModel.filteredArray.count {
                let viewModel = self.viewModel.filteredArray[indexPath.row]
                (cell as? MailAddressCell)?.update(newModel: viewModel)
            }
        }
        return cell
    }

    func _tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        shawdowHeaderView.isHidden = true
        guard indexPath.row < viewModel.filteredArray.count else { tableView.isHidden = true; return }
        let cellViewModel = viewModel.filteredArray[indexPath.row]
        // 先把群组人数存起来
        if accountContext.featureManager.open(.massiveSendRemind, openInMailClient: false),
           self.recipientLimitEnable,
           cellViewModel.type == .group,
           let groupMemberCount = cellViewModel.chatGroupMembersCount {
            self.groupMemberCount[cellViewModel.larkID] = (groupMemberCount >= self.recipientLimit ? -1 : groupMemberCount)
        }
        // 将数据转为LKToken
        let token = LKToken()
        token.name = cellViewModel.name
        token.displayName = cellViewModel.displayName
        token.address = cellViewModel.address
        token.context = cellViewModel as AnyObject
        var addressArray: [MailAddressCellViewModel]?
        var addPosition: ContactAddPosition = .to

        // 发送
        if editionInputView == scrollContainer.toInputView {
            addressArray = viewModel.sendToArray
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.ccToArray, inputView: scrollContainer.ccInputView)
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.bccToArray, inputView: scrollContainer.bccInputView)
            addPosition = .to
        }
        // 抄送
        if editionInputView == scrollContainer.ccInputView {
            addressArray = viewModel.ccToArray
            addPosition = .cc
        }
        if editionInputView == scrollContainer.bccInputView {
            addressArray = viewModel.bccToArray
            addPosition = .bcc
        }
        if editionInputView == nil {
            addressArray = viewModel.atContactsToArray
            var count = 0
            if let existNumber = viewModel.tempAtContacts[cellViewModel.address] {
                count = existNumber
            }
            let flatArray = [viewModel.sendToArray, viewModel.ccToArray, viewModel.bccToArray].flatMap({ $0 })

            if !flatArray.contains(where: { $0.address == cellViewModel.address }) {
                viewModel.tempAtContacts.merge(other: [cellViewModel.address: count + 1])
            }
        }
        if var addressArray = addressArray {
            addressArray.append(cellViewModel)
            editionInputView?.addToken(token: token)
        }

        if editionInputView == nil {
            let toTokenAddresses = scrollContainer.toInputView.tokens.map({ ($0.context as? MailAddressCellViewModel)?.address ?? "" })
            let ccTokenAddresses = scrollContainer.ccInputView.tokens.map({ ($0.context as? MailAddressCellViewModel)?.address ?? "" })
            let bccTokenAddresses = scrollContainer.bccInputView.tokens.map({ ($0.context as? MailAddressCellViewModel)?.address ?? "" })
            let tokenAddresses = [toTokenAddresses, ccTokenAddresses, bccTokenAddresses].flatMap { ($0) }
            let notAdd = self.mentionFg() && !mentionAddAddressBtn.isSelected
            if  !notAdd && !tokenAddresses.contains(cellViewModel.address) {
                scrollContainer.toInputView.addToken(token: token)
                addPosition = .to
            }
            var param = ["address": cellViewModel.address, "username": cellViewModel.name, "userId": cellViewModel.larkID] as [String: Any]
            
            // core event
            let event = NewCoreEvent(event: .email_email_edit_click)
            event.params = ["target": "none",
                            "click": "at_confirm",
                            "as_mail_to": mentionAddAddressBtn.isSelected,
                            "mail_account_type": NewCoreEvent.accountType()]
            event.post()
            self.insertAtName(param: param)
        }
        tableView.isHidden = true
        if addressArray != nil {
            let mapBlock = { (model: MailAddressCellViewModel) -> [String: Any] in
                ["name": model.name,
                 "address": model.address,
                 "lark_entity_type": model.type?.rawValue ?? 1,
                 "lark_entity_id": Int64(cellViewModel.larkID) ?? 0,
                 "lark_entity_id_string": model.larkID]
            }
            let dataString = ["to": viewModel.sendToArray.map(mapBlock),
                              "cc": viewModel.ccToArray.map(mapBlock),
                              "bcc": viewModel.bccToArray.map(mapBlock),
                              "msg_biz_id": baseInfo.messageID ?? "",
                              "pre_mail_body": ""].toString() ?? ""

            let js = "window.smartComposeData = `\(dataString)`"
            evaluateJavaScript(js) { (res, error) in
                if let error = error {
                    mailAssertionFailure("\(error)")
                }
            }
        }
        if draft?.isSendSeparately == true {
            addPosition = .separately
        }
        self.dataProvider.trackAddMailContact(contactType: cellViewModel.type,
                                              contactTag: cellViewModel.tags?.first,
                                              addType: .contact_search,
                                              addPosition: addPosition)
        self.dataProvider.trackContactSearchFinish(type: .hit,
                                                   resultCount: viewModel.filteredArray.count,
                                                   selectRank: indexPath.row,
                                                   contactVM: cellViewModel,
                                                   fromAddress: draft?.content.from)
    }
    
    func insertAtName(param: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: param, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }
        requestEvaluateJavaScript("window.command.insertAtBlock(\(JSONString))") { [weak self] (_, _) in
            self?.deactiveContactlist()
        }
    }

    //  filter load more
    func _tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let text = editionInputView?.text, !text.isEmpty && text == self.dataProvider.searchKey {
            // 滑动到最后一页中间的位置，加载下一页
            if indexPath.row == (viewModel.filteredArray.count - Int(self.dataProvider.searchPageSize) / 2) &&
                self.dataProvider.searchBegin != Int32(viewModel.filteredArray.count) {
                self.dataProvider.searchBegin = Int32(viewModel.filteredArray.count)
                var groupEmailAccount: Email_Client_V1_GroupEmailAccount? = nil
                if self.draft?.content.from.type == .enterpriseMailGroup,
                   let fromLarkID = self.draft?.content.from.larkID,
                   let fromAddress = self.draft?.content.from.address {
                    groupEmailAccount = Email_Client_V1_GroupEmailAccount()
                    groupEmailAccount?.userID = Int64(fromLarkID) ?? 0
                    groupEmailAccount?.emailAddress = fromAddress
                }
                _ = self.dataProvider.recommandListWith(key: text,
                                                        begin: self.dataProvider.searchBegin,
                                                        end: self.dataProvider.searchBegin + self.dataProvider.searchPageSize,
                                                        groupEmailAccount: groupEmailAccount)
                    .observeOn(MainScheduler.instance).subscribe(
                    onNext: { [weak self] (list, _) in
                        guard let `self` = self else { return }
                        guard self.dataProvider.searchBegin == Int32(self.viewModel.filteredArray.count) else { return }
                        let array = list.compactMap { (model) -> MailAddressCellViewModel? in
                            guard !model.address.isEmpty || (model.larkID != nil && !model.larkID!.isEmpty && model.larkID! != "0" ) else {
                                return nil
                            }
                            let viewModel = MailAddressCellViewModel.make(from: model, currentTenantID: self.accountContext.user.tenantID)
                            return viewModel
                        }
                        guard !array.isEmpty else { return }
                        self.viewModel.filteredArray += array
                    },
                    onCompleted: { [weak self] in
                        guard let `self` = self else { return }
                        if self.viewModel.filteredArray.isEmpty {
                            self.editionInputView = nil
                        }
                        self.suggestTableView.separatorStyle = .singleLine
                        self.suggestTableView.reloadData()
                        self.suggestTableSelectionRow = 0
                    })
            }
        }
    }
}

// MARK: - LKTokenInputViewDelegate
extension MailSendController: LKTokenInputViewDelegate {
    /// 将 tokenInput 折叠起来
    func foldAllTokenInputViews() {
        scrollContainer.hideAllTokens()
    }

    private func handleTextDidChangeFromPasteIfNotOnlyOneAddress(aView: LKTokenInputView, addressesDidChangeText addresses: [MailAddressHelper.AddressItem]) -> Bool {
        if shouldIgnoreThisInput {
            var addressArray: [MailAddressCellViewModel]?
            var addPosition: ContactAddPosition = .to
            // 发送
            if aView == scrollContainer.toInputView {
                addressArray = viewModel.sendToArray
                addPosition = .to
            }
            // 抄送
            if aView == scrollContainer.ccInputView {
                addressArray = viewModel.ccToArray
                addPosition = .cc
            }
            if aView == scrollContainer.bccInputView {
                addressArray = viewModel.bccToArray
                addPosition = .bcc
            }
            if draft?.isSendSeparately == true {
                addPosition = .separately
            }
            var tmpSendTo = viewModel.sendToArray
            var obserables: [Observable<(MailSendAddressModel?, MailAddressHelper.AddressItem, ContactAddPosition)>] = []
            for item in addresses {
                let observable = dataProvider.addressInfoSearchAppend(address: item.address, item: item, addPosition: addPosition)
                obserables.append(observable)
            }
            addressInfoSearchAppend(obserables: obserables, aView: aView)
            return true
        }
        return false
    }
    func addressInfoSearchAppend(obserables: [Observable<(MailSendAddressModel?, MailAddressHelper.AddressItem, ContactAddPosition)>],
                                 aView: LKTokenInputView) {
        guard obserables.count > 0 else { return }
        Observable.concat(obserables)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (model) in
                    guard let `self` = self else { return }
                    if let info = model.0 {
                        var viewModel = MailAddressCellViewModel()
                        viewModel.address = info.address
                        viewModel.name = info.name
                        viewModel.type = info.type
                        viewModel.groupType = info.groupType
                        viewModel.displayName = info.displayName ?? ""
                        viewModel.currentTenantID = self.accountContext.user.tenantID
                        self.addAddressByString(aView: aView,
                                                addPosition: model.2,
                                                viewModel: viewModel)
                    } else {
                        var viewModel = MailAddressCellViewModel()
                        viewModel.address = model.1.address
                        viewModel.name = model.1.name
                        viewModel.currentTenantID = self.accountContext.user.tenantID
                        self.addAddressByString(aView: aView,
                                                addPosition: model.2,
                                                viewModel: viewModel)
                    }
                }).disposed(by: disposeBag)
        
    }
    private func addAddressByString(aView: LKTokenInputView,
                                    addPosition: ContactAddPosition,
                                    viewModel: MailAddressCellViewModel) {

        let token = LKToken()
        token.name = viewModel.name
        token.displayName = viewModel.displayName
        token.address = viewModel.address
        token.context = viewModel as AnyObject

        if scrollContainer.statusIsError(address: viewModel) {
            token.status = .error
        }
        token.context = viewModel as AnyObject
        // add token & model
        aView.addToken(token: token)
        aView.textField.text = nil
        // email_edit_click 埋点
        self.dataProvider.trackAddMailContact(contactType: viewModel.type,
                                              contactTag: viewModel.tags?.first,
                                              addType: .copy_mail_address,
                                              addPosition: addPosition)
    }

    func handleTextDidChange(aView: LKTokenInputView, didChangeText text: String?) {
        // 有可能是paste过来的已经识别了。
        guard !shouldIgnoreThisInput else {
            shouldIgnoreThisInput = false
            return
        }

        /// 三方开启 fg 后才支持搜索联系人
        guard !Store.settingData.mailClient || accountContext.featureManager.open(.clientSearchContact) else {
            return
        }

        var processedText = text
        // markedTextRange 是拼音输入提示的range，输入提示有额外的空格需要去除
        if let range = aView.textField.markedTextRange, let text = text {
            let textField = aView.textField
            let location = textField.offset(from: textField.beginningOfDocument, to: range.start)
            let length = textField.offset(from: range.start, to: range.end)
            let range = NSRange(location: location, length: length)
            processedText = processedText?.replacingOccurrences(of: "\\s", with: "", options: .regularExpression, range: .init(range, in: text))
        }

        if let text = processedText, !text.isEmpty {
            // let predicate: NSPredicate = NSPredicate(format: "self contains[cd] %@", argumentArray: [text])
            // 从联系人中过滤出命中的地址
            self.dataProvider.searchBegin = 0
            self.dataProvider.searchKey = text
            let event = MailAPMEvent.DraftContactSearch()
            event.markPostStart()
            let startTime = MailTracker.getCurrentTime()
            //每次文案变更，取消前一次请求
            self.searchBag = DisposeBag()

            var groupEmailAccount: Email_Client_V1_GroupEmailAccount? = nil
            if self.draft?.content.from.type == .enterpriseMailGroup,
               let fromLarkID = self.draft?.content.from.larkID,
               let fromAddress = self.draft?.content.from.address {
                groupEmailAccount = Email_Client_V1_GroupEmailAccount()
                groupEmailAccount?.userID = Int64(fromLarkID) ?? 0
                groupEmailAccount?.emailAddress = fromAddress
            }
            _ = self.dataProvider.recommandListWith(key: text, groupEmailAccount: groupEmailAccount).observeOn(MainScheduler.instance).subscribe(
                onNext: { [weak self] (list, isRemote) in
                    guard let `self` = self else { return }
                    self.handleSearchContactList(list, isRemote: isRemote)

                    event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                    self.dataProvider.trackDraftContactSearch(event: event)
                    self.dataProvider.trackContactSearchRequest(inputType: .keyboard_input, queryId: text.md5(),
                                                                startTime: startTime)
                    self.dataProvider.trachContactSearchResult(queryId: text.md5(),
                                                               resultTime: MailTracker.getCurrentTime(),
                                                               result: list)
                },
                onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                    event.endParams.appendError(error: error)
                    self.dataProvider.trackDraftContactSearch(event: event)
                }).disposed(by: self.searchBag)
            editionInputView = aView
            pushEditionInputView = aView
        } else {
            self.editionInputView = nil
            self.updateSuggestTableView(viewModel.filteredArray.count)
            viewModel.filteredArray = []
        }
    }

    func tokenInputView(aView: LKTokenInputView, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var handled = false
        if !string.isEmpty {
            let addresses = MailAddressHelper.createAddressesIfAvailable(str: string)
            if addresses.count > 1 || (addresses.count == 1 && addresses[0].address.isLegalForEmail() ) {
                let startTime = MailTracker.getCurrentTime()
                handled = handleTextDidChangeFromPasteIfNotOnlyOneAddress(aView: aView, addressesDidChangeText: addresses)
                self.dataProvider.trackContactSearchRequest(inputType: .copy_input, queryId: string.md5(), startTime: startTime)
            }
            if shouldIgnoreThisInput {
                shouldIgnoreThisInput = false
            }
        }
        if range.location == 0, range.length == 0 {
            // start
            self.dataProvider.searchSession.renewSession()
            MailLogger.debug("mail contact search start timestamp \(Int(self.dataProvider.searchSession.sessionTimeStamp() * 1000))")
        }
        return !handled
    }

    // 输入框文字改变
    func tokenInputView(aView: LKTokenInputView, didChangeText text: String?) {
        // 这里啥也不做。通过Rx去监听。为了方便利用rebounce方法！
    }

    // 添加一个 token
    func tokenInputView(aView: LKTokenInputView, didAddToken token: LKToken, isDragAction: Bool) {
        var address = MailAddressCellViewModel()
        address.currentTenantID = accountContext.user.tenantID
        if let context = token.context as? MailAddressCellViewModel {
            address = context
            if address.name.isEmpty {
                address.name = String(token.displayText.split(separator: "@").first ?? "")
            }
        } else {
            address.address = token.displayText
            if address.name.isEmpty {
                address.name = String(token.displayText.split(separator: "@").first ?? "")
            }
            token.context = address as AnyObject
        }
        if aView == scrollContainer.toInputView {
            viewModel.sendToArray.append(address)
        }
        if aView == scrollContainer.ccInputView {
            viewModel.ccToArray.append(address)
        }
        if aView == scrollContainer.bccInputView {
            viewModel.bccToArray.append(address)
        }
        if editionInputView == nil {
            self.viewModel.atContactsToArray.append(address)
        }
        checkRecipientCount()
        updateSendButtonEnable()
    }

    func removeAddressChange(index: Int, type: CollaOpType) {
        let param = ["type": type.rawValue,
                   "op": ["action": "remove", "value": index]] as [String: Any]
        guard let data = try? JSONSerialization.data(withJSONObject: param, options: []),
            let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json")
                return
        }
        requestEvaluateJavaScript("window.setCollaValue" + "(\(JSONString))") { (_, err) in
            if let err = err {
                mailAssertionFailure("err \(err)")
            }
        }
    }

    // 移除一个 token
    func tokenInputView(aView: LKTokenInputView, didRemoveToken token: LKToken, index: Int) {
        var address = MailAddressCellViewModel()
        address.currentTenantID = accountContext.user.tenantID
        address.name = String(token.displayText.split(separator: "@").first ?? "")
        if let context = token.context as? MailAddressCellViewModel {
            address.address = context.address
        } else {
            address.address = token.displayText
        }
        if aView == scrollContainer.toInputView {
            if viewModel.sendToArray.count > index && viewModel.sendToArray[index].address == address.address {
                self.viewModel.sendToArray.remove(at: index)
            } else {
                if let idx: Int = viewModel.sendToArray.firstIndex(where: { $0.address == address.address }) {
                    self.viewModel.sendToArray.remove(at: idx)
                }
            }
        }
        if aView == scrollContainer.ccInputView {
            if viewModel.ccToArray.count > index && viewModel.ccToArray[index].address == address.address {
                self.viewModel.ccToArray.remove(at: index)
            } else {
                if let idx: Int = viewModel.ccToArray.firstIndex(where: { $0.address == address.address }) {
                    self.viewModel.ccToArray.remove(at: idx)
                }
            }
        }
        if aView == scrollContainer.bccInputView {
            if viewModel.bccToArray.count > index && viewModel.bccToArray[index].address == address.address {
                self.viewModel.bccToArray.remove(at: index)
            } else {
                if let idx: Int = viewModel.bccToArray.firstIndex(where: { $0.address == address.address }) {
                    self.viewModel.bccToArray.remove(at: idx)
                }
            }
        }

        self.recipientOverLimit = false // 删除收件地址时需要重新置为false
        checkRecipientCount()
        updateSendButtonEnable()
    }

    // text 对应的 token
    func tokenInputView(aView: LKTokenInputView, tokenForText text: String?) -> LKToken? {
        editionInputView = aView
        if let text = text, !text.isEmpty {
            let token: LKToken = LKToken()
            /// 判断输入的email地址是否合法
            if !text.isLegalForEmail() {
                token.status = .error
            }
            token.address = text
            token.context = nil
            return token
        }
        return nil
    }

    func tokenInputViewDidEndEditing(aView: LKTokenInputView) {
        aView.placeholderText = nil
        editionInputView = nil
        pushEditionInputView = nil
        updateSuggestTableView(viewModel.filteredArray.count)
        viewModel.filteredArray = []
        unregisterTabKey(currentView: aView)
        unregisterLeftKey(currentView: aView)
        unregisterRightKey(currentView: aView)
    }

    func ifViewWillDisappear() -> Bool {
        return self.isViewWillDisAppear
    }
    
    func emailDomains() -> [String]? {
        self.accountContext.user.emailDomains
    }

    func tokenInputViewDidBeginEditing(aView: LKTokenInputView) {
        if !Store.settingData.mailClient {
            aView.placeholderText = BundleI18n.MailSDK.Mail_Edit_SearchPlaceholder
        }
        foldAllTokenInputViews()
        aView.showAllTokens = true
        editionInputView = nil
        viewModel.filteredArray = []
        updateSuggestTableView()
        firstResponder = aView
        //每一次选中InputView时都要需求选中所有的TokenInputView
        scrollContainer.toInputView.unselectAllTokenViewsAnimated(animated: true)
        scrollContainer.ccInputView.unselectAllTokenViewsAnimated(animated: true)
        scrollContainer.bccInputView.unselectAllTokenViewsAnimated(animated: true)
        registerTabKey(currentView: aView)
        registerLeftKey(currentView: aView)
        registerRightKey(currentView: aView)
    }

    func tokenInputView(aView: LKTokenInputView, didChangeHeightTo height: CGFloat) {
        UIView.animate(withDuration: timeIntvl.ultraShort) {
            self.view.layoutIfNeeded()
        }
    }

    func tokenInputViewShouldReturn(aView: LKTokenInputView) {
        focusNextInputView(currentView: aView)
    }

    func oldTokenInputView(aView: LKTokenInputView, needShowTipAt tokenView: LKTokenView) {
        if let addressModel = tokenView.token.context as? MailAddressCellViewModel {
            if addressModel.type == .group {
                // 邮件组就可以展示地址
                let text = BundleI18n.MailSDK.Mail_Compose_GroupAddressTip
                let tip = TipViewController(text: text, forView: tokenView, navigator: accountContext.navigator)
                tip.show(fromVC: self)
            } else if addressModel.type == .enterpriseMailGroup {
                let text = addressModel.address
                let tip = TipViewController(text: text, forView: tokenView, navigator: accountContext.navigator)
                tip.show(fromVC: self)
            } else if !addressModel.address.isEmpty, addressModel.address.isLegalForEmail() {
                let userid = addressModel.larkID
                if !userid.isEmpty && userid != "0" {
                    accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
                } else {
                    let tip = TipViewController(text: addressModel.address, forView: tokenView, navigator: accountContext.navigator)
                    tip.show(fromVC: self)
                }
            }
        }
    }

    func tokenInputView(aView: LKTokenInputView, needShowTipAt tokenView: LKTokenView) {
        // 错误地址不呼起联系人卡片
        guard accountContext.featureManager.open(.contactCards) && tokenView.token.status != .error else {
            oldTokenInputView(aView: aView, needShowTipAt: tokenView)
            return
        }

        if let addressModel = tokenView.token.context as? MailAddressCellViewModel {
            let type = addressModel.type ?? .chatter
            let userid = addressModel.larkID
            let tenantId = addressModel.tenantId
            let name = addressModel.mailDisplayName
            let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
            MailContactLogic.default.checkContactDetailAction(userId: userid,
                                                              tenantId: tenantId,
                                                              currentTenantID: accountContext.user.tenantID,
                                                              userType: type) { [weak self] result in
                guard let self = self else { return }
                if result == .nameCard {
                    self.accountContext.profileRouter.openNameCard(accountId: accountId, address: addressModel.address, name: name, fromVC: self)
                } else if result == .profile && addressModel.address.isLegalForEmail() {
                    if !userid.isEmpty && userid != "0" {
                        self.accountContext.profileRouter.openUserProfile(userId: userid, fromVC: self)
                    } else {
                        let tip = TipViewController(text: addressModel.address, forView: tokenView, navigator: self.accountContext.navigator)
                        tip.show(fromVC: self)
                    }
                } else {
                    var text = addressModel.address
                    if addressModel.type == .group {
                        // 邮件组就可以展示地址
                        text = BundleI18n.MailSDK.Mail_Compose_GroupAddressTip
                    }

                    let tip = TipViewController(text: text, forView: tokenView, navigator: self.accountContext.navigator)
                    tip.show(fromVC: self)
                }
            }
        }
    }

    func tokenInputView(aView: LKTokenInputView) {
        shouldIgnoreThisInput = true
    }

    func tokenInputView(aView: LKTokenInputView, didStartDragDrop tokenView: LKTokenView) {
        if let draft = draft, draft.isSendSeparately {
            // nothing，分别发送不能移动到cc和bcc
        } else {
            scrollContainer.isCCandBCCNeedShow = true
        }
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    func tokenInputView(aView: LKTokenInputView, didDrag tokenView: LKTokenView, focusAt target: LKTokenInputView) {
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    func tokenInputView(aView: LKTokenInputView, didDrag tokenView: LKTokenView, dropTo target: LKTokenInputView) {
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()
    }

    func tokenInputView(aView: LKTokenInputView, didEndDragDrop tokenView: LKTokenView) {

    }
    
    func tokenInputView(aView: LKTokenInputView, didSelected tokenView: LKTokenView) {
        registerLeftKey(currentView: aView)
        registerRightKey(currentView: aView)
    }
    
    func tokenInputView(unresignLeftKeymand aView: LKTokenInputView) {
        unregisterLeftKey(currentView: aView)
    }
    
    func tokenInputView(unresignRightKeymand aView: LKTokenInputView) {
        unregisterRightKey(currentView: aView)
    }
    
    func tokenInputView(resignLeftKeymand aView: LKTokenInputView) {
        registerLeftKey(currentView: aView)
    }
    
    func tokenInputView(resignRightKeymand aView: LKTokenInputView) {
        registerRightKey(currentView: aView)
    }
    
    func selectPreToken(currentView: UIView)  {
        var findCurrentView = false
        for view in scrollContainer.contentView.arrangedSubviews {
            if view == currentView {
                findCurrentView = true
                view.resignFirstResponder()
            }
            if findCurrentView, !view.isHidden {
                if view is LKTokenInputView {
                    (view as? LKTokenInputView)?.selectPreToken()
                    return
                }
            }
        }
    }
    
    func selectNextToken(currentView: UIView) {
        var findCurrentView = false
        for view in scrollContainer.contentView.arrangedSubviews {
            if view == currentView {
                findCurrentView = true
                view.resignFirstResponder()
            }
            if findCurrentView, !view.isHidden {
                if view is LKTokenInputView {
                    (view as? LKTokenInputView)?.selectNextToken()
                    return
                }
            }
        }
    }
    func subjectViewChangeText() {
        self.emlFilledSubject = true
    }

    func focusNextInputView(currentView: UIView) {
        var findCurrentView = false
        for view in scrollContainer.contentView.arrangedSubviews {
            if view == currentView {
                findCurrentView = true
                view.resignFirstResponder()
                continue
            }
            if findCurrentView, !view.isHidden {
                if view is LKTokenInputView {
                    (view as? LKTokenInputView)?.beginEditing()
                    return
                } else if view == self.scrollContainer.subjectCoverInputView {
                    if let inputView = (view as? MailSubjectFieldView) {
                        inputView.textView.isEditable = true
                        inputView.becomeFirstResponder()
                        self.registerTabKey(currentView: view)
                        return
                    }
                } else if view is MailCoverDisplayView {
                    if let coverView = (view as? MailCoverDisplayView) {
                        coverView.becomeFirstResponder()
                        self.registerTabKey(currentView: view)
                        return
                    }
                } else if view is MailSendWebView {
                    _ = (view as? MailSendWebView)?.becomeFirstResponder()
                    (view as? MailSendWebView)?.focusAtEditorBegin()
                    self.selectionPosition = EditorSelectionPosition(top: 0, left: 0, height: 0)
                    self.unregisterTabKey(currentView: view)
                    self.unregisterLeftKey(currentView: view)
                    self.unregisterRightKey(currentView: view)
                    return
                }
            }
        }
    }

    /// obser
    func tokenInputView(aView: LKTokenInputView, searchTextAddressInfo address: String) -> Observable<Bool> {
        return dataProvider.addressInfoSearch(address: address).map { [weak self] model in
            if let info = model {
                self?.handleProfileInfo(info: info)
                return true
            } else {
                return false
            }
        }
    }

    private func handleProfileInfo(info model: MailSendAddressModel) {
        let cellViewModel = MailAddressCellViewModel.make(from: model, currentTenantID: accountContext.user.tenantID)
        let token = LKToken()
        token.name = cellViewModel.name
        token.displayName = cellViewModel.displayName
        token.address = cellViewModel.address
        token.context = cellViewModel as AnyObject

        var addressArray: [MailAddressCellViewModel]?
        var type = 0; // 后面找机会重构这里代码太蠢

        // 发送
        if editionInputView == scrollContainer.toInputView {
            addressArray = viewModel.sendToArray
            type = 0
        }
        // 抄送
        if editionInputView == scrollContainer.ccInputView {
            addressArray = viewModel.ccToArray
            type = 1
        }
        if editionInputView == scrollContainer.bccInputView {
            addressArray = viewModel.bccToArray
            type = 2
        }
        if var addressArray = addressArray, !addressArray.contains(where: {
            if cellViewModel.address.isEmpty {
                return false
            } else {
                return $0.address == cellViewModel.address
            }
        }) {
            addressArray.append(cellViewModel)
            editionInputView?.addToken(token: token)
        }
        // update other views & array
        if type == 0 {
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.ccToArray, inputView: scrollContainer.ccInputView)
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.bccToArray, inputView: scrollContainer.bccInputView)
        } else if type == 1 {
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.sendToArray, inputView: scrollContainer.toInputView)
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.bccToArray, inputView: scrollContainer.bccInputView)
        } else if type == 2 {
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.sendToArray, inputView: scrollContainer.toInputView)
            updateCellViewModel(viewModel: cellViewModel, dataArray: &self.viewModel.ccToArray, inputView: scrollContainer.ccInputView)
        }
    }

    func updateCellViewModel(viewModel updateModel: MailAddressCellViewModel,
                                     dataArray: inout [MailAddressCellViewModel],
                                     inputView: LKTokenInputView) {
        var viewModel = updateModel
        // 更新数据
        var target = -1
        for (index, temp) in dataArray.enumerated() {
            if temp.address.lowercased() == viewModel.address.lowercased() {
                viewModel.isSelected = temp.isSelected
                target = index
                break
            }
        }
        if target > 0 {
            dataArray.remove(at: target)
            dataArray.append(viewModel)
        }
        // 更新token
        for token in inputView.allTokens() {
            if let temp = token.context as? MailAddressCellViewModel,
               temp.address.lowercased() == viewModel.address.lowercased() {
                token.name = viewModel.name
                token.displayName = viewModel.displayName
                token.address = viewModel.address
                token.context = viewModel as AnyObject
                // 找到对应的tokenView
                for view in inputView.tokenViews {
                    if view.token.address.lowercased() == token.address.lowercased() {
                        view.token = token
                        view.updateStatus()
                        view.frame = CGRect(x: 0.0, y: 0, width: 50, height: 50)
                        inputView.repositionViews()
                        break
                    }
                }
                break
            }
        }
    }

    func listenSearchContactPush() {
        guard !Store.settingData.mailClient || accountContext.featureManager.open(.clientSearchContact) else {
            return
        }

        PushDispatcher.shared.$searchContactChange
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] change in
                guard let self = self,
                      let value = change.element,
                      value.info.searchSession == self.dataProvider.searchSession.session,
                      self.pushEditionInputView != nil,
                      let dataSource = self.dataProvider as? MailSendDataSource
                else { return }
                let list = dataSource.transformSearchResult(value.result)
                dataSource.updateSearchInfo(value.info)
                self.editionInputView = self.pushEditionInputView
                self.handleSearchContactList(list, isRemote: true)
                self.pushEditionInputView = nil
            }).disposed(by: disposeBag)
    }

    private func handleSearchContactList(_ list: [MailSendAddressModel], isRemote: Bool) {
        viewModel.filteredArray = list.compactMap({ (model) -> MailAddressCellViewModel? in
            guard !model.address.isEmpty || (model.larkID != nil && !model.larkID!.isEmpty && model.larkID! != "0") else {
                return nil
            }
            let viewModel = MailAddressCellViewModel.make(from: model, currentTenantID: accountContext.user.tenantID)
            return viewModel
        })
        if viewModel.filteredArray.isEmpty {
            self.editionInputView = nil
        } else if let inputView = editionInputView {
            let y = inputView.screenFrame.maxY
            let maxY: CGFloat = 240
            if y > maxY {
                let delta = y - maxY
                let currentOffsetY = scrollContainer.contentOffset.y
                scrollContainer.setContentOffset(CGPoint(x: 0, y: currentOffsetY + delta), animated: false)
            }
        }
        if !isRemote {
            // 后台没有返回数据，清空
            editionInputView = nil
        }
        updateSuggestTableView()
        suggestTableView.separatorStyle = .singleLine
        suggestTableView.reloadData()
        suggestTableSelectionRow = 0
    }
}

// MARK: - Cover
extension MailSendController: CoverSelectPanelDelegate, MailCoverDisplayViewDelegate {
    func isTitleHighlighted() -> Bool {
        return false
    }
    
    func bindCoverPickerViewModelIfNeeded() {
        guard accountContext.featureManager.open(.editMailCover, openInMailClient: false) else { return }
        coverPickerVM.output.initialDataFailed
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.scrollContainer.coverStateSubject.onNext(.loadFailed)
            }).disposed(by: disposeBag)
    }

    func showCoverPicker() {
        officialCoverListProvider.loadDataScene = .coverLoadScene(.select)
        scrollContainer.coverVM.loadDataScene = .coverLoadScene(.select)
        let vc = CoverSelectPanelViewController(viewModel: coverPickerVM)
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle =  Display.pad ? .formSheet : .overFullScreen
        navigator?.present(nav, from: self)
    }

    /// 点击添加封面，自动选择官方封面图
    func triggerAddCover() {
        guard checkNetworkAndShowToastIfNone() else { return }
        // 延迟显示，减少显示灰底频率
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
            guard let self = self, let state = try? self.scrollContainer.coverStateSubject.value() else { return }
            switch state {
            case .none:
                self.scrollContainer.coverStateSubject.onNext(.loading(nil))
            case .loadFailed:
                self.scrollContainer.coverStateSubject.onNext(.none)
            default:
                break
            }
        }
        officialCoverListProvider.loadDataScene = .coverLoadScene(.add)
        scrollContainer.coverVM.loadDataScene = .coverLoadScene(.add)
        coverPickerVM.randomSelectPublicCoverPhoto()
    }

    func didTapEditCover(from view: UIView) {
        guard checkNetworkAndShowToastIfNone() else { return }
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)
        
        if rootSizeClassIsSystemRegular {
            showEditPopOver(sourceView: view)
        } else {
            showEditActionSheet()
        }
    }

    func didTapRandomCover() {
        guard checkNetworkAndShowToastIfNone() else { return }
        let photoSeries = coverPickerVM.officialSeries
        scrollContainer.coverVM.loadDataScene = .coverLoadScene(.random)
        if var photoSeries = photoSeries, let selectedCoverToken = draft?.content.subjectCover?.token {
            outerLoop:
            for i in 0..<photoSeries.count {
                for j in 0..<photoSeries[i].infos.count {
                    if photoSeries[i].infos[j].token == selectedCoverToken {
                        photoSeries[i].infos.remove(at: j)
                        break outerLoop
                    }
                }
            }
            coverPickerVM.input.randomSelectOfficialCoverPhoto.onNext(photoSeries)
        } else {
            if photoSeries?.isEmpty == false {
                coverPickerVM.input.randomSelectOfficialCoverPhoto.onNext(photoSeries)
            } else {
                coverPickerVM.randomSelectPublicCoverPhoto()
            }
        }
    }

    func didTapReloadCover(_ cover: MailSubjectCover?) {
        scrollContainer.coverVM.loadDataScene = .coverLoadScene(.customReload)

        if let cover = cover {
            scrollContainer.coverStateSubject.onNext(.loading(cover))
        } else {
            scrollContainer.coverStateSubject.onNext(.loading(nil))
            coverPickerVM.randomSelectPublicCoverPhoto()
        }
    }

    func didFailToSelectCover() {
        scrollContainer.coverStateSubject.onNext(.loadFailed)
    }

    func didRemoveSelectedCover() {
        guard checkNetworkAndShowToastIfNone() else { return }
        draft?.content.subjectCover = nil
        scrollContainer.coverStateSubject.onNext(.none)
    }

    func didSelectLocalCover(info: CoverPickImagePreInfo, source: CoverPhotoSource) {

    }

    func didSelectOfficialCover(info: OfficialCoverPhotoInfo, source: CoverPhotoSource) {
        guard checkNetworkAndShowToastIfNone() else { return }
        let mailCover = info.asMailCover
        scrollContainer.coverStateSubject.onNext(.loading(mailCover))
        draft?.content.subjectCover = mailCover
    }

    private func checkNetworkAndShowToastIfNone() -> Bool {
        if let connection = connection {
            if connection == .none {
                UDToast().showFailure(with: BundleI18n.MailSDK.Mail_Cover_MobileUnableEditTryAgain, on: view)
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }

    private func showEditActionSheet() {
        let source = UDActionSheetSource(sourceView: view, sourceRect: view.bounds, arrowDirection: .up)
        let sheet = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: false, popSource: source))
        sheet.addDefaultItem(text: BundleI18n.MailSDK.Mail_Cover_MobileSelectCover) { [weak self] in
            self?.showCoverPicker()
        }
        sheet.addDestructiveItem(text: BundleI18n.MailSDK.Mail_Cover_MobileRemoveCover) { [weak self] in
            self?.didRemoveSelectedCover()
        }
        sheet.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        navigator?.present(sheet, from: self)
    }

    private func showEditPopOver(sourceView: UIView) {
        // ux说看到键盘很不开心
        var popArray: [PopupMenuActionItem] = []
        let selectCover = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_Cover_MobileSelectCover, icon: UDIcon.imageOutlined) { [weak self] (_, _) in
            self?.showCoverPicker()
        }
        popArray.append(selectCover)
        let removeCover = PopupMenuActionItem(title: BundleI18n.MailSDK.Mail_Cover_MobileRemoveCover, icon: UDIcon.deleteTrashOutlined) { [weak self] (_, _) in
            self?.didRemoveSelectedCover()
        }

        var direction: UIPopoverArrowDirection = .up
        if Display.pad,
           keyBoard.options?.event == .didShow,
           let endFrame = keyBoard.options?.endFrame,
           let sourceFrame = sourceView.superview?.convert(sourceView.frame, to: nil),
           (UIScreen.main.bounds.height - endFrame.origin.y - sourceFrame.bottom) < 130 {
            direction = .down
        }

        popArray.append(removeCover)
        let vc = PopupMenuPoverViewController(items: popArray)
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        vc.popoverPresentationController?.sourceRect = CGRect(x: sourceView.bounds.origin.x,
                                                              y: sourceView.bounds.origin.y + (direction == .up ? 4 : -4),
                                                              width: sourceView.bounds.width,
                                                              height: sourceView.bounds.height)
        vc.popoverPresentationController?.sourceView = sourceView
        vc.popoverPresentationController?.permittedArrowDirections = direction
        navigator?.present(vc, from: self)
    }
}

// MARK: - Cover Guide
extension MailSendController: GuideSingleBubbleDelegate {
    func showMailCoverGuideIfNeeded() {
        guard accountContext.featureManager.open(FeatureKey(fgKey: .editMailCover, openInMailClient: false)) else { return }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(self.scrollContainer.coverEntryButton))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Cover_MobileCoverOnboarding,
                                        detail: BundleI18n.MailSDK.Mail_Cover_MobileCoverOnboardingDesc())
        let leftButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_Cover_MobileLearnMore, buttonType: .skip)
        let rightButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_Cover_MobileGotIt, buttonType: .finished)
        let bottomConfig = BottomConfig(leftBtnInfo: leftButtonInfo, rightBtnInfo: rightButtonInfo, leftText: nil)
        let bubbleConfig = SingleBubbleConfig(delegate: self,
                                              bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor,
                                                                             textConfig: textConfig,
                                                                             bottomConfig: bottomConfig),
                                              maskConfig: MaskConfig(shadowAlpha: 0.0, windowBackgroundColor: .clear, maskInteractionForceOpen: true))
        let guideKey = "all_mail_cover"
        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig)) { [weak self] in
            self?.accountContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
    }

    func didClickLeftButton(bubbleView: GuideBubbleView) {
        // open url
        accountContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
        guard let link = ProviderManager.default.commonSettingProvider?.stringValue(key: "mail-cover")?.localLink,
              let url = URL(string: link) else { return }
        navigator?.push(url, from: self)
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        accountContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
    }

    func didTapBubbleView(bubbleView: GuideBubbleView) {

    }
}

extension MailSendController {
    func showContactPicker(tokenView: LKTokenInputView) {
        guard let provider = accountContext.provider.contactPickerProvider else {
            return
        }

        let params = MailContactPickerParams()
        params.pickerDepartmentFG = accountContext.featureManager.open(.pickerDepartment, openInMailClient: false)
        if params.pickerDepartmentFG {
            params.selectedCallbackWithNoEmail = { [weak self] (items, noEmailChatters) in
                guard let self = self else {
                    return
                }
                self.handleContactPickRes(tokenView: tokenView, items: items)
                self.handleNoEmailContact(noEmailList: noEmailChatters)
                asyncRunInMainThread {
                    UDToast.removeToast(on: self.view)
                }
            }
        } else {
            params.selectedCallback = { [weak self] (items) in
                guard let self = self else {
                    return
                }
                self.handleContactPickRes(tokenView: tokenView, items: items)
            }
        }
        params.loadingText = BundleI18n.MailSDK.Mail_Toast_Loading
        // 产品沟通后去掉这个逻辑
//        let defaultSelected = tokenView.tokens.map { token in
//            return token.address
//        }
//        params.defaultSelectedMails = defaultSelected
        let allCount = viewModel.sendToArray.count + viewModel.ccToArray.count + viewModel.bccToArray.count
        params.mailAccount = Store.settingData.getCachedCurrentAccount()
        params.maxSelectCount = max(0, contentChecker.recipientsLimit - allCount)
        provider.presentMailContactPicker(params: params, vc: self)

        // 埋点
        let event = NewCoreEvent(event: .email_select_contact_from_picker_click)
        event.params["target"] = "email_select_contact_from_picker_view"
        event.params["click"] = "add_picker"
        if draft?.isSendSeparately == true {
            event.params["contact_position"] = "separately"
        } else {
            if tokenView == scrollContainer.toInputView {
                event.params["contact_position"] = "to"
            }
            // 抄送
            if tokenView == scrollContainer.ccInputView {
                event.params["contact_position"] = "cc"
            }
            if tokenView == scrollContainer.bccInputView {
                event.params["contact_position"] = "bcc"
            }
        }
        event.post()
    }

    private func handleContactPickRes(tokenView: LKTokenInputView, items: [MailContactPickerResItem]) {
        var addressArray: [MailAddressCellViewModel]?
        var addPosition: ContactAddPosition = .to
        // 埋点
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params["target"] = "none"
        event.params["click"] = "add_confirm"

        if draft?.isSendSeparately == true {
            event.params["contact_position"] = "separately"
            addressArray = viewModel.sendToArray
            addPosition = .separately
        } else {
            // 发送
            if tokenView == scrollContainer.toInputView {
                event.params["contact_position"] = "to"
                addressArray = viewModel.sendToArray
                addPosition = .to
            }
            // 抄送
            if tokenView == scrollContainer.ccInputView {
                event.params["contact_position"] = "cc"
                addressArray = viewModel.ccToArray
                addPosition = .cc
            }
            if tokenView == scrollContainer.bccInputView {
                event.params["contact_position"] = "bcc"
                addressArray = viewModel.bccToArray
                addPosition = .bcc
            }
        }
        var chatterCount = 0
        var namecardCount = 0
        var chatGroupCount = 0
        var mailGroupCount = 0
        var sharedCount = 0
        var externalCount = 0
        var noneTypeCount = 0

        for item in items {
            var type: ContactType = .chatter
            switch item.type {
            case .chatter:
                type = .chatter
                chatterCount += 1
            case .external:
                type = .externalContact
                externalCount += 1
            case .nameCard:
                type = .nameCard
                namecardCount += 1
            case .group:
                type = .group
                chatGroupCount += 1
            case .mailGroup:
                type = .enterpriseMailGroup
                mailGroupCount += 1
            case .sharedMailbox:
                type = .sharedMailbox
                sharedCount += 1
            case .unknown:
                type = .unknown
                noneTypeCount += 1
            }
            let displayName = item.type == .nameCard ? item.displayName : ""
            let name = item.type == .nameCard ? "" : item.displayName
            let cellViewModel = MailAddressCellViewModel(name: name,
                                                         address: item.email,
                                                         avatar: "",
                                                         isSelected: false,
                                                         avatarKey: item.avatarKey,
                                                         type: type,
                                                         larkID: item.entityId,
                                                         tenantId: item.tenantId ?? "",
                                                         displayName: displayName,
                                                         currentTenantID: accountContext.user.tenantID)
            let token = LKToken()
            token.name = cellViewModel.name
            token.displayName = cellViewModel.displayName
            token.address = cellViewModel.address
            token.context = cellViewModel as AnyObject

            if var addressArray = addressArray {
                addressArray.append(cellViewModel)
                tokenView.addToken(token: token)
                // email_edit_click 埋点
                self.dataProvider.trackAddMailContact(contactType: cellViewModel.type,
                                                      contactTag: cellViewModel.tags?.first,
                                                      addType: .picker,
                                                      addPosition: addPosition)
            }
        }
        tokenView.beginEditing()

        event.params["inner_contact"] = chatterCount
        event.params["mail_contact"] = namecardCount
        event.params["chat_group"] = chatGroupCount
        event.params["mail_group"] = mailGroupCount
        event.params["public_mail_address"] = sharedCount
        event.params["outer_mail_address"] = externalCount
        event.params["none_type_contact"] = noneTypeCount
        event.post()
    }

    private func handleNoEmailContact(noEmailList: [MailContactPickerResItem]) {
        let alertController = LarkAlertController()
        let noEmailCount = noEmailList.count
        guard noEmailCount > 0 else { return }
        alertController.setContent(text: BundleI18n.MailSDK.Mail_ContactPicker_ContactsPartiallyAdded_Desc(noEmailCount))
        alertController.setTitle(text: BundleI18n.MailSDK.Mail_ContactPicker_ContactsPartiallyAdded_Title)
        alertController.addSecondaryButton(text: BundleI18n.MailSDK.Mail_ContactPicker_ContactsPartiallyAdded_ViewDetails_Bttn, dismissCompletion: {
            self.presentNoEmailUsers(noEmailList: noEmailList)
        })
        alertController.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ContactPicker_ContactsPartiallyAdded_GotIt_Bttn)
        self.navigator?.present(alertController, from: self)
    }

    private func presentNoEmailUsers(noEmailList: [MailContactPickerResItem]) {
        let pickerDetailVC = MailSendPickerDetailController(pickerItems: noEmailList)
        self.navigator?.push(pickerDetailVC, from: self)
    }
}

// MARK: - UITextFieldDelegate
extension MailSendController {
    func _textFieldDidBeginEditing(_ textField: UITextField) {
        foldAllTokenInputViews()
        firstResponder = textField
        let attrItem = EditorToolBarItemInfo(identifier: EditorToolBarButtonIdentifier.attr.rawValue)
        attrItem.isEnable = false
        mainToolBar?.updateItemStatus(newItem: attrItem)
    }

    func _textFieldShouldReturn(_ textField: UITextField) -> Bool {
        focusNextInputView(currentView: scrollContainer.subjectCoverInputView)
        return false
    }
}

extension MailSendController: AliasListDelegate {
    func showAliasEditPage() {
        guard let account = self.accountContext.mailAccount else { return }

        let isMailClient = Store.settingData.mailClient

        if isMailClient && account.mailSetting.userType == .tripartiteClient && account.protocol != .exchange {
            guard let setting = Store.settingData.getCachedCurrentSetting() else { return }
            let currentAddress = MailAddress(with: setting.emailAlias.defaultAddress)
            let titleText = BundleI18n.MailSDK.Mail_ThirdClient_AccountNameMobile
            let viewModel = MailSettingViewModel(accountContext: accountContext)
            let senderAliasSettingController = MailSenderAliasController(viewModel: viewModel, 
                                                                         accountId: accountContext.accountID,
                                                                         accountContext: accountContext,
                                                                         titleText: titleText,
                                                                         currentAddress: currentAddress)
            senderAliasSettingController.delegate = self
            let nav = LkNavigationController(rootViewController: senderAliasSettingController)
            nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            navigator?.present(nav, from: self)
        } else if account.mailSetting.userType != .tripartiteClient {
            let aliasSettingController = MailSettingWrapper.getAliasSettingController(accountContext: accountContext)
            let nav = LkNavigationController(rootViewController: aliasSettingController)
            nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            navigator?.present(nav, from: self)
        }

    }

    func selectedAlias(address: Email_Client_V1_Address) {
        var nickName = address.mailDisplayNameNoMe
        if let setting = Store.settingData.getCachedCurrentSetting(),
           Store.settingData.mailClient {
            nickName = setting.emailAlias.defaultAddress.name
        }
        scrollContainer.fromInputView.resetAddress(nickName: nickName, addressName: address.address)
        var type = ContactType.chatter
        switch address.larkEntityType {
        case .user:
            type = .chatter
        case .group:
            type = .group
        case .enterpriseMailGroup:
            type = .enterpriseMailGroup
        case .unknown:
            type = .unknown
        case .sharedMailbox:
            type = .sharedMailbox
        @unknown default:
            break
        }
        draft?.content.from = MailAddress(name: address.name,
                                          address: address.address,
                                          larkID: address.larkEntityIDString,
                                          tenantId: address.tenantID,
                                          displayName: address.displayName,
                                          type: type)
        MailTracker.log(event: "email_alias_edit_name", params: [:])
        MailTracker.addressLog()
        // 切换了alias，查看是否需要切换签名
        self.scrollContainer.webView.sigId = nil
        if accountContext.featureManager.realTimeOpen(.enterpriseSignature), let sigData = Store.settingData.getCachedCurrentSigData() {
            if let dic = self.genSignatureDicByAddres(sigData: sigData,
                                                      address: address) {
                self.pluginRender?.resetSignature(address: address.address, dic: dic)
            } else {
                var dic: [String: Any] = [:]
                dic["list"] = []
                self.pluginRender?.resetSignature(address: address.address, dic: dic)
            }

        }
    }

    func cancel() {
        scrollContainer.fromInputView.cancel()
    }
}

extension MailSendController: MailAddressCellDelegate {
    func deleteExternAddress(_ model: MailAddressCellViewModel) {
        let event = NewCoreEvent(event: .email_search_contact_result_click)
        event.params = ["click": "delete_search_record"]
        event.post()
        guard !model.address.isEmpty else {
            MailLogger.error("delete extern address is empty")
            return
        }
        // 乐观删除filterArray中的address
        self.viewModel.filteredArray = self.viewModel.filteredArray.filter({ $0 != model })
        if self.viewModel.filteredArray.isEmpty {
            suggestTableView.isHidden = true
        } else {
            suggestTableView.isHidden = false
            suggestTableView.reloadData()
            self.suggestTableSelectionRow = 0
        }

        if accountContext.featureManager.open(.clientSearchContact) {
            MailDataServiceFactory.commonDataService?.mailDeleteExternContact(address: model.address).subscribe( onNext: { _ in
                MailLogger.info("deleteExternAddress success")
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("resp error \(error)")
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Search_FailedToDeleteRetry, on: self.view)
                InteractiveErrorRecorder.recordError(event: .delete_search_address_error)
            }).disposed(by: disposeBag)
        } else {
            MailDataServiceFactory.commonDataService?.mailDeleteExternAddress(address: model.address).subscribe( onNext: { _ in
                MailLogger.info("deleteExternAddress success")
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("resp error \(error)")
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Search_FailedToDeleteRetry, on: self.view)
                InteractiveErrorRecorder.recordError(event: .delete_search_address_error)
            }).disposed(by: disposeBag)
        }
    }
}

extension MailSendController: MailSenderAliasDelegate {
    func didUpdateAliasAndDismiss(address: MailAddress) {
        let clientAddress = address.toPBModel()
        var nickName = clientAddress.mailDisplayNameNoMe
        if let setting = Store.settingData.getCachedCurrentSetting(),
           Store.settingData.mailClient {
            nickName = setting.emailAlias.defaultAddress.name
        }
        scrollContainer.fromInputView.resetAddress(nickName: nickName, addressName: address.address)
        draft?.content.from = address
        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThirdClient_AccountNameUpdated, on: self.view)
    }

    func shouldShowAliasLimit() -> Bool {
        return true
    }

}
