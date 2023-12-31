//
//  SearchResultView.swift
//  ByteView
//
//  Created by huangshun on 2019/6/5.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import ByteViewUI

class SearchContainerView: UIView {

    enum Status {
        case loading, result(Bool), noResult
    }

    var hasEmptyText: Bool = false

    private let loadMoreSubject: PublishSubject<Void> = PublishSubject()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 72
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.keyboardDismissMode = .onDrag
        tableView.loadMoreDelegate?.addBottomLoading { [weak self] in
            self?.loadMoreSubject.onNext(())
        }
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

    var customNoResultView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            noResultDefaultView.removeFromSuperview()
            guard let noResultView = customNoResultView else {
                self.addDefaultNoResultView()
                return
            }
            self.addSubview(noResultView)
            noResultView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(self.vc.keyboardLayoutGuide.snp.top)
            }
        }
    }

    var noResultView: UIView {
        if let customView = customNoResultView {
            return customView
        } else {
            return noResultDefaultView
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.vc.keyboardLayoutGuide.snp.top)
        }
        self.addDefaultNoResultView()
    }

    private func addDefaultNoResultView() {
        self.addSubview(noResultDefaultView)
        noResultDefaultView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.vc.keyboardLayoutGuide.snp.top)
        }
    }

    func update(_ status: Status) {
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

    var statusObserver: AnyObserver<Status> {
        return AnyObserver<Status>(eventHandler: { [weak self] element in
            if case let .next(status) = element {
                self?.update(status)
            }
        })
    }

    var loadMoreObservable: Observable<Void> {
        return loadMoreSubject.asObservable()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
