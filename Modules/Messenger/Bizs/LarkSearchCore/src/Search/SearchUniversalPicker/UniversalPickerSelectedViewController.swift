//
//  UniversalPickerSelectedViewController.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/9/13.
//

import UIKit
import RxSwift
import LarkUIKit
import Foundation
import LarkSDKInterface
import LarkMessengerInterface

public final class UniversalPickerSelectedViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let completion: (UIViewController) -> Void

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let confirmTitle: String
    private let pickType: UniversalPickerType
    private var isFirstEnter: Bool

    private weak var delegate: SelectedViewControllerDelegate?

    private let disposeBag = DisposeBag()

    public init(delegate: SelectedViewControllerDelegate, confirmTitle: String, pickType: UniversalPickerType, isFirstEnter: Bool, completion: @escaping (UIViewController) -> Void) {
        self.delegate = delegate
        self.completion = completion
        self.confirmTitle = confirmTitle
        self.pickType = pickType
        self.isFirstEnter = isFirstEnter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // nolint: duplicated_code 不同业务不同的初始化方法
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.confirmButton)
        self.confirmButton.isEnabled = true
        if let delegate = self.delegate {
            self.navigationItem.titleView = PickerNavigationTitleView(
                title: BundleI18n.LarkSearchCore.Lark_Groups_MobileYouveSelected,
                observable: delegate.selectedObservable,
                initialValue: delegate.selected,
                shouldDisplayCountTitle: false
            )
            self.updateConfirmItem(count: delegate.selected.count)
        }

        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = 64
        tableView.register(UniversaPickerSelectedTableViewCell.self, forCellReuseIdentifier: "UniversaPickerSelectedTableViewCell")
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = self.view.bounds
        tableView.reloadData()
        self.delegate?.selectedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] selected in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.updateConfirmItem(count: selected.count)
            }).disposed(by: disposeBag)
    }
    // enable-lint: duplicated_code

    private lazy var confirmButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didConfirm), for: .touchUpInside)
        button.setTitle(self.confirmTitle, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.fillDisable, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()

    func updateConfirmItem(count: Int) {
        var title = BundleI18n.LarkSearchCore.Lark_Legacy_Sure
        if count >= 1 {
            title = BundleI18n.LarkSearchCore.Lark_Legacy_Sure + "(\(count))"
        }
        self.confirmButton.setTitle(title, for: .normal)
    }

    @objc
    func didConfirm(_ button: UIButton) {
        self.completion(self)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.selected.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UniversaPickerSelectedTableViewCell") as? UniversaPickerSelectedTableViewCell,
              let selected = delegate?.selected[indexPath.row] as? ForwardItem else {
            assertionFailure()
            return UITableViewCell()
        }
        cell.setContent(model: selected,
                        pickType: self.pickType,
                        tapHandler: { [weak self] in
                                        guard let self = self else { return }
                                        self.delegate?.deselect(option: selected, from: self)
                                    })
        return cell
    }
}
