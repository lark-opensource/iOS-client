//
//  CreateVoteViewController.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/3/21.
//

import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import EENavigator
import UniverseDesignColor
import UIKit
import RustPB
import LarkRustClient
import LarkSDKInterface
import LarkContainer
import LarkCore
import UniverseDesignToast
import LKCommonsLogging
import LKCommonsTracker
import Homeric

public let voteBlue: UIColor = UIColor.ud.primaryContentDefault
public let voteGray: UIColor = UIColor.ud.fillDisabled
// 最小选项数
public let leastOptionNum: Int = 2
// 最大选项数
public let mostOptionNum: Int = 50
// 主题最多字数
public let topicMaximumCharacterLimit = 60
// 选项最多字数
public let optionMaximumCharacterLimit = 120

final class CreateVoteViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    let disposeBag = DisposeBag()
    var tempDisposeBag = DisposeBag()
    private let logger = Logger.log("CreateVoteViewController")
    @ScopedInjectedLazy private var rustService: SDKRustService?
    // ui elements
    let tableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)
    private let submitBtn: UIButton = UIButton()
    private let checkBtn: UIButton = UIButton()
    private let bottomView: UIView = UIView()
    private var topicCell: CreateVoteTopicCell = CreateVoteTopicCell()
    private var optionCells: [CreateVoteOptionCell] = []
    private var addOptionCell: CreateVoteAddOptionCell = CreateVoteAddOptionCell()
    private var isMultipleCell: CreateVoteSwitchCell = CreateVoteSwitchCell()
    private var isRealNameCell: CreateVoteSwitchCell = CreateVoteSwitchCell()
    // params
    private var data: CreateVoteModel = CreateVoteModel()
    private var containerType: Vote_V1_VoteScopeContainerType
    private var scopeID: String
    private var topicObservable: Observable<Bool>?
    private var optionObservableList: [Observable<Bool>] = []
    private var tableHeight: Int = 0
    private var shouldRecoverKeyboard: Bool = false
    private var isDragging: Bool = false

    // MARK: init views
    private func initView() {
        view.addSubview(tableView)
        view.addSubview(bottomView)
        bottomView.addSubview(submitBtn)
        bottomView.addSubview(checkBtn)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.allowsSelection = false
        tableView.bounces = true
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: .leastNormalMagnitude))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: .leastNormalMagnitude))
        tableView.register(CreateVoteBaseCell.self, forCellReuseIdentifier: String(describing: CreateVoteBaseCell.self))
        tableHeight = 54 + 48 * (leastOptionNum + 3) + 12 * 3
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(view.safeAreaInsets.top)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(bottomView.snp.top)
        }
        tableView.backgroundColor = .clear
        bottomView.backgroundColor = .clear
        bottomView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.top.equalToSuperview().offset(tableHeight).priority(99)
            maker.height.greaterThanOrEqualTo(114).priority(100)
        }
        submitBtn.setBackgroundImage(UIImage.ud.fromPureColor(voteBlue), for: .normal)
        submitBtn.setBackgroundImage(UIImage.ud.fromPureColor(voteGray), for: .disabled)
        submitBtn.isEnabled = false
        submitBtn.setTitle(BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_Post_Button, for: .normal)
        submitBtn.setTitleColor(.white, for: .normal)
        submitBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        submitBtn.layer.cornerRadius = 6
        submitBtn.layer.masksToBounds = true
        tableHeight = 54 + 48 * (self.optionCells.count + 3) + 12 * 3
        submitBtn.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(24)
            maker.height.equalTo(48)
        }
        submitBtn.addTarget(self, action: #selector(submitVote), for: .touchUpInside)
        checkBtn.snp.makeConstraints { (maker) in
            maker.left.right.top.bottom.equalTo(submitBtn)
        }
        checkBtn.backgroundColor = .clear
        checkBtn.addTarget(self, action: #selector(checkContentEmpty), for: .touchUpInside)
    }

    private func initNavigation() {
        self.title = BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_Title
        addCloseItem()
    }

    private func initTableViewCell() {
        // 初始化主题Cell
        self.topicCell.updateCellBlock { [weak self] (text) in
            self?.data.topic = text?.trimmingCharacters(in: .whitespaces)
        }
        bindCheckEmptyEvent()
        // 初始化最少的投票选项Cell（最少2个选项）
        for _ in (1...leastOptionNum) {
            self.createOption()
        }
        // 初始化添加选项Cell
        self.addOptionCell.updateCellContent(text: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_Options_AddOptions_Button) { [weak self] () in
            self?.addOption()
        }
        // 初始化允许多选Cell
        self.isMultipleCell.updateCellContent(text: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_MultipleAnswers)
        // 初始化是否实名Cell
        self.isRealNameCell.updateCellContent(text: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_Anonymous)
        tableView.reloadData()
    }

    // cell数量变化时调整按钮位置
    private func adjustBottomView() {
        tableHeight = 54 + 48 * (self.optionCells.count + 3) + 12 * 3
        self.bottomView.snp.remakeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.height.greaterThanOrEqualTo(114).priority(100)
            maker.top.equalToSuperview().offset(self.tableHeight).priority(99)
        }
        self.view.layoutIfNeeded()
    }

    // 新建一个选项
    private func createOption() -> CreateVoteOptionCell {
        let index = self.optionCells.count
        let optionModel = CreateVoteOption(optionNumber: index, optionContent: "")
        self.data.options.append(optionModel)
        let optionCell = CreateVoteOptionCell()
        optionCell.updateCellContent(index: index)
        optionCell.updateCellBlock { [weak self] (idx) in
            self?.deleteOption(index: idx)
        } textChangeBlock: { [weak self] (text, idx) in
            guard let options = self?.data.options else { return }
            if idx < options.count {
                self?.data.options[idx].optionContent = text?.trimmingCharacters(in: .whitespaces)
            }
        }
        self.optionCells.append(optionCell)
        bindOptionCellTextField(cell: optionCell)
        changeOptionCellBtnStatus()
        let contentOffset = tableView.contentOffset
        adjustBottomView()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        tableView.setContentOffset(contentOffset, animated: false)
        return optionCell
    }

    // 添加选项
    private func addOption() {
        if self.data.options.count >= mostOptionNum {
            UDToast.showWarning(with: BundleI18n.LarkVote.Lark_IM_Poll_CreatePoll_TooManyOptions_Toast(mostOptionNum), on: self.view)
          return
        }
        let optionCell = createOption()
        optionCell.contentField.becomeFirstResponder()
    }

    // 删除选项
    private func deleteOption(index: Int) {
        self.optionCells.remove(at: index)
        adjustBottomView()
        tableView.reloadData()
        self.data.options.remove(at: index)
        self.optionObservableList.remove(at: index)
        bindCheckEmptyEvent()
        changeOptionCellBtnStatus()
        updateOptionIndex()
    }

    // 当选项大于2时，使删除行按钮可用
    private func changeOptionCellBtnStatus() {
        let enableOptionBtn = self.optionCells.count > 2
        for optionCell in self.optionCells {
            optionCell.changeOptionBtnStatus(isEnabled: enableOptionBtn)
        }
    }

    private func updateOptionIndex() {
        for (index, option) in self.data.options.enumerated() {
            option.optionNumber = index
        }
        for (index, cell) in self.optionCells.enumerated() {
            cell.index = index
        }
    }

    // 若存在重复选项则无法提交
    // 存在一对重复选项提示对应的两个选项序号
    // 存在多个/对重复选项则提示投票选项不能重复
    // 如果存在只有空格的选项提示投票选项不能为空
    private func checkOptions() -> Bool {
        var duplicatedDict: [String: [Int]] = [:]
        for (index, option) in self.data.options.enumerated() {
            guard let optionStr = option.optionContent else { continue }
            if optionStr.isEmpty {
                UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_NoEmptyOption_Toast, on: view)
                return false
            }
            if duplicatedDict[optionStr] == nil {
                duplicatedDict[optionStr] = [index]
            } else {
                duplicatedDict[optionStr]?.append(index)
            }
        }
        let dict = duplicatedDict.filter { (_, list) in
            if list.count > 1 {
                return true
            }
            return false
        }
        if dict.isEmpty {
            return true
        } else if dict.count == 1 {
            if let indexList = dict.first?.value {
                if indexList.count == 2 {
                    UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_Option1AndOption2AreTheSame_ErrorText(indexList[0] + 1, indexList[1] + 1, lang: nil), on: view)
                } else {
                    UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_MultipleDuplicateOptions_ErrorText, on: view)
                }
            }
        } else {
            UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_MultipleDuplicateOptions_ErrorText, on: view)
        }
        return false
    }

    // MARK: Rx Events
    private func bindCheckEmptyEvent() {
        // 创建新的disposeBag销毁之前的监听事件
        tempDisposeBag = DisposeBag()
        let topicVerify = getTopicCellTextField()
        var optionsVerify: Observable<Bool>
        optionsVerify = Observable.combineLatest(optionObservableList) { Elements in
            for e in Elements where e == false {
                return false
            }
            return true
        }
        optionsVerify.subscribe(onNext: { [weak self] isenabled in
            guard let self = self else { return }
            self.addOptionCell.isEnabled = isenabled
        })
        .disposed(by: tempDisposeBag)

        Observable.combineLatest(topicVerify, optionsVerify) { topicVerify, optionsVerify in
            return topicVerify && optionsVerify
        }
        .bind(to: submitBtn.rx.isEnabled)
        .disposed(by: tempDisposeBag)

        Observable.combineLatest(topicVerify, optionsVerify) { topicVerify, optionsVerify in
            return !(topicVerify && optionsVerify)
        }
        .bind(to: checkBtn.rx.isEnabled)
        .disposed(by: tempDisposeBag)
    }

    private func getTopicCellTextField() -> Observable<Bool> {
        let verifiInput = self.topicCell.contentField.rx.text.orEmpty.debug().asObservable()
            .map({ !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        return verifiInput
    }

    private func bindOptionCellTextField(cell: CreateVoteOptionCell) {
        let verifiInput = cell.contentField.rx.text.orEmpty.asObservable()
            .map({ !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
        self.optionObservableList.append(verifiInput)
        bindCheckEmptyEvent()
    }

    // MARK: Life Cycle
    let userResolver: UserResolver
    init(userResolver: UserResolver, containerType: Vote_V1_VoteScopeContainerType, scopeID: String) {
        self.userResolver = userResolver
        self.containerType = containerType
        self.scopeID = scopeID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        initNavigation()
        initView()
        initTableViewCell()
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(tap:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: Tap Event
    @objc
    func submitVote() {
        let verify = checkOptions()
        if !verify { return }
        self.data.minPickNum = 1
        if self.isMultipleCell.switchBtn.isOn {
            self.data.maxPickNum = self.data.options.count
        } else {
            self.data.maxPickNum = 1
        }
        self.data.isRealName = !self.isRealNameCell.switchBtn.isOn
        let request = self.data.transformModelToPB(containerType: self.containerType, scopeID: self.scopeID)
        let observer: Observable<RustPB.Vote_V1_PublishVoteResponse> = rustService?.sendAsyncRequest(request) ?? .empty()
        let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
        var bag = DisposeBag()
        observer.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                bag = DisposeBag()
                hud.remove()
                Tracker.post(TeaEvent(Homeric.IM_CHAT_VOTE_CREATE_CLICK, params: [
                    "click": "post",
                    "item_num": "\(self.data.options.count)",
                    "is_anonymous": "\(!self.data.isRealName)",
                    "vote_id": "\(response.voteID)",
                    "target": "none"]))
                self.dismiss(animated: true, completion: nil)
                self.logger.info("publish vote success, vote id : \(response.voteID)")
        }, onError: { [weak self] error in
            guard let self = self else { return }
            self.logger.info("publish vote error, error : \(error)")
            UDToast.showFailure(with: BundleI18n.LarkVote.Lark_IM_Poll_UnableToPostPollTryLater_ErrorText, on: self.view, error: error)
        }).disposed(by: bag)
    }

    @objc
    func checkContentEmpty() {
        guard let topicStr = self.data.topic else { return }
        if topicStr.isEmpty {
            UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_NoEmptyTitle_Toast, on: self.view)
        } else {
            UDToast.showTips(with: BundleI18n.LarkVote.Lark_IM_Poll_NoEmptyOption_Toast, on: self.view)
        }
    }

    @objc
    func viewTapped(tap: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    @objc
    func keyboardWillAppear(_ notification: NSNotification) {
        if let keyboardBounds = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if let firstResponse = self.view.lu.firstResponder(),
                let superView = firstResponse.superview,
                let window = firstResponse.window {
                let frame = superView.convert(firstResponse.frame, to: window)
                let keyboardHeight = keyboardBounds.height
                let showWindowHeight = UIScreen.main.bounds.height - keyboardHeight
                let offset: CGFloat = 75
                if frame.bottom + offset > showWindowHeight {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += frame.bottom + offset - showWindowHeight
                    self.tableView.setContentOffset(contentOffset, animated: true)
                    shouldRecoverKeyboard = true
                }
            }
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        // 滑动时不设置滚动，否则会有键盘卡顿问题
        if !isDragging, shouldRecoverKeyboard, tableView.contentOffset.y + tableView.frame.height > tableView.contentSize.height {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 3), at: .bottom, animated: true)
            shouldRecoverKeyboard = false
            isDragging = false
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            isDragging = true
            self.view.endEditing(true)
        } else {
            isDragging = false
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = VoteIndex(rawValue: section) else { return 0 }
        switch sectionType {
        case .topic, .isMultiple, .isAnonymous:
            return 1
        case .options:
            return optionCells.count + 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: CreateVoteBaseCell = CreateVoteBaseCell()
        guard let sectionType = VoteIndex(rawValue: indexPath.section) else { return cell }
        switch sectionType {
        case .topic:
            cell = topicCell
        case .options:
            if indexPath.row < optionCells.count {
                cell = optionCells[indexPath.row]
            } else {
                cell = addOptionCell
            }
        case .isMultiple:
            cell = isMultipleCell
        case .isAnonymous:
            cell = isRealNameCell
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sectionType = VoteIndex(rawValue: section) else { return 0 }
        switch sectionType {
        case .topic:
            return .leastNormalMagnitude
        default:
            return 12
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        return view
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        return view
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let sectionType = VoteIndex(rawValue: indexPath.section) else { return 0 }
        switch sectionType {
        case .topic:
            return 54
        default:
            return 48
        }
    }
}
