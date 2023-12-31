//
//  DetailAttachmentContentView.swift
//  Todo
//
//  Created by baiyantao on 2022/12/21.
//

import CTFoundation

final class DetailAttachmentContentView: UIView {

    var cellDatas: [DetailAttachmentContentCellData]? {
        didSet {
            guard cellDatas != nil else {
                tableView.isHidden = true
                return
            }
            tableView.isHidden = false
            tableView.reloadData()
        }
    }

    var headerData: DetailAttachmentHeaderViewData? {
        didSet {
            guard let headerData = headerData else {
                headerView.isHidden = true
                return
            }
            headerView.isHidden = false
            headerView.viewData = headerData
            headerView.frame.size.height = headerData.headerHeight
            tableView.tableHeaderView = headerView
        }
    }

    var footerData: DetailAttachmentFooterViewData? {
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

    weak var actionDelegate: DetailAttachmentContentCellDelegate? {
        didSet {
            tableView.reloadData()
        }
    }

    private(set) lazy var tableView = getTableView()
    private(set) lazy var headerView = DetailAttachmentHeaderView()
    private(set) lazy var footerView = DetailAttachmentFooterView()

    let edgeInsets: UIEdgeInsets

    init(edgeInsets: UIEdgeInsets = .zero, hideHeader: Bool = false, hideFooter: Bool = false) {
        self.edgeInsets = edgeInsets
        super.init(frame: .zero)

        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(edgeInsets)
        }
        headerView.isHidden = hideHeader
        footerView.isHidden = hideFooter

        tableView.delegate = self
        tableView.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = footerView
        tableView.ctf.register(cellType: DetailAttachmentContentCell.self)
        tableView.separatorStyle = .none
        tableView.clipsToBounds = true
        return tableView
    }
}

extension DetailAttachmentContentView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let cellDatas = cellDatas else { return .zero }
        return cellDatas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailAttachmentContentCell.self, for: indexPath),
              let cellData = cellData(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.actionDelegate = actionDelegate
        cell.viewData = cellData
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cellData = cellData(at: indexPath) else { return .zero }
        return cellData.cellHeight
    }

    private func cellData(at indexPath: IndexPath) -> DetailAttachmentContentCellData? {
        guard let cellDatas = cellDatas, let row = safeCheck(indexPath: indexPath, cellDatas: cellDatas) else {
            return nil
        }
        return cellDatas[row]
    }

    private func safeCheck(indexPath: IndexPath, cellDatas: [DetailAttachmentContentCellData]) -> Int? {
        guard !cellDatas.isEmpty else {
            DetailAttachment.logger.error("items is empty")
            return nil
        }
        let row = indexPath.row
        guard row >= 0 && row < cellDatas.count else {
            DetailAttachment.logger.error("out of range. cur: \(row), total: \(cellDatas.count)")
            return nil
        }
        return row
    }
}
