//
//  MailSearchHistoryView.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/7.
//

import Foundation
import RxSwift
import LarkAlertController
import EENavigator

protocol MailSearchHistoryViewDelegate: AnyObject {
    func historyView(_ historyView: MailSearchHistoryView, didSelect historyInfo: MailSearchHistoryInfo)
    func clearHistoryInfo()
    func historyViewDidClickBackground(_ historyView: MailSearchHistoryView)
    func showAlert(alert: LarkAlertController)
}

class MailSearchHistoryView: UIView {
    struct HistoryItem: MailSearchHistoryInfo {
        let keyword: String
    }

    weak var delegate: MailSearchHistoryViewDelegate?
    let dataCenter: MailSearchHistoryDataCenter = MailSearchHistoryDataCenter()
    let bottomView = MailSearchQueryBottomView()

    private let disposeBag = DisposeBag()

    // MARK: Life Circle
    init() {
        super.init(frame: CGRect.zero)
        configUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configUI() {
        backgroundColor = UIColor.ud.bgBody

        bottomView.delegate = self
        addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension MailSearchHistoryView: MailSearchQueryBottomViewDelegate {
    func bottomViewDidClickClearHistory(_ bottomView: MailSearchQueryBottomView) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_Alert_ClearSearchHistory, alignment: .center)
//        alert.addCancelButton() // 目前iphone所有文案都是ENG。所以用ENG的不用默认的国际化文案
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_AdvancedSearch_Deletehistory) { [weak self] in
            self?.delegate?.clearHistoryInfo()
        }
        delegate?.showAlert(alert: alert)
    }

    func bottomView(_ bottomView: MailSearchQueryBottomView, didSelect historyInfo: MailSearchHistoryInfo) {
        delegate?.historyView(self, didSelect: historyInfo)
    }
}
