//
//  EventEmailAttendeeViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/4/8.
//

import UniverseDesignIcon
import RxSwift
import RxCocoa
import RoundedHUD
import LarkUIKit
import UIKit

/// 日程 - 邮件参与人编辑页

protocol EventEmailAttendeeViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventEmailAttendeeViewController)
    func didFinishEdit(from viewController: EventEmailAttendeeViewController, attendeeType: AttendeeType)
}

final class EventEmailAttendeeViewController: UIViewController {

    let viewModel: EventEmailAttendeeViewModel
    weak var delegate: EventEmailAttendeeViewControllerDelegate?

    private typealias UIStyle = EventEditUIStyle

    private let disposeBag = DisposeBag()
    private let cellReuseId = "Cell"
    private lazy var searchView = initSearchView()
    private lazy var tableView = initTableView()
    private lazy var suggestionView = initSuggestionView()

    init(viewModel: EventEmailAttendeeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_GoogleCal_AddEmailContacts
        setupView()
        setupNaviItem()
        setupViewModel()
        tableView.reloadData()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(searchView)
        searchView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }

        view.addSubview(suggestionView)
        suggestionView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }

        searchView.textField.addTarget(
            self,
            action: #selector(addAttendeeFromKeyboard),
            for: .editingDidEndOnExit
        )

        suggestionView.onClick = { [weak self] in
            self?.addAttendeeFromSuggestion()
        }
    }

    private func setupNaviItem() {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didCancelEdit(from: self)
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = cancelItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.delegate?.didFinishEdit(from: self, attendeeType: .normal)
            }.disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = doneItem
    }

    private func setupViewModel() {
        viewModel.onAllCellDataUpdate = { [weak self] in
            self?.tableView.reloadData()
        }

        // input
        searchView.textField.rx.text.orEmpty
            .bind(to: viewModel.rxInput)
            .disposed(by: disposeBag)

        // output
        viewModel.rxSuggestion
            .observeOn(MainScheduler.instance)
            .bind { [weak self] suggestion in
                guard let self = self else { return }
                self.suggestionView.suggestion = suggestion
                self.suggestionView.isHidden = suggestion.isEmpty
                self.tableView.isHidden = !self.suggestionView.isHidden
            }
            .disposed(by: disposeBag)
    }

    @objc
    private func addAttendeeFromKeyboard() {
        doAddAttendee()
        CalendarTracer.shareInstance.calAddEmailAttendee(from: .enter)
    }

    @objc
    private func addAttendeeFromSuggestion() {
        doAddAttendee()
        CalendarTracer.shareInstance.calAddEmailAttendee(from: .invite)
    }

    private func doAddAttendee() {
        searchView.textField.resignFirstResponder()
        if viewModel.addEmailAttendeeFromInput() {
            searchView.textField.text = nil
            viewModel.rxInput.accept("")
        }
    }
}

extension EventEmailAttendeeViewController {

    private func initSearchView() -> SearchView {
        let searchView = SearchView()
        searchView.isIconHidden = true
        return searchView
    }

    private func initSuggestionView() -> EventEmailSuggestionView {
        return EventEmailSuggestionView()
    }

    private func initTableView() -> UITableView {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .init(top: 0, left: 80, bottom: 0, right: 0)
        tableView.separatorColor = UIStyle.Color.horizontalSeperator
        tableView.register(EventEmailAttendeeCell.self, forCellReuseIdentifier: cellReuseId)
        return tableView
    }

}

extension EventEmailAttendeeViewController {

    fileprivate final class SearchView: UIView {
        var textField: UITextField = UITextField()
        var isIconHidden: Bool = false {
            didSet {
                iconView.isHidden = isIconHidden
                textField.snp.remakeConstraints {
                    $0.left.equalToSuperview().offset(8)
                    $0.top.bottom.equalToSuperview()
                    $0.right.equalToSuperview().offset(-5)
                }
            }
        }
        var onTextChanged: ((String) -> Void)?
        var onTextEditEnd: ((String) -> Void)?

        private var iconView: UIImageView = UIImageView()
        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = UIColor.ud.bgBody

            let contentView = UIView()
            contentView.backgroundColor = UIColor.ud.N100
            contentView.layer.cornerRadius = 4
            addSubview(contentView)
            contentView.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 12, bottom: 8, right: 12))
            }

            iconView.image = UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3)
            contentView.addSubview(iconView)
            iconView.snp.makeConstraints {
                $0.width.height.equalTo(20)
                $0.centerY.equalToSuperview()
                $0.left.equalToSuperview().offset(8)
            }

            textField.attributedPlaceholder = NSAttributedString(
                string: BundleI18n.Calendar.Calendar_GoogleCal_InputEmail,
                attributes: [.foregroundColor: UIColor.ud.textPlaceholder]
            )
            textField.font = UIFont.cd.regularFont(ofSize: 14)
            textField.textColor = UIColor.ud.N800
            textField.returnKeyType = .default
            textField.keyboardType = .emailAddress
            textField.clearButtonMode = .whileEditing
            contentView.addSubview(textField)
            textField.snp.makeConstraints {
                $0.left.equalToSuperview().offset(32)
                $0.top.bottom.equalToSuperview()
                $0.right.equalToSuperview().offset(-5)
            }
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: Self.noIntrinsicMetric, height: 48)
        }

    }

}

extension EventEmailAttendeeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseId, for: indexPath)
        if let cell = cell as? EventEmailAttendeeCell {
            cell.viewData = viewModel.cellData(at: indexPath.row)
            cell.deleteHandler = { [unowned self] in
                self.viewModel.deleteRow(at: indexPath.row)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = viewModel.sectionHeaderTitle() else {
            return nil
        }
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.bgBody

        let titleLabel = UILabel.cd.subTitleLabel(fontSize: 15)
        titleLabel.text = title
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.sectionHeaderTitle() != nil ? 44 : CGFloat.leastNormalMagnitude
    }

}
