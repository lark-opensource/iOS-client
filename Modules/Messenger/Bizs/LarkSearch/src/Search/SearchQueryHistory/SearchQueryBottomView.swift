//
//  SearchQueryBottomView.swift
//  LarkSearch
//
//  Created by SuPeng on 5/6/19.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import EETroubleKiller
import LarkSDKInterface

protocol SearchQueryBottomViewDelegate: AnyObject {
    func bottomViewDidClickClearHistory(_ bottomView: SearchQueryBottomView)
    func bottomView(_ bottomView: SearchQueryBottomView, didSelect historyInfo: SearchHistoryInfo)
}

final class SearchQueryBottomView: UIView {
    weak var delegate: SearchQueryBottomViewDelegate?

    private var historyButtons: [SearchHistoryInfoButton] = []
    private let titleLabel = UILabel()
    private let clearButton = UIButton()

    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = BundleI18n.LarkSearch.Lark_Search_SearchHistory
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(20)
        }

        clearButton.setImage(Resources.search_clear_history, for: .normal)
        addSubview(clearButton)
        clearButton.snp.makeConstraints { (make) in
            make.right.equalTo(-18)
            make.centerY.equalTo(titleLabel)
        }
        clearButton.rx.tap
            .subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                self.delegate?.bottomViewDidClickClearHistory(self)
            })
            .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(historyInfos: [SearchHistoryInfo]) {
        historyButtons.forEach { $0.removeFromSuperview() }
        historyButtons = historyInfos.map { SearchHistoryInfoButton(info: $0) }
        historyButtons.enumerated().forEach { (index, button) in
            let colIndex = index % 2
            let rowIndex = ceil(Double(index + 1) / 2) - 1
            addSubview(button)
            button.snp.makeConstraints { (make) in
                make.width.equalToSuperview().multipliedBy(0.5).offset(-24)
                make.height.equalTo(36)
                if colIndex == 0 {
                    make.left.equalTo(16)
                } else {
                    make.left.equalTo(snp.centerX).offset(8)
                }
                make.top.equalTo(titleLabel.snp.bottom).offset(20 + rowIndex * 36)
            }
            button.didClickSearchHistoryInfoBlock = { [weak self] info in
                guard let self = self else { return }
                self.delegate?.bottomView(self, didSelect: info)
            }
        }
        self.layoutIfNeeded() // 提前layout, 避免动画从0出来
    }
}

private final class SearchHistoryInfoButton: UIControl {
    var didClickSearchHistoryInfoBlock: ((SearchHistoryInfo) -> Void)?

    private let info: SearchHistoryInfo
    private let titleLabel = UILabel()

    init(info: SearchHistoryInfo) {
        self.info = info
        super.init(frame: .zero)

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = info.query
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }

        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        didClickSearchHistoryInfoBlock?(info)
    }
}

extension SearchHistoryInfoButton: CaptureProtocol & DomainProtocol {

    var isLeaf: Bool {
        return true
    }

    var domainKey: [String: String] {
        return [
            "query": "\(info.query.md5())",
            "source": "\(info.searchAction.tab)",
            "subsource": "\(String(describing: info.searchAction.tab))"
        ]
    }
}
