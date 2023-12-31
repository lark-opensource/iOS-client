//
//  SandboxViewController.swift
//  swit_test
//
//  Created by bytedance on 2021/6/29.
//
import Foundation
#if !LARK_NO_DEBUG
import UIKit
import LarkFoundation
import LarkSensitivityControl

final class SandboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var copyBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("复制沙盒路径", for: .normal)
        btn.addTarget(self, action: #selector(copyPath), for: .touchUpInside)
        return btn
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SandboxDisplayCell.self, forCellReuseIdentifier: SandboxDisplayCell.reuseID)
        return tableView
    }()
    let viewModel: SandboxFileViewModel
    init() {
        self.viewModel = SandboxFileViewModel()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.refreshCallBack = { [weak self] in
            guard let self = self else {
                return
            }
            self.setHeaderView()
            self.tableView.reloadData()
            self.updateNavBar()
        }
        setupView()
    }
    func setupView() {
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        updateNavBar()
        setHeaderView()
    }
    func updateNavBar() {
        let backBtn = UIButton()
        backBtn.setImage(Resources.backBtn, for: .normal)
        backBtn.addTarget(self, action: #selector(popSelf), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
        title = viewModel.title
        if viewModel.isRootDic {
            self.navigationItem.rightBarButtonItem = nil
        } else {
            let rightItem = UIBarButtonItem(barButtonSystemItem: .action,
                                            target: self,
                                            action: #selector(shareBtnClick))
            self.navigationItem.rightBarButtonItem = viewModel.datas.isEmpty ? nil : rightItem
        }
    }
    // MARK: - tableView delegate&dateSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SandboxDisplayCell.reuseID, for: indexPath)
        if let sandboxCell = cell as? SandboxDisplayCell {
            sandboxCell.item = viewModel.datas[indexPath.row]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.datas.count else {
            return
        }
        let item = viewModel.datas[indexPath.row]
        if item.type == .file {
            showActionForFile(item.path)
        } else {
            viewModel.currentPath = item.path
        }
    }

    func setHeaderView() {
        tableView.tableHeaderView = (viewModel.isRootDic && Utils.isSimulator) ? copyBtn : nil
        tableView.tableHeaderView?.frame = CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: 60))
    }
    // MARK: - 按钮的点击
    @objc
    func popSelf() {
        if viewModel.isRootDic {
            self.navigationController?.popViewController(animated: true)
        } else {
            viewModel.lastHierarchy()
        }
    }

    @objc
    func shareBtnClick() {
        shareFileForPath(viewModel.currentPath)
    }

    @objc
    func copyPath() {
        UIPasteboard.general.string = NSHomeDirectory()
    }

    func shareFileForPath(_ path: String) {
        let activityVC = UIActivityViewController(activityItems: [NSURL(fileURLWithPath: path)],
                                                  applicationActivities: nil)
        self.present(activityVC, animated: false, completion: nil)
    }

    func showActionForFile(_ path: String) {
        let alert = UIAlertController(title: "请选择操作方式", message: nil, preferredStyle: .actionSheet)
        let previewAction = UIAlertAction(title: "本地预览", style: .default) { [weak self] _ in
            self?.pushToDetailVCWith(path: path)
        }
        let shareAction = UIAlertAction(title: "分享", style: .default) { [weak self] _ in
            self?.shareFileForPath(path)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(previewAction)
        alert.addAction(shareAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    func pushToDetailVCWith(path: String) {
        let vc = SandboxDetailIViewController(filePath: path)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
#endif
