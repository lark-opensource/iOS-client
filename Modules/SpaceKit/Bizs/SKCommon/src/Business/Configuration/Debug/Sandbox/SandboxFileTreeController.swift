//
//  SandboxFileTreeController.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2021/11/18.
//
#if BETA || ALPHA || DEBUG
import UIKit
import EENavigator
import SKResource
import SKFoundation
import LarkFoundation
import SpaceInterface
import UniverseDesignIcon
import LarkEMM

/// 沙盒文件浏览界面
class SandboxFileTreeController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private lazy var copyBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("复制沙盒根路径", for: .normal)
        btn.addTarget(self, action: #selector(copyPath), for: .touchUpInside)
        return btn
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(_ItemCell.self, forCellReuseIdentifier: _ItemCell.reuseID)
        return tableView
    }()
    
    private let viewModel: _ViewModel
    
    init(initPath: SKFilePath) {
        self.viewModel = .init(initPath: initPath)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.refreshCallBack = { [weak self] in
            guard let self = self else { return }
            self.setHeaderView()
            self.tableView.reloadData()
            self.updateNavBar()
        }
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        updateNavBar()
        setHeaderView()
    }
    
    private func updateNavBar() {
        if #available(iOS 13.0, *) {
            let backbbi = UIBarButtonItem(image: .init(systemName: "arrow.backward"), style: .plain,
                                          target: self, action: #selector(onBackClick))
            let closebbi = UIBarButtonItem(image: .init(systemName: "xmark"), style: .plain,
                                           target: self, action: #selector(onCloseClick))
            navigationItem.leftBarButtonItems = [backbbi, closebbi]
        } else {
            let backbbi = UIBarButtonItem(title: "<", style: .plain, target: self, action: #selector(onBackClick))
            let closebbi = UIBarButtonItem(title: "×", style: .plain, target: self, action: #selector(onCloseClick))
            navigationItem.leftBarButtonItems = [backbbi, closebbi]
        }
        title = viewModel.title
        if viewModel.isRootDic {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    private func setHeaderView() {
        tableView.tableHeaderView = (viewModel.isRootDic && Utils.isSimulator) ? copyBtn : nil
        tableView.tableHeaderView?.frame = CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 60))
    }
    
    // MARK: - tableView delegate & dateSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: _ItemCell.reuseID, for: indexPath)
        if let sandboxCell = cell as? _ItemCell {
            sandboxCell.item = viewModel.datas[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.datas.count else { return }
        
        let item = viewModel.datas[indexPath.row]
        if item.type == .file {
            onClickFile(item.path?.pathString ?? "")
        } else {
            viewModel.currentPath = item.path ?? SKFilePath.absPath("")
        }
    }
    
    // MARK: - actions
    @objc
    private func onBackClick() {
        if viewModel.isRootDic {
            navigationController?.popViewController(animated: true)
        } else {
            viewModel.backToLastHierarchy()
        }
    }
    
    @objc
    private func onCloseClick() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    private func copyPath() {
        //debug下使用，用默认的defaultConfig管控
        SCPasteboard.general(SCPasteboard.defaultConfig()).string = SKFilePath.globalSandboxWithDocument.pathString
    }
    
    private func onClickFile(_ path: String) {
        let fileURL = URL(fileURLWithPath: path)
        let fileName = fileURL.lastPathComponent
        let fileType = SKFilePath.getFileExtension(from: fileName)
        let fileId = fileURL.absoluteString
        let file = DriveSDKLocalFileV2(fileName: fileName, fileType: fileType, fileURL: fileURL,
                                       fileId: fileId, dependency: TestLocalDependencyImpl())
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(files: [file], index: 0, appID: "9999",
                                         thirdPartyAppID: nil, naviBarConfig: config)
        Navigator.shared.push(body: body, from: self)
    }
}

private class _ItemNode {
    enum FileType {
        case file, directory
    }
    var name = ""
    var path: SKFilePath?
    var type = FileType.file
}

private class _ViewModel {
    
    private(set) var datas: [_ItemNode] = []
    let rootPath: SKFilePath
    var refreshCallBack: (() -> Void)?
    var currentPath: SKFilePath {
        didSet {
            loadDataForPath(currentPath)
        }
    }
    var isRootDic: Bool { currentPath == rootPath }
    var title: String { isRootDic ? "沙盒浏览器" : currentPath.displayName }
    
    init(initPath: SKFilePath) {
        rootPath = initPath
        currentPath = initPath
        loadDataForPath(currentPath)
    }
    
    private func loadDataForPath(_ path: SKFilePath) {
        guard let paths = try? path.contentsOfDirectory() else {
            datas = []
            refreshCallBack?()
            return
        }
        datas = paths.map { subPath in
            let fullPath = path.appendingRelativePath(subPath)
            var isDir = fullPath.exists && fullPath.isDirectory
            let item = _ItemNode()
            item.path = fullPath
            item.type = isDir ? .directory : .file
            item.name = subPath
            return item
        }
        refreshCallBack?()
    }
    
    func backToLastHierarchy() {
        currentPath = currentPath.deletingLastPathComponent
    }
}

private class _ItemCell: UITableViewCell {
    static let reuseID = "cell"
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let sizeLabel = UILabel()
    var item: _ItemNode? {
        didSet {
            updateUI()
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupView() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(sizeLabel)
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        sizeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        sizeLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        sizeLabel.textAlignment = .right
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalTo(sizeLabel.snp.left).offset(-8)
        }
        sizeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    private func updateUI() {
        guard let item = self.item else { return }
        
        let size = _FileManager.getFileSizeForPath(item.path)
        sizeLabel.text = _FileManager.getFileSizeDisplayText(size)
        
        let isDir = (item.type == .directory)
        if #available(iOS 13.0, *) {
            titleLabel.text = item.name
            imageView?.image = isDir ? UIImage(systemName: "folder") : UIImage(systemName: "doc.plaintext")
        } else {
            titleLabel.text = item.name
            imageView?.image = isDir ? UDIcon.fileFolderColorful : UDIcon.fileColorful
        }
    }
}

private class _FileManager {

    static func getFileSizeForPath(_ path: SKFilePath?) -> Int? {
        guard let path = path else { return nil }
        if path.exists, !path.isDirectory {
            if let size = path.fileSize {
                return Int(size)
            }
        }
        return nil
    }

    static func getFileSizeDisplayText(_ fileSize: Int?) -> String {
        guard let fileSize = fileSize, fileSize > 0 else { return "" }
        var fileSizeText = ""
        if fileSize > 1024 * 1024 {
            fileSizeText = String(format: "%.2fMB", Float(fileSize) / Float(1024 * 1024))
        } else {
            fileSizeText = String(format: "%.2fKB", Float(fileSize) / Float(1024))
        }
        return fileSizeText
    }
}
#endif
