//
//  MinutesHomeMoreAlertController.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/14.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import LarkUIKit
import MinutesFoundation
import UniverseDesignIcon

class MinutesHomeMoreAlertController: UIViewController {

    private let presentationManager: SlidePresentationManager = {
        let p = SlidePresentationManager()
        p.style = .actionSheet(.right)
        p.isUsingSpring = true
        p.autoSize = {
            let size = ScreenUtils.sceneScreenSize
            return CGSize(width: 148, height: size.height)
        }
        return p
    }()

    private lazy var contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        v.addGestureRecognizer(tap)
        return v
    }()

    private lazy var tableView: UITableView = {
        let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 66
        tableView.rowHeight = 66
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.layer.cornerRadius = 4
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = false
        return tableView
    }()

    private lazy var items: [Item] = {
        return [Item(image: UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_Trash_TabTitle, type: .trash)]
    }()

    var completionBlock: ((ItemType) -> Void)?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .custom
        transitioningDelegate = presentationManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.backgroundColor = .clear

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(tableView)
        if modalPresentationStyle == .popover {
            tableView.snp.makeConstraints { maker in
                maker.left.bottom.right.equalToSuperview()
                maker.height.equalTo(items.count * 66)
            }
        } else {
            tableView.snp.makeConstraints { maker in
                maker.left.equalToSuperview()
                maker.width.equalTo(132)
                maker.height.equalTo(items.count * 66)
                maker.top.equalTo(view.safeAreaLayoutGuide).offset(42)
            }
        }
    }

    @objc private func tapAction() {
        dismiss(animated: true, completion: nil)
    }

}

extension MinutesHomeMoreAlertController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return tableView.mins.dequeueReusableCell(with: Cell.self) { cell in
            cell.config(with: item)
        }
    }
}

extension MinutesHomeMoreAlertController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completionBlock?(item.type)
        }
    }
}

extension MinutesHomeMoreAlertController {

    class Cell: UITableViewCell {

        private let icon = UIImageView()
        private lazy var titleLabel: UILabel = {
            let l = UILabel()
            l.font = .systemFont(ofSize: 14)
            l.textColor = UIColor.ud.textTitle
            return l
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            selectionStyle = .none
            contentView.addSubview(icon)
            icon.snp.makeConstraints { maker in
                maker.width.height.equalTo(20)
                maker.left.equalTo(16)
                maker.centerY.equalToSuperview()
            }

            contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { maker in
                maker.left.equalTo(48)
                maker.right.equalTo(-16)
                maker.centerY.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func config(with item: Item) {
            icon.image = item.image
            titleLabel.text = item.title
        }
    }

    struct Item {
        let image: UIImage
        let title: String
        let type: ItemType
    }

    enum ItemType {
        case trash
    }
}
