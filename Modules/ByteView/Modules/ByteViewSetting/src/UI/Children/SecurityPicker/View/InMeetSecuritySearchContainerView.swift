//
//  InMeetSecuritySearchContainerView.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/12.
//

import Foundation
import ByteViewCommon
import ByteViewUI

final class InMeetSecuritySearchContainerView: UIView {
    enum Status {
        case loading, result(Bool), noResult
    }

    var hasEmptyText: Bool = false

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 72
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.keyboardDismissMode = .onDrag
        tableView.isAccessibilityElement = true
        tableView.isHidden = true
        return tableView
    }()

    lazy var loadingView: UIView = {
        let view = LoadingTipView(frame: .zero, padding: 8, style: .blue)
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        view.start(with: I18n.View_VM_Loading)

        let containerView = UIView()
        containerView.isUserInteractionEnabled = false
        containerView.addSubview(view)
        view.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        return containerView
    }()

    lazy var noResultDefaultView: UIView = {
        let label = UILabel(frame: CGRect.zero)
        label.text = I18n.View_M_NoResultsFound
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 16)

        let view = UIView()
        view.isHidden = true
        view.addSubview(label)
        label.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }
        return view
    }()

    var noResultView: UIView {
        noResultDefaultView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }

        self.addSubview(noResultDefaultView)
        noResultDefaultView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }
    }

    func update(_ status: Status) {
        Logger.setting.info("search container update status: \(status)")
        tableView.isHidden = true
        loadingView.isHidden = true
        noResultView.isHidden = true

        switch status {
        case .loading:
            loadingView.isHidden = false
        case let .result(hasMore):
            tableView.isHidden = false
            tableView.loadMoreDelegate?.endBottomLoading(hasMore: hasMore)
        case .noResult:
            if !hasEmptyText {
                noResultView.isHidden = false
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
