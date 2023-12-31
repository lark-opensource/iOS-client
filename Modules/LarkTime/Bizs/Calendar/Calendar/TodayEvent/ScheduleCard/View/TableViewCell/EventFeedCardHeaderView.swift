//
//  EventFeedCardHeaderView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/17.
//

class EventFeedCardHeaderView: UITableViewHeaderFooterView {
    private lazy var view = UIView()
    static let identifier = String(describing: EventFeedCardHeaderView.self)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(8)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
