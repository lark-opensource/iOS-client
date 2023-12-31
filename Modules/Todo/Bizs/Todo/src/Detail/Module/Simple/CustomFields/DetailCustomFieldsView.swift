//
//  DetailCustomFieldsView.swift
//  Todo
//
//  Created by baiyantao on 2023/4/18.
//

import Foundation
import RxSwift
import LarkContainer

final class DetailCustomFieldsView: UIView {

    var cellDatas: [DetailCustomFieldsContentCellData]? {
        didSet {
            guard cellDatas != nil else {
                tableView.isHidden = true
                return
            }
            tableView.isHidden = false

            let contentOffset = self.tableView.contentOffset
            let contentSize = self.tableView.contentSize
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            var offset: CGFloat = 0
            if self.tableView.contentSize.height < contentSize.height {
                offset = contentSize.height - self.tableView.contentSize.height
            }
            self.tableView.setContentOffset(
                CGPoint(x: contentOffset.x, y: max(0, contentOffset.y - offset)),
                animated: false
            )
        }
    }

    var headerData: DetailCustomFieldsHeaderViewData? {
        didSet {
            guard let headerData = headerData else {
                headerView.isHidden = true
                return
            }
            headerView.isHidden = false
            headerView.viewData = headerData
            headerView.frame.size.height = DetailCustomFields.headerHeight
            tableView.tableHeaderView = headerView
        }
    }

    var footerData: DetailCustomFieldsFooterViewData? {
        didSet {
            guard let footerData = footerData else {
                footerView.isHidden = true
                return
            }
            footerView.isHidden = false
            footerView.viewData = footerData
            footerView.frame.size.height = footerData.footerHeight
            tableView.tableFooterView = footerView
        }
    }

    private(set) lazy var tableView = getTableView()
    private(set) lazy var headerView = DetailCustomFieldsHeaderView()
    private(set) lazy var footerView = DetailCustomFieldsFooterView()

    private lazy var layoutHelper = DetailCustomFields.initTagListView()
    private lazy var layoutInputHelper = InputController(resolver: userResolver, sourceId: nil)
    private static let layoutInput = DetailSubTaskCellSummaryView()
    weak var actionDelegate: DetailCustomFieldsContentCellDelegate?
    private let disposeBag = DisposeBag()
    private let userResolver: LarkContainer.UserResolver
    private let context: DetailModuleContext

    init(resolver: UserResolver, context: DetailModuleContext) {
        self.userResolver = resolver
        self.context = context
        super.init(frame: .zero)
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        tableView.rx.observe(CGSize.self, #keyPath(UITableView.contentSize))
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.invalidateIntrinsicContentSize()
            })
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let contentHeight = tableView.contentSize.height
        return CGSize(width: Self.noIntrinsicMetric, height: contentHeight)
    }

    private func getTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        tableView.ctf.register(cellType: DetailCustomFieldsContentCell.self)
        tableView.separatorStyle = .none
        tableView.clipsToBounds = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = DetailCustomFields.cellHeight
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }
}

extension DetailCustomFieldsView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let cellDatas = cellDatas else { return .zero }
        return cellDatas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailCustomFieldsContentCell.self, for: indexPath),
              let cellData = cellData(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.actionDelegate = actionDelegate
        cell.viewData = cellData
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let data = cellData(at: indexPath) else { return .zero }
        switch data.customType {
        case .tag(let options):
            if options.count > 1 {
                let tagViews = DetailCustomFields.options2TagViews(options, with: layoutHelper)
                layoutHelper.frame.size = CGSize(
                    width: tableView.frame.width - 140,
                    height: .greatestFiniteMagnitude
                )
                layoutHelper.removeAllTags()
                layoutHelper.addTagViews(tagViews)
                let height = layoutHelper.intrinsicContentSize.height + 18
                return data.showMore ? min(height, DetailCustomFields.contentMaxHeight) : height
            } else {
                return DetailCustomFields.cellHeight
            }
        case .text(let core):
            let size = core.layout(CGSize(width: tableView.frame.width - 140, height: .greatestFiniteMagnitude))
            if let size = size {
                // 上下边距各5. 底部为4
                let height = max(size.height + 14, DetailCustomFields.cellHeight)
                return data.showMore ? min(height, DetailCustomFields.contentMaxHeight) : height
            }
            return DetailCustomFields.cellHeight

        default:
            return DetailCustomFields.cellHeight
        }
    }

    private func cellData(at indexPath: IndexPath) -> DetailCustomFieldsContentCellData? {
        guard let cellDatas = cellDatas, let row = safeCheck(indexPath: indexPath, cellDatas: cellDatas) else {
            return nil
        }
        return cellDatas[row]
    }

    private func safeCheck(indexPath: IndexPath, cellDatas: [DetailCustomFieldsContentCellData]) -> Int? {
        guard !cellDatas.isEmpty else {
            DetailCustomFields.logger.error("items is empty")
            return nil
        }
        let row = indexPath.row
        guard row >= 0 && row < cellDatas.count else {
            DetailCustomFields.logger.error("out of range. cur: \(row), total: \(cellDatas.count)")
            return nil
        }
        return row
    }
}
