//
//  ContainerFilesController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2023/5/28.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import EENavigator
import LarkStorage
import QuickLook
import LarkReleaseConfig

struct ContainerFilesItem: SearchTableItem {
    let path: String
    let name: String
    let isDirectory: Bool

    var title: String { name }
}

class ContainerFilesController: UIViewController, UISearchControllerDelegate {
    private static let identifier = "ContainerFilesCell"

    let name: String
    let path: String

    let searchQueue = OperationQueue()
    lazy var hintLabel = UILabel()
    lazy var searchingLabel = UILabel()
    lazy var searchController = UISearchController()
    lazy var fileTableView = UITableView()
    lazy var searchTableView = UITableView()

    let disposeBag = DisposeBag()

    init(name: String, path: String) {
        self.name = name
        self.path = path

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupRx()
    }

    private func setupView() {
        title = name

        hintLabel.text = "没有数据"
        hintLabel.isHidden = true
        hintLabel.textColor = .gray

        searchingLabel.isHidden = true
        searchingLabel.textColor = .gray

        fileTableView.keyboardDismissMode = .onDrag
        fileTableView.register(UITableViewCell.self, forCellReuseIdentifier: ContainerFilesController.identifier)

        searchTableView.isHidden = true
        searchTableView.keyboardDismissMode = .onDrag
        searchTableView.register(UITableViewCell.self, forCellReuseIdentifier: ContainerFilesController.identifier)

        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
            searchController.searchBar.searchTextField.autocapitalizationType = .none
        }
        searchController.delegate = self

        view.backgroundColor = .white
        view.addSubview(fileTableView)
        view.addSubview(hintLabel)
        view.addSubview(searchTableView)
        view.addSubview(searchingLabel)

        fileTableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        searchingLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.centerX.equalToSuperview()
        }
        searchTableView.snp.makeConstraints { make in
            make.top.equalTo(searchingLabel.snp.bottom)
            make.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupRx() {
        fileTableView.rx.itemSelected
            .bind { [weak self] indexPath in
                if self?.fileTableView.cellForRow(at: indexPath) != nil {
                    self?.fileTableView.deselectRow(at: indexPath, animated: true)
                }
            }
            .disposed(by: disposeBag)
        fileTableView.rx.modelSelected(ContainerFilesItem.self)
            .bind { [weak self] in self?.didSelected($0) }
            .disposed(by: disposeBag)
        searchTableView.rx.itemSelected
            .bind { [weak self] indexPath in
                if self?.searchTableView.cellForRow(at: indexPath) != nil {
                    self?.searchTableView.deselectRow(at: indexPath, animated: true)
                }
            }
            .disposed(by: disposeBag)
        searchTableView.rx.modelSelected(ContainerFilesItem.self)
            .bind { [weak self] in self?.didSelected($0) }
            .disposed(by: disposeBag)

        // 创建数据流
        let dataStream = Observable
            .create { [weak self] observer in
                if let self = self {
                    observer.onNext(self.loadAllFiles())
                }
                return Disposables.create()
            }
            .subscribeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
            .share(replay: 1)

        let isFilesEmpty = dataStream.map(\.isEmpty).share(replay: 1)

        isFilesEmpty.map(!).bind(to: hintLabel.rx.isHidden).disposed(by: disposeBag)
        isFilesEmpty
            .observeOn(MainScheduler.instance)
            .bind { [weak self] in
                if $0 {
                    self?.hintLabel.text = "没有数据"
                    self?.navigationItem.searchController = nil
                } else {
                    self?.navigationItem.searchController = self?.searchController
                    //                    self?.navigationItem.hidesSearchBarWhenScrolling = false
                }
            }
            .disposed(by: disposeBag)

        dataStream
            .bind(to: fileTableView.rx.items(
                cellIdentifier: ContainerFilesController.identifier,
                cellType: UITableViewCell.self
            )) { _, item, cell in
                Self.configureCell(item: item, cell: cell)
            }

        let searchResult = PublishSubject<[ContainerFilesItem]>()

        searchResult
            .bind(to: searchTableView.rx.items(
                cellIdentifier: ContainerFilesController.identifier,
                cellType: UITableViewCell.self
            )) { _, item, cell in
                Self.configureCell(item: item, cell: cell)
            }
            .disposed(by: disposeBag)

        searchController.searchBar.rx.text.orEmpty
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .bind { [weak self] text in
                guard let self = self else { return }

                searchResult.onNext([]) // 先清空现有搜索列表
                guard !text.isEmpty else {
                    return
                }

                self.searchingLabel.text = "搜索中..."
                self.searchingLabel.sizeToFit()
                var results = [ContainerFilesItem]()
                let operation = FileWalkerOperation(path: self.path, filter: {
                    $0.lowercased().contains(text.lowercased())
                }, action: { item in
                    results.append(item)
                    searchResult.onNext(results)
                }, onComplete: {
                    self.searchingLabel.text = ""
                    self.searchingLabel.sizeToFit()
                })
                self.searchQueue.cancelAllOperations()
                self.searchQueue.addOperation(operation)
            }
    }

    func didSelected(_ item: ContainerFilesItem) {
        if item.isDirectory {
            let newPath = NSString.path(withComponents: [self.path, item.title])
            let controller = ContainerFilesController(name: item.title, path: newPath)
            Navigator.shared.push(controller, from: self)
        } else {
            present(ContainerPreviewController(path: item.path), animated: true)
        }
    }

    func loadAllFiles() -> [ContainerFilesItem] {
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: self.path) else {
            return []
        }
        return names.map { name in
            let newPath = NSString.path(withComponents: [self.path, name])
            var directoryExists = ObjCBool(false)
            let fileExists = FileManager.default.fileExists(atPath: newPath, isDirectory: &directoryExists)
            let isDirectory = fileExists && directoryExists.boolValue

            return ContainerFilesItem(path: newPath, name: name, isDirectory: isDirectory)
        }
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchController.searchBar.setShowsCancelButton(true, animated: true)
        }
        title = "搜索"
        fileTableView.isHidden = true
        searchTableView.isHidden = false
        searchingLabel.isHidden = false
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
        title = name
        fileTableView.isHidden = false
        searchTableView.isHidden = true
        searchingLabel.isHidden = true
    }

    private static func configureCell(item: ContainerFilesItem, cell: UITableViewCell) {
        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.title
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = item.title
        }
        cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none
    }
}

class SharedContainerController: ContainerFilesController {
    var valid = true

    init() {
        let path: String
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: ReleaseConfig.groupId
        ) {
            path = url.path
        } else {
            path = NSHomeDirectory()
            self.valid = false
        }
        super.init(name: "AppGroup", path: path)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadAllFiles() -> [ContainerFilesItem] {
        guard valid else { return [] }
        return super.loadAllFiles()
    }
}

let SystemContainerControllerProvider = {
    ContainerFilesController(name: "Container", path: NSHomeDirectory())
}

let SharedContainerControllerProvider = { SharedContainerController() }

#endif
