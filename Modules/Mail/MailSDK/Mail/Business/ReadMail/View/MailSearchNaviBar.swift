//
//  MailSearchNaviBar.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/5/7.
//

import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignLoading
import UniverseDesignColor

final class MailSearchNaviBar: UIView {
    private let searchNavBar = SearchNaviBar(style: .search)
    private let rightView = UIView()
    private let searchCountLabel = UILabel()
    private let loadingView: UDSpin
    private var loadingTimer: Timer?

    var cancelButton: UIButton {
        return searchNavBar.searchbar.cancelButton
    }

    var searchTextField: UITextField {
        return searchNavBar.searchbar.searchTextField
    }

    override init(frame: CGRect) {
        let spinConfig = UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 16, color: UDColor.primaryContentDefault),
                                      textLabelConfig: nil)
        loadingView = UDLoading.spin(config: spinConfig)
        super.init(frame: frame)
        searchNavBar.backgroundColor = UIColor.ud.bgBody
        backgroundColor = UIColor.ud.bgBody
        addSubview(searchNavBar)
        searchNavBar.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        // setup right view
        searchTextField.returnKeyType = .search
        searchTextField.enablesReturnKeyAutomatically = true
        searchTextField.clearButtonMode = .never
        searchCountLabel.textColor = UIColor.ud.textPlaceholder
        searchCountLabel.font = UIFont.systemFont(ofSize: 14)
        searchCountLabel.textAlignment = .left
        rightView.addSubview(searchCountLabel)
        searchTextField.placeholder = BundleI18n.MailSDK.Mail_Search_SearchInEmailPlaceholder

        searchTextField.addSubview(loadingView)
        loadingView.isHidden = true
        loadingView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading(_ show: Bool) {
        MailLogger.info("MailContentSearch trigger loading \(show)")
        let loadingInerval: TimeInterval = 0.5
        loadingTimer?.invalidate()
        if show {
            if loadingView.isHidden == true {
                loadingTimer = Timer.scheduledTimer(withTimeInterval: loadingInerval, repeats: false, block: { [weak self] _ in
                    self?.loadingView.isHidden = false
                    self?.searchCountLabel.isHidden = true
                })
            }
            // 若 loading 已经在展示，不需要处理
        } else {
            loadingView.isHidden = true
            searchCountLabel.isHidden = false
        }
    }

    func updateSearchCount(currentIdx: Int, total: Int) {
        let currentIdx = min(currentIdx + 1, total)
        if total == 0 {
            searchCountLabel.text = "0/0"
        } else {
            searchCountLabel.text = "\(currentIdx)/\(total)"
        }
        let correctSize = searchCountLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: bounds.height))
        let newSize = CGSize(width: ceil(correctSize.width), height: ceil(correctSize.height))
        let leftPadding: CGFloat = 10
        let rightPadding: CGFloat = 12
        rightView.frame.size = CGSize(width: newSize.width + leftPadding + rightPadding, height: 32)
        searchCountLabel.frame = CGRect(x: 12, y: 0, width: newSize.width, height: rightView.bounds.height)
        if searchTextField.rightView == nil {
            searchTextField.rightView = rightView
            searchTextField.rightViewMode = .always
        }
    }

    func reset() {
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
        searchTextField.rightView = nil
        searchTextField.rightViewMode = .never
    }
}
