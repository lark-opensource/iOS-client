//
//  MsgCardAvatarListView.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/22.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import UniverseDesignEmpty
import LarkMessengerInterface

final class MsgCardAvatarListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let cellIdentify = "MsgCardAvatarListViewControl"
    private let rowHeight: CGFloat = 66

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloat)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = rowHeight
        tableView.rowHeight = rowHeight
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.register(MsgCardAvatarListCell.self, forCellReuseIdentifier: cellIdentify)
        return tableView
    }()

    let navigator: Navigatable
    var persons: [Person]

    init(persons: [Person], navigator: Navigatable) {
        self.persons = persons
        self.navigator = navigator

        super.init(nibName: nil, bundle: nil)
    }
    
    func updatePerson(persons: [Person]) {
        self.persons = persons
        DispatchQueue.main.async { self.tableView.reloadData() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleString = BundleI18n.LarkMessageCard.OpenPlatform_CardForMyAi_PplCntMemberListTtl(persons.count)
        self.titleColor = UIColor.ud.textTitle
        addCloseItem()
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentify, for: indexPath) as? MsgCardAvatarListCell,
              indexPath.row < persons.count else {
            return UITableViewCell()
        }
        cell.update(person: persons[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.row < persons.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let person = persons[indexPath.row]
        guard let id = person.id else { return }
        let body = PersonCardBody(chatterId: id,
                                  fromWhere: .chat,
                                  source: .chat)
        navigator.push(body: body, from: self)
    }
}
