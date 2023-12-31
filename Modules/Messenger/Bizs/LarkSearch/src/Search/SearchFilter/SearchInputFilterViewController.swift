//
//  SearchInputFilterViewController.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/10/6.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import RustPB
import EENavigator
import LarkSearchFilter
import LarkNavigator
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

final class SearchInputFilterViewController: BaseUIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    // 服务端是多选，暂时预留成多选
    var selectedTexts: [String] {
        didSet {
            updateSaveButtonTitle()
        }
    }

    let completion: ([String]) -> Void
    let bag = DisposeBag()

    private lazy var saveButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.contentHorizontalAlignment = .right
        return button
    }()

    let textFieldContainer: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        containerView.layer.cornerRadius = 6
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        return containerView
    }()

    let inputTextField: UITextField = {
        let inputTextField = UITextField()
        inputTextField.backgroundColor = UIColor.clear
        inputTextField.textColor = UIColor.ud.textTitle
        inputTextField.font = UIFont.ud.body0
        inputTextField.returnKeyType = .search
        return inputTextField
    }()

    let selectedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 6
        tableView.register(SearchInputFilterCell.self, forCellReuseIdentifier: "SearchInputFilterCell")
        return tableView
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    init(userResolver: UserResolver,
         title: String,
         selectedTexts: [String],
         completion: @escaping ([String]) -> Void) {
        self.userResolver = userResolver
        self.selectedTexts = selectedTexts
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSaveButtonTitle() {
        let countStr: String = !selectedTexts.isEmpty ? " (\(selectedTexts.count))" : ""
        self.saveButton.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure + countStr, for: .normal)
        self.saveButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.inputTextField.becomeFirstResponder()
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        addCancelItem()
        updateSaveButtonTitle()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)

        view.addSubview(textFieldContainer)
        inputTextField.delegate = self
        textFieldContainer.addSubview(inputTextField)
        selectedLabel.isHidden = true
        tableView.isHidden = true
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(selectedLabel)
        view.addSubview(tableView)

        textFieldContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(48)
            make.top.equalToSuperview().offset(8)
        }
        inputTextField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        selectedLabel.snp.makeConstraints { make in
            make.leading.equalTo(textFieldContainer.snp.leading).offset(16)
            make.trailing.equalTo(textFieldContainer)
            make.top.equalTo(textFieldContainer.snp.bottom).offset(16)
            make.height.equalTo(20)
        }
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(textFieldContainer)
            make.top.equalTo(selectedLabel.snp.bottom)
            make.height.equalTo(100)
        }
        self.tableView.rx.observe(CGSize.self, "contentSize")
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let maxHeight = self.tableViewMaxHeight()
                if maxHeight > 0 {
                    let height = min(self.tableView.contentSize.height, maxHeight)
                    self.tableView.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                }
            })
            .disposed(by: bag)
        selectedLabel.text = BundleI18n.LarkSearch.Lark_Search_EmailSearch_FiltersCommon_SelectSearchResults_Selected + (self.title ?? "")
        if !selectedTexts.isEmpty {
            selectedLabel.isHidden = false
            tableView.isHidden = false
        }
    }

    @objc
    func save() {
        inputTextField.resignFirstResponder()
        if let text = inputTextField.text, !text.isEmpty {
            selectedTexts = selectedTexts.filter { selected in
                !selected.elementsEqual(text)
            }
            selectedTexts.insert(text, at: 0)
        }
        completion(selectedTexts)
        closeBtnTapped()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedTexts.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchInputFilterCell", for: indexPath)
        guard let _cell = cell as? SearchInputFilterCell,
              let text = selectedTexts[safe: indexPath.row] else { return cell }
        _cell.updateCellContent(cellContent: text, index: indexPath.row, sumCount: selectedTexts.count) { index in
            self.selectedTexts.remove(at: index)
            self.tableView.reloadData()
            if self.selectedTexts.isEmpty {
                self.selectedLabel.isHidden = true
                self.tableView.isHidden = true
            }
        }
        return _cell
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.textFieldContainer.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.textFieldContainer.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        save()
        return true
    }

    private func tableViewMaxHeight() -> CGFloat {
        let topSafeHeight = UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0.0
        let bottomSafeHeight = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0.0
        let extraHeight = (topSafeHeight + bottomSafeHeight + 92)
        return view.frame.size.height - extraHeight
    }
}

final class SearchInputFilterCell: UITableViewCell {
    static var cellHeight: CGFloat = 48
    private let titleLabel = UILabel()
    private let deleteButton = UIButton()
    private let lineView = UIView()
    private var deleteAction: ((Int) -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        // 没有选中态
        selectionStyle = .none

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.ud.body0
        deleteButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 14, height: 14)), for: .normal)
        deleteButton.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(titleLabel)
        contentView.addSubview(deleteButton)
        contentView.addSubview(lineView)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(deleteButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.centerY.equalToSuperview()
        }
        lineView.snp.makeConstraints { make in
            make.height.equalTo(0.75)
            make.leading.equalToSuperview().offset(16)
            make.trailing.bottom.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        deleteButton.tag = -1
        deleteAction = nil
        lineView.isHidden = false
    }

    func updateCellContent(cellContent: String, index: Int, sumCount: Int, deleteAction: @escaping ((Int) -> Void)) {
        titleLabel.text = cellContent
        deleteButton.tag = index
        self.deleteAction = deleteAction
        if sumCount == index + 1 {
            lineView.isHidden = true
        }
    }

    @objc
    func tapAction() {
        if deleteButton.tag >= 0 {
            deleteAction?(deleteButton.tag)
        }
    }
}
