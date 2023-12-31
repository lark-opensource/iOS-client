//
//  MinutesGroupMeetingViewController.swift
//  Minutes
//
//  Created by yangyao on 2023/4/27.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignIcon
import LarkContainer

class MinutesGroupMeetingCell: UITableViewCell {
    private lazy var iconView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.minutesLogoFilled, iconColor: UIColor.ud.B500)
        return imageView
    }()

    private lazy var contentLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.B500
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconView)
        contentView.addSubview(contentLabel)
        iconView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.right.lessThanOrEqualTo(-16)
        }
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    func configure(with meeting: GroupMeeting) {
        contentLabel.text = meeting.topic
    }
}


class MeetingGroupHeaderView: UIView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)

        label.text = BundleI18n.Minutes.MMWeb_G_RecordingsMenu
        label.font = .systemFont(ofSize: 14, weight: .medium)
        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview().offset(-8)
            maker.left.equalToSuperview().offset(7)
            maker.right.lessThanOrEqualToSuperview().offset(-7)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesGroupMeetingViewController: UIViewController {
    var dataSource: [GroupMeeting] = []
    let userResolver: UserResolver
    let tracker: MinutesTracker

    init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadData() {
        tableView.reloadData()
    }

    lazy var tableView: MinutesTableView = {
        let tableView: MinutesTableView = MinutesTableView()
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MinutesGroupMeetingCell.self, forCellReuseIdentifier: MinutesGroupMeetingCell.description())
        tableView.tableHeaderView = MeetingGroupHeaderView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension MinutesGroupMeetingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesGroupMeetingCell.description(), for: indexPath) as? MinutesGroupMeetingCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none
        let item = dataSource[indexPath.row]
        cell.configure(with: item)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]
        if let url = URL(string: item.url) {
            userResolver.navigator.push(url, context: ["forcePush": true], from: self)
        }
        tracker.tracker(name: .detailClick, params: ["click": "discussion_record", "tab_type": "group_discussion"])
    }
}

extension MinutesGroupMeetingViewController: PagingViewListViewDelegate {
    public func listView() -> UIView {
        return view
    }

    public func listScrollView() -> UIScrollView {
        return self.tableView
    }
}

