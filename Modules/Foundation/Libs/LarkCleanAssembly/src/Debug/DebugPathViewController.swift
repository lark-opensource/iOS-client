//
//  DebugPathViewController.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/6/29.
//  

#if !LARK_NO_DEBUG

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import Foundation
import Dispatch
import EENavigator
import LarkClean
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkStorage

final class DebugPathViewController: UIViewController, UITableViewDelegate, UISearchControllerDelegate {
    private static let identifier = "DebugPathViewController"

    private let disposeBag = DisposeBag()
    private let viewModel: DebugPathViewModel
    private lazy var dataSource = self.configureDataSource()

    private lazy var tableView = UITableView(frame: self.view.frame, style: .grouped)
    private lazy var searchController = UISearchController()
    private var searchBar: UISearchBar { searchController.searchBar }

    var tip: String?

    init(cleanContext: CleanContext) {
        self.viewModel = DebugPathViewModel(cleanContext: cleanContext)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
        setupRx()

        viewModel.fetchPaths()
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchBar.setShowsCancelButton(true, animated: true)
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchBar.setShowsCancelButton(false, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let headerLabel = UILabel()

        headerLabel.text = dataSource[section].title
        headerLabel.font = .systemFont(ofSize: 16, weight: .bold)

        headerView.addSubview(headerLabel)

        headerLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.left.equalToSuperview().inset(16)
        }

        return headerView
    }

    private func setupView() {
        if let tip, tip.count > 0 {
            tableView.tableHeaderView = {
                let view = UIView()
                view.snp.makeConstraints { $0.height.equalTo(40) }
                let label = UILabel()
                label.text = tip
                label.textColor = .red
                label.font = .systemFont(ofSize: 12)
                label.numberOfLines = 0
                label.textAlignment = .center
                view.addSubview(label)
                label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(edges: 12)) }
                return view
            }()
        }
        tableView.keyboardDismissMode = .onDrag

        view.backgroundColor = .white
        view.addSubview(tableView)

        searchController.hidesNavigationBarDuringPresentation = false
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
            searchController.searchBar.searchTextField.autocapitalizationType = .none
        }
        searchController.delegate = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
    }

    private func setupRx() {
        // 将数据源绑定至 tableView
        filteredData().asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        // 注册 select 回调
        tableView.rx.itemSelected.asDriver()
            .drive { [weak self] indexPath in
                guard let self else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)

                let section = self.dataSource[indexPath.section]
                let item = section.items[indexPath.item]
                self.didSelected(item: item, section: section)
            }
            .disposed(by: disposeBag)

        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    // 返回根据搜索文本筛选后的数据流
    private func filteredData() -> Observable<[PathDebugSection]> {
        let searchText = searchBar.rx.text.orEmpty
        return Observable.combineLatest(searchText, viewModel.data) { text, data in
            if text.isEmpty {
                return data
            }
            var ret = data
            for i in 0..<ret.count {
                ret[i].items = ret[i].items.filter { adapter in
                    adapter.title.lowercased().contains(text.lowercased())
                }
            }
            return ret
        }
    }

    private func configureDataSource() -> RxTableViewSectionedReloadDataSource<PathDebugSection> {
        return .init(
            // 将数据绑定到 cell 上
            configureCell: { dataSource, tableView, indexPath, adapter in
                let cell = tableView.dequeueReusableCell(withIdentifier: Self.identifier)
                    ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.identifier)
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = adapter.title
                cell.textLabel?.font = .systemFont(ofSize: 12)
                cell.detailTextLabel?.text = adapter.description
                return cell
            },
            titleForHeaderInSection: { dataSource, section in
                dataSource[section].title
            }
        )
    }

    private func didSelected(item: PathDebugAdapter, section: PathDebugSection) {
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(style: .normal))
        actionSheet.modalPresentationStyle = .formSheet

        if item.exists {
            actionSheet.addItem(UDActionSheetItem(title: "清除", isEnable: item.exists) { [unowned self] in
                self.viewModel.clearPath(for: item)
            })
        }
        if item.exists && item.isDirectory {
            actionSheet.addItem(UDActionSheetItem(title: "在当前目录新建文件", isEnable: true) { [unowned self] in
                let filePath = item.inner.path + UUID().uuidString
                self.createFile(atPath: filePath) { [weak self] in
                    self?.viewModel.reloadPath(for: item)
                }
            })
        }
        if !item.exists {
            actionSheet.addItem(UDActionSheetItem(title: "在当前路径创建目录", isEnable: true) { [unowned self] in
                self.createDirectory(atPath: item.inner.path)
                self.viewModel.reloadPath(for: item)
            })

            actionSheet.addItem(UDActionSheetItem(title: "在当前路径新建文件", isEnable: true) { [unowned self] in
                self.createFile(atPath: item.inner.path) { [weak self] in
                    self?.viewModel.reloadPath(for: item)
                }
            })
        }
        actionSheet.addDestructiveItem(text: "取消")

        Navigator.shared.present(actionSheet, from: self)
    }

    private func createFile(atPath path: AbsPath, completion: @escaping () -> Void) {
        let parentDir = path.deletingLastPathComponent
        if !parentDir.exists {
            createDirectory(atPath: parentDir)
        }
        let dialog = UDDialog()
        dialog.setTitle(text: "填写要创建的文件大小")
        let textField = UITextField()
        textField.placeholder = "xx B/KB/MB/GB"
        dialog.setContent(view: textField)
        var fileSize: FileSize?
        dialog.addCancelButton()
        dialog.addPrimaryButton(
            text: "确认",
            dismissCheck: { [unowned self] in
                let inputText = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
                fileSize = try? FileSize.parse(from: inputText)
                if fileSize != nil {
                    return true
                }
                UDToast.showTips(with: "格式错误，", on: self.view)
                return false
            },
            dismissCompletion: { [unowned self] in
                guard let fs = fileSize else {
                    UDToast.showTips(with: "异常，", on: self.view)
                    return
                }
                do {
                    try createCustomFile(atPath: path.absoluteString, size: fs, completon: completion)
                } catch {
                    UDToast.showTips(with: "异常：\(error)", on: self.view)
                }
            }
        )
        self.present(dialog, animated: true)
    }

    private func createDirectory(atPath path: AbsPath) {
        try? FileManager.default.createDirectory(atPath: path.absoluteString, withIntermediateDirectories: true)
    }
}

#endif
