//
//  MinutesAddParticipantSearchViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import EENavigator
import LarkLocalizations
import UniverseDesignToast
import UniverseDesignIcon
import LarkContainer
import MinutesNetwork

protocol MinutesAddParticipantSearchViewControllerDelegate: AnyObject {
    func participantsInvited(_ controller: MinutesAddParticipantSearchViewController)
}

class MinutesAddParticipantSearchViewController: UIViewController {
    private let tracker: MinutesTracker
    // 标记是否是第一次唤起键盘
    private var firstActiveKeyboard: Bool = true

    public var shouldActiveKeyboardWhenEnter: Bool = false

    weak var delegate: MinutesAddParticipantSearchViewControllerDelegate?

    private var viewModel: MinutesAddParticipantSearchViewModel

    private lazy var closeBarButtonItem: UIBarButtonItem = {
        let image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))

        let item = UIBarButtonItem(image: image,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(onCloseBarButtonItem(_:)))
        return item
    }()

    private lazy var pickerToolBar: MinutesAddParticipantCollaboratorPickerBar = {
        let toolBar = MinutesAddParticipantCollaboratorPickerBar(frame: CGRect.zero)
        toolBar.setItems(toolBar.toolbarItems(), animated: false)
        toolBar.allowSelectNone = false
        toolBar.updateSelectedItem(firstSelectedItems: [], secondSelectedItems: [], updateResultButton: true)
        toolBar.barTintColor = UIColor.ud.bgBody
        return toolBar
    }()

    /// 已选择的协作者头像面板
    private lazy var avatarBar: AddParticipantCollaboratorAvatarBar = {
        let bar = AddParticipantCollaboratorAvatarBar()
        bar.delegate = self
        return bar
    }()

    private lazy var addNewAvatarBar: AddParticipantNewCollaboratorBar = {
        let bar = AddParticipantNewCollaboratorBar()
        bar.delegate = self
        return bar
    }()

    lazy var editView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.layer.cornerRadius = 6
        contentView.backgroundColor = UIColor.ud.bgBodyOverlay
        contentView.clipsToBounds = true
        return contentView
    }()

    lazy var searchTextField: MinutesAddParticipantSearchTextField = {
        let textField = MinutesAddParticipantSearchTextField.init(frame: CGRect.zero)
        textField.delegate = self
        textField.returnKeyType = .search
        textField.enablesReturnKeyAutomatically = true
        textField.placeholder = BundleI18n.Minutes.MMWeb_G_Search
        textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textField.textCleared = { [weak self] in
            self?.search(query: "")
            self?.updateAddNewAvatarBar()
        }
        return textField
    }()

    lazy var editViewBackground: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.backgroundColor = UIColor.ud.bgBody
        return contentView
    }()

    lazy var topSeparatorLineView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.backgroundColor = UIColor.ud.lineDividerDefault
        return contentView
    }()

    lazy var bottomSeparatorLineView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.backgroundColor = UIColor.ud.lineDividerDefault
        return contentView
    }()

    /// 协作者选择列表
    private(set) lazy var collaboratorSearchTableView: MinutesAddParticipantSearchResultView = {

        let viewModel = MinutesAddParticipantSearchResultViewModel(minutes: self.viewModel.minutes,
                                                         selectedItems: self.viewModel.selectedItems,
                                                         uuid: self.viewModel.participantAddUUID)
        let tableView = MinutesAddParticipantSearchResultView(resolver: userResolver, viewModel: viewModel)
        tableView.searchDelegate = self
        return tableView
    }()

    private var workItem: DispatchWorkItem?
    let userResolver: UserResolver
    
    init(resolver: UserResolver, minutes: Minutes) {
        userResolver = resolver
        viewModel = MinutesAddParticipantSearchViewModel(minutes: minutes)
        tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTextField.delegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.Minutes.MMWeb_G_AddParticipant

        navigationItem.leftBarButtonItems = [closeBarButtonItem]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.backgroundColor = UIColor.ud.bgBody
            navBarAppearance.shadowColor = nil
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
            navigationController?.navigationBar.standardAppearance = navBarAppearance
        } else {
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        navigationController?.navigationBar.layoutIfNeeded()
        self.view.backgroundColor = UIColor.ud.bgBase

        editView.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(34)
        }

        editViewBackground.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(34)
        }

        view.addSubview(editViewBackground)
        editViewBackground.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(42)
        }

        view.addSubview(avatarBar)
        avatarBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(editViewBackground.snp.bottom)
            make.height.equalTo(0)
        }

        view.addSubview(topSeparatorLineView)
        topSeparatorLineView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(avatarBar.snp.bottom)
            make.height.equalTo(0.5)
        }

        view.addSubview(addNewAvatarBar)
        addNewAvatarBar.isHidden = true
        addNewAvatarBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topSeparatorLineView.snp.bottom)
            make.height.equalTo(0)
        }

        view.addSubview(pickerToolBar)
        pickerToolBar.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(48)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        setupPickerToolBar()

        pickerToolBar.addSubview(bottomSeparatorLineView)
        bottomSeparatorLineView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        view.addSubview(collaboratorSearchTableView)
        collaboratorSearchTableView.snp.makeConstraints { (make) in
            make.top.equalTo(addNewAvatarBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(pickerToolBar.snp.top)
        }
        search(query: "")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if firstActiveKeyboard && shouldActiveKeyboardWhenEnter {
            self.firstActiveKeyboard = false
            self.searchTextField.becomeFirstResponder()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    @objc
    private func onCloseBarButtonItem(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    func search(query: String) {
        collaboratorSearchTableView.search(query: query)
    }

    func shouldSelect(userId: String) {
        collaboratorSearchTableView.shouldSelect(userId: userId)
    }

    private func setupPickerToolBar() {
        self.view.bringSubviewToFront(pickerToolBar)
        pickerToolBar.confirmButtonTappedBlock = { [weak self] _ in
            guard let self = self else { return }

            self.tracker.tracker(name: .detailClick, params: ["click": "participant_edit", "target": "none", "edit_type": "add_participant"])

            let participants = self.viewModel.selectedItems
            DispatchQueue.main.async {
                UDToast.showLoading(with: BundleI18n.Minutes.MMWeb_G_Loading, on: self.view)
            }
            self.viewModel.minutes.info.participantsAdd(catchError: true,
                                                        users: participants,
                                                        uuid: self.viewModel.participantAddUUID) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        UDToast.removeToast(on: self.view)
                        self.delegate?.participantsInvited(self)
                        self.dismiss(animated: true, completion: nil)
                    }
                case .failure(let error): break
                }
            }
        }
    }

    private func updateAvatarBar() {
        avatarBar.setImages(items: viewModel.selectedItems.map {
            var imageURL: URL? = $0.avatarURL
            return AddParticipantAvatarBarItem(id: $0.userID, imageURL: imageURL, image: nil)
        }, complete: { [weak self] in
            guard let bar = self?.avatarBar else { return }
            // 滚动到最后
            bar.setContentOffset(CGPoint(x: max(0, bar.contentSize.width - bar.bounds.size.width), y: 0),
                                 animated: true)
        })
        avatarBar.snp.updateConstraints({ (make) in
            make.height.equalTo(viewModel.selectedItems.isEmpty ? 0 : 48)
        })

        updateAddNewAvatarBar()
    }

    private func updateAddNewAvatarBar() {
        var topOffsetOfBar: CGFloat = 0
        var isEmpty = true
        if searchTextField.text?.isEmpty == false {
            topOffsetOfBar = 8
            isEmpty = false
            addNewAvatarBar.isHidden = false
            if let text = searchTextField.text {
                addNewAvatarBar.updateNewAvatarName(text)
            }
        } else {
            addNewAvatarBar.isHidden = true
            addNewAvatarBar.updateNewAvatarName("")
        }

        addNewAvatarBar.snp.updateConstraints({ (make) in
            make.top.equalTo(topSeparatorLineView.snp.bottom).offset(isEmpty ? 0 : topOffsetOfBar)
            make.height.equalTo(isEmpty ? 0 : 52)
        })

        var topOffsetOfTable: CGFloat = topOffsetOfBar
        if viewModel.selectedItems.isEmpty == false {
            topOffsetOfTable = 8
        }

        collaboratorSearchTableView.snp.updateConstraints { (make) in
            make.top.equalTo(addNewAvatarBar.snp.bottom).offset(topOffsetOfTable)
        }
    }

    private func updatePickerToolBar() {
        pickerToolBar.updateSelectedItem(firstSelectedItems: viewModel.selectedItems,
                                         secondSelectedItems: [],
                                         updateResultButton: true)
    }

    private func updateSearchResultView() {
        collaboratorSearchTableView.updateSelectItems(viewModel.selectedItems)
    }
}

extension MinutesAddParticipantSearchViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if !text.isEmpty {
                self.searchTextField.resignFirstResponder()
                return true
            }
        }
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.workItem?.cancel()

        guard let text = textField.text, let textRange = Range(range, in: text) else {
            return true
        }

        let updatedText = text.replacingCharacters(in: textRange, with: string)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else {
                return
            }
            self.search(query: updatedText)
            self.updateAddNewAvatarBar()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)

        self.workItem = workItem
        return true
    }
}

extension MinutesAddParticipantSearchViewController: MinutesAddParticipantSearchResultViewDelegate {

    func collaboratorSearched(_ view: MinutesAddParticipantSearchResultView, didUpdateWithSearchResults searchResults: [Participant]?) {
    }

    func collaboratorInvited(_ view: MinutesAddParticipantSearchResultView, invitedItem: Participant) {
        viewModel.selectedItems.append(invitedItem)
        updateAvatarBar()
        updatePickerToolBar()
    }

    func collaboratorRemoved(_ view: MinutesAddParticipantSearchResultView, removedItem: Participant) {
        guard let index = viewModel.selectedItems.firstIndex(where: { (collaborator) -> Bool in
            return collaborator.userID == removedItem.userID
        }) else { return }
        viewModel.selectedItems.remove(at: index)
        updateAvatarBar()
        updatePickerToolBar()
    }

