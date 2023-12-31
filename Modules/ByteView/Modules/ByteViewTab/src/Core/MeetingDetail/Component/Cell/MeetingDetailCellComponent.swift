//
//  MeetingDetailCellComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/21.
//

import Foundation

class MeetingDetailCellComponent: MeetingDetailComponent {

    private static let cellID = String(describing: MeetingDetailCellComponent.self)
    let regularLRInset: CGFloat = 28
    let compactLRInset: CGFloat = 16

    var LRInset: CGFloat {
        Util.rootTraitCollection?.horizontalSizeClass == .regular ? regularLRInset : compactLRInset
    }

    var title: String {
        ""
    }

    var isMeetingEnd: Bool {
        guard let commonInfo = viewModel?.commonInfo.value else { return true }
        return commonInfo.meetingStatus == .meetingEnd
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.attributedText = NSAttributedString(string: title, config: .boldBodyAssist, textColor: UIColor.ud.textPlaceholder)
        return titleLabel
    }()

    lazy var tableView: FitContentTableView = {
        let tableView = FitContentTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.register(MeetingFileTableViewCell.self, forCellReuseIdentifier: Self.cellID)
        return tableView
    }()

    var items: [MeetingDetailFile] = []

    required init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgFloat
        translatesAutoresizingMaskIntoConstraints = false

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        super.setupViews()

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(LRInset)
            make.top.equalToSuperview().inset(16)
        }
        addTableView()
    }

    func addTableView() {
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(LRInset)
            make.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom)
        }
        tableView.isHidden = false
    }

    func removeTableView() {
        tableView.isHidden = true
        tableView.removeFromSuperview()
    }

    override func updateLayout() {
        super.updateLayout()
        titleLabel.snp.updateConstraints { (make) in
            make.left.right.equalToSuperview().inset(LRInset)
        }
        if !tableView.isHidden {
            tableView.snp.updateConstraints { (make) in
                make.left.right.equalToSuperview().inset(LRInset)
            }
        }
    }

    func openURL(_ urlString: String) {}

    func forwardMinutes(_ urlString: String) {}

    func openMinutesCollection(with data: MeetingDetailFile) {}

    func openMinutes(with data: MeetingDetailFile) {}
}

extension MeetingDetailCellComponent: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MeetingDetailCellComponent.cellID) as? MeetingFileTableViewCell, let vm = self.viewModel else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.tapAction = { [weak self] in
            guard let self = self else { return }
            if item.isMinutesCollection {
                self.openMinutes(with: item)
            } else {
                if let urlString = item.url {
                    self.openURL(urlString)
                }
            }
        }
        cell.forwardAction = { [weak self] in
            if let urlString = item.url {
                if item.isMinutesCollection {
                    self?.forwardMinutes("\(urlString)?share_type=1")
                } else {
                    self?.forwardMinutes(urlString)
                }
            }
        }
        cell.collectionAction = { [weak self] in
            guard let self = self else { return }
            self.openMinutesCollection(with: item)
        }
        cell.config(with: item, viewModel: vm.tabViewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = items[indexPath.row]
        return item.isMinutesCollection ? 106 : 76
    }
}
