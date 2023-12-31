//
//  IMMentionSelectedViewController.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/26.
//

import UIKit
import Foundation
import UniverseDesignIcon
import RxSwift

final class IMMentionSelectedViewController: UIViewController {
    private let disposeBag = DisposeBag()
    var headerView = IMMentionHeaderView()
    var tableView = UITableView()
    var items: [IMMentionOptionType] = []
    weak var formVC: IMMentionViewController?
    var store: SelectedItemStore
 
    var didDeselectItemHandler: ((IMMentionOptionType) -> Void)?
    private var headerHeight: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        setupHeaderUI()
        setupHeaderAction()
    }
    
    init(store: SelectedItemStore, from: IMMentionViewController) {
        self.store = store
        formVC = from
        super.init(nibName: nil, bundle: nil)
        setupTableView()
        store.items.subscribe { [weak self] in
                self?.items = $0
                self?.tableView.reloadData()
                self?.updateSelectedCount(numbers: $0.count)
            }.disposed(by: disposeBag)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHeaderUI() {
        self.view.addSubview(headerView)
        if self.traitCollection.horizontalSizeClass == .regular {
            headerView.lineView.isHidden = true
            headerHeight = 48
        }
        headerView.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
            $0.height.equalTo(headerHeight)
        }
        headerView.changeToLeftBtn()
        headerView.titleLabel.text = BundleI18n.LarkIMMention.Lark_IM_SelectedMentions_Title
    }
    
    private func setupHeaderAction() {
        headerView.closeBtn.addTarget(self, action: #selector(closeView), for: .touchUpInside)
        headerView.multiBtn.addTarget(self, action: #selector(finish), for: .touchUpInside)
        if self.traitCollection.horizontalSizeClass != .regular {
            headerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:))))
        }
    }
    
    @objc private func closeView() {
        self.navigationController?.popViewController(animated: false)
    }
    
    @objc private func finish() {
        formVC?.selectFinish()
    }
    
    @objc private func deleteItem(btn: UIButton) {
        var row: Int = btn.tag
        let item = items[row]
        store.toggleItemSelected(item: item)
        didDeselectItemHandler?(item)
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .changed:
            let changeY = pan.translation(in: self.view).y
            if changeY > 0 {
                formVC?.changePanelHeight(changeY: changeY, state: pan.state)
            }
        case .ended:
            let changeY = pan.translation(in: self.view).y
            formVC?.changePanelHeight(changeY: changeY, state: pan.state)
        default:
            break
        }
    }
    
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.rowHeight = 68
        tableView.lu.register(cellSelf: IMMentionItemCell.self)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func updateSelectedCount(numbers: Int) {
        if numbers == 0 {
            headerView.multiBtn.isUserInteractionEnabled = false
            headerView.multiBtn.alpha = 0.4
            headerView.multiBtn.setTitleColor(UIColor.ud.N400, for: .normal)
            headerView.multiBtn.setTitleColor(UIColor.ud.N400, for: .selected)
            headerView.multiBtn.setTitle(BundleI18n.LarkIMMention.Lark_Legacy_Sure, for: .normal)
        } else {
            headerView.multiBtn.isUserInteractionEnabled = true
            headerView.multiBtn.alpha = 1
            headerView.multiBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            headerView.multiBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
            headerView.multiBtn.setTitle("\(BundleI18n.LarkIMMention.Lark_Legacy_Sure)(\(numbers))", for: .normal)
        }
    }
}

extension IMMentionSelectedViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: IMMentionItemCell.self), for: indexPath)
        if let mentionCell = cell as? IMMentionItemCell {
            mentionCell.node = MentionItemNode(item: items[indexPath.row])
            mentionCell.setDeleteBtn()
            mentionCell.deleteBtn.tag = indexPath.row
            mentionCell.deleteBtn.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadData()
    }
}