    func blockedCollaboratorInvited(_ view: MinutesAddParticipantSearchResultView, invitedItem: Participant) {

    }
}

// MARK: - CollaboratorAvatarBar
extension MinutesAddParticipantSearchViewController: AddParticipantCollaboratorAvatarBarDelegate {
    func avatarBar(_ bar: AddParticipantCollaboratorAvatarBar, didSelectAt index: Int) {
        guard index >= 0, index < viewModel.selectedItems.count else { return }
        let item = viewModel.selectedItems[index]
        // 点击头像去掉选择的
        if let index = viewModel.selectedItems.firstIndex(where: { $0.userID == item.userID }) {
            viewModel.selectedItems.remove(at: index)
            updateAvatarBar()
            updatePickerToolBar()
            updateSearchResultView()
        } else {
            MinutesLogger.record.error("out of range")
        }
    }
}

// MARK: - CollaboratorAvatarBar
extension MinutesAddParticipantSearchViewController: AddParticipantNewCollaboratorBarDelegate {
    func newAvatarBar(_ bar: AddParticipantNewCollaboratorBar, didAddNew: String) {
        MinutesSearchLoadingView.showLoad()
        viewModel.minutes.info.participantSearchAdd(catchError: true, userName: didAddNew, uuid: viewModel.participantAddUUID) { [weak self] result in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    MinutesSearchLoadingView.dissmissLoad()
                    self.collaboratorInvited(self.collaboratorSearchTableView, invitedItem: response)
                case .failure(let error):
                    MinutesSearchLoadingView.dissmissLoad()
                    self.tracker.tracker(name: .popupView, params: ["popup_name": "violative_participant_name"])
                    UIApplication.shared.keyWindow?.endEditing(true)
                }
            }
        }
    }
}
