//
//  DebugTaskViewController.swift
//  LarkCleanAssembly
//
//  Created by 7Up on 2023/7/24.
//

#if !LARK_NO_DEBUG

import Foundation
import UIKit
import EENavigator
import LarkClean
import LarkAlertController
import LarkContainer
import SnapKit
import UniverseDesignLoading
import UniverseDesignTag
import LarkStorage
import RxSwift
import RxCocoa

struct DebugVkeySection {
    final class Row {
        let inner: CleanIndex.Vkey
        init(inner: CleanIndex.Vkey) {
            self.inner = inner
        }

        private var _count: Int?

        var count: Int {
            if let v = _count {
                return v
            }
            guard case .unified(let unified)  = inner else { return 0 }

            let store: KVStore
            switch unified.type {
            case .udkv:
                store = KVStores.udkv(space: unified.space, domain: unified.domain)
            case .mmkv:
                store = KVStores.mmkv(space: unified.space, domain: unified.domain)
            @unknown default:
                fatalError("unexpected type")
            }
            let ret = store.allKeys().count
            _count = ret
            return ret
        }

        func setDirty() {
            _count = nil
        }
    }

    var group: String
    var rows: [Row]
}

final class DebugVkeyViewController: UITableViewController {
    var sectionItems: [DebugVkeySection] = []

    let disposeBag = DisposeBag()

    let cleanContext: CleanContext

    init(cleanContext: CleanContext) {
        self.cleanContext = cleanContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshDataSource()

        tableView.reloadData()
    }

    private func refreshDataSource() {
        var sections = [DebugVkeySection]()
        for (name, vkeys) in LarkClean.allVkeys(for: cleanContext) {
            let sec = DebugVkeySection(
                group: name,
                rows: vkeys.map { .init(inner: $0) }
            )
            sections.append(sec)
        }
        sections.sort(by: { $0.group < $1.group })
        sectionItems = sections
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].rows.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let item = sectionItems[section]

        let view = UIView()
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        view.addSubview(label)
        label.text = "group: \(item.group)"
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 12, vertical: 0))
        }
        view.backgroundColor = .white

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = sectionItems[indexPath.section].rows[indexPath.row]

        guard case .unified(let vk) = item.inner else { return cell }

        // spaceView
        let spaceView = UILabel()
        spaceView.text = "space: \(vk.space.isolationId)"
        spaceView.font = .systemFont(ofSize: 12)
        spaceView.textAlignment = .left
        // typeView
        let typeView = UDTag(withText: vk.type.rawValue)
        typeView.colorScheme = .orange
        var typeViewConf = typeView.configuration
        typeViewConf.font = .systemFont(ofSize: 12)
        typeViewConf.horizontalMargin = 4
        typeView.updateConfiguration(typeViewConf)
        // domainView
        let domainView = UILabel()
        domainView.text = "domain: \(vk.domain.asComponents().map(\.isolationId).joined(separator: "."))"
        domainView.font = .systemFont(ofSize: 14)
        domainView.textAlignment = .left
        // countView
        let countView = UILabel()
        countView.font = .systemFont(ofSize: 14)
        countView.text = "count: \(item.count)"

        cell.contentView.addSubview(spaceView)
        cell.contentView.addSubview(typeView)
        cell.contentView.addSubview(domainView)
        cell.contentView.addSubview(countView)

        spaceView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(12)
            make.height.equalTo(14)
        }
        typeView.snp.makeConstraints { make in
            make.left.equalTo(spaceView.snp.right).offset(10)
            make.centerY.equalTo(spaceView.snp.centerY)
            make.height.equalTo(14)
        }
        domainView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.left.equalToSuperview().offset(12)
            make.height.equalTo(16)
        }
        countView.snp.makeConstraints { make in
            make.left.equalTo(domainView.snp.right).offset(10)
            make.centerY.equalTo(domainView.snp.centerY)
            make.height.equalTo(14)
        }
        if #available(iOS 13.0, *) {
            let trashView = UIImageView(image: UIImage(systemName: "trash"))
            trashView.isUserInteractionEnabled = true
            trashView.tintColor = .systemRed
            cell.accessoryView = trashView

            let gesture = UITapGestureRecognizer()
            trashView.addGestureRecognizer(gesture)
            gesture.rx.event.bind { [weak self] _ in self?.cleanData(with: item) }.disposed(by: disposeBag)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sectionItems[indexPath.section].rows[indexPath.row]
        guard case .unified(let uni) =  item.inner else {
            return
        }

        let space = uni.space.isolationId
        let domain = uni.domain.asComponents().map(\.isolationId).joined(separator: "_")
        let type = uni.type.rawValue
        guard let url = URL(string: "//client/lark_storage/key_value/debug?space=\(space)&domain=\(domain)&type=\(type)") else {
            fatalError("make url failed")
        }
        Navigator.shared.push(url, from: self)
    }

    private func cleanData(with row: DebugVkeySection.Row) {
        guard case .unified(let uni) = row.inner else {
            return
        }
        switch uni.type {
        case .udkv:
            KVStores.udkv(space: uni.space, domain: uni.domain).clearAll()
        case .mmkv:
            KVStores.mmkv(space: uni.space, domain: uni.domain).clearAll()
        @unknown default:
            fatalError("unexpected type")
        }
        row.setDirty()
        tableView.reloadData()
    }

}

#endif
