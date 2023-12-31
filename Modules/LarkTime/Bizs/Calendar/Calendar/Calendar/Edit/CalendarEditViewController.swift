//
//  CalendarEditViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/10/23.
//

import Foundation
import FigmaKit
import RxSwift
import LarkUIKit
import UniverseDesignButton
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignIcon

class CalendarEditViewController: UIViewController {

    let viewModel: CalendarEditViewModel
    private let disposeBag = DisposeBag()

    /// View Hierarchy:
    /// |---containerView (self.view)
    ///     |---rootView
    ///         |---CalendarEditSectionView
    ///             |---summaryView
    ///             |---attendeeView
    ///             |---....
    ///         |---CalendarEditSectionView
    ///             |---addMembersButton
    ///             |---CalendarEditMemberCell
    ///         |---...
    ///         |---footer
    private let rootView = UIScrollView()

    private let avatarCell = CalendarEditBasicCell()
    private let titleCell = CalendarEditBasicCell()
    private let colorCell = CalendarEditBasicCell()
    private let descriptionCell = CalendarEditBasicCell()

    private let authInOrgCell = CalendarEditBasicCell()
    private let authOutOfOrgCell = CalendarEditBasicCell()

    private let addMembersButton = CalendarEditAddButton()
    private let membersSection = CalendarEditSectionView(title: I18n.Calendar_Setting_SharingUsers)

    private let unSubscribeButton = CalendarEditOperationButton()
    private let deleteButton = CalendarEditOperationButton()
    private let actionsSection = CalendarEditSectionView()

    private let fullScreenCloseButton = UIButton(type: .custom)
    private let fullScreenTipView = PlaceHolderIconLabelView()
    private let loadingView = LoadingPlaceholderView()
    private let failedRetryView = LoadFaildRetryView()

    private var isNavigationBarHidden = true {
        didSet {
            self.navigationController?.setNavigationBarHidden(isNavigationBarHidden, animated: false)
            if !isNavigationBarHidden {
                (self.navigationController as? LkNavigationController)?.update(style: .custom(.ud.bgBase))
            }
        }
    }

    init(viewModel: CalendarEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setUpNavi()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpDecorations()

        bindViews()
        bindViewActions()
        bindViewResponses()

        viewModel.trace(.viewAppear)
    }

    private func setUpNavi() {
        let isFromCreate = viewModel.input.isFromCreate
        title = isFromCreate ? I18n.Calendar_Setting_NewCalendar : I18n.Calendar_Setting_CalendarSetting

        let leftItem = LKBarButtonItem(title: I18n.Calendar_Common_Cancel)
        leftItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.handleLeftBtnClick()
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = leftItem

        let rightItem = LKBarButtonItem(title: I18n.Calendar_Common_Save, fontStyle: .medium)
        rightItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.handleRightBtnClick()
            }.disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = rightItem
    }

    private func setUpViews() {
        view.backgroundColor = UIColor.ud.bgBase

        rootView.showsVerticalScrollIndicator = false
        rootView.contentInsetAdjustmentBehavior = .never
        rootView.alwaysBounceVertical = true
        view.addSubview(rootView)
        rootView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        // Assemble Views
        let basicInfosSection = CalendarEditSectionView(title: I18n.Calendar_Manage_BasicInfo)
        basicInfosSection.reFillWith(contents: [avatarCell, titleCell, colorCell, descriptionCell])

        let authSettingsSection = CalendarEditSectionView(title: I18n.Calendar_Share_SharingPermissions)
        authSettingsSection.reFillWith(contents: [authInOrgCell, authOutOfOrgCell])
        authSettingsSection.isHidden = !viewModel.permission.isPermissionEditable

        addMembersButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        let container = UIStackView(arrangedSubviews: [basicInfosSection, authSettingsSection, membersSection, actionsSection])
        container.axis = .vertical
        container.spacing = 24
        rootView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.width.equalToSuperview().offset(-32)
            make.top.bottom.equalToSuperview().inset(14)
            make.centerX.equalToSuperview()
        }

        unSubscribeButton.setTitle(with: I18n.Calendar_Detail_UnsubscribeButton, color: .ud.textTitle)
        unSubscribeButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        deleteButton.setTitle(with: I18n.Calendar_Detail_DeleteCalendar_Button, color: .ud.functionDangerContentDefault)
        deleteButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    private func setUpDecorations() {
        loadingView.text = I18n.Calendar_Common_LoadingCommon
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(failedRetryView)
        failedRetryView.backgroundColor = .ud.bgBase
        failedRetryView.retryAction = { [weak self] in
            let calID = self?.viewModel.rxCalendar.value.pb.serverID ?? ""
            self?.viewModel.fetchCalendar(with: calID)
        }
        failedRetryView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(fullScreenTipView)
        fullScreenTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let closeIcon = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1)
        fullScreenCloseButton.setImage(closeIcon, for: .normal)
        fullScreenCloseButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(fullScreenCloseButton)
        fullScreenCloseButton.snp.makeConstraints {
            $0.size.equalTo(CalendarUI.closeIconSize)
            $0.leading.equalTo(16)
            $0.top.equalTo(CalendarUI.closeIconY)
        }
    }

    private func bindViews() {
        // navi
        viewModel.rxAbleToSave
            .distinctUntilChanged()
            .subscribeForUI(onNext: { [weak self] ableToSave in
                guard let savingItem = self?.navigationItem.rightBarButtonItem as? LKBarButtonItem else { return }
                savingItem.button.tintColor = ableToSave ? .ud.primaryContentDefault : .ud.textDisabled
            }).disposed(by: disposeBag)

        // basic info
        viewModel.rxAvatarViewData.bind(to: avatarCell).disposed(by: disposeBag)
        viewModel.rxTitleViewData.bind(to: titleCell).disposed(by: disposeBag)
        viewModel.rxColorViewData.bind(to: colorCell).disposed(by: disposeBag)
        viewModel.rxDescriptionViewData.bind(to: descriptionCell).disposed(by: disposeBag)

        viewModel.rxAuthInGroupViewData.bind(to: authInOrgCell).disposed(by: disposeBag)
        viewModel.rxAuthOutOfGroupViewData.bind(to: authOutOfOrgCell).disposed(by: disposeBag)

        // permission
        let permission = viewModel.permission
        deleteButton.isHidden = !permission.isDeleteable
        unSubscribeButton.isHidden = !permission.isUnsubscriable
        actionsSection.reFillWith(contents: [unSubscribeButton, deleteButton].filter { !$0.isHidden }, isButtonSection: true)

        // members
        viewModel.rxMembersSectioinData
            .subscribeForUI { [weak self] sectionData in
                guard let self = self else { return }
                var sectionCells = sectionData.members.map { memberData -> UIView in
                    let memberCell = CalendarEditMemberCell()
                    memberCell.setUp(with: memberData)
                    memberCell.delegate = self
                    return memberCell
                }

                if sectionData.isCalMemberEditable { sectionCells.insert(self.addMembersButton, at: 0) }

                self.membersSection.reFillWith(contents: sectionCells, footer: sectionData.footerStr)
            }.disposed(by: disposeBag)
    }

    private func bindViewActions() {
        avatarCell.onClick = { [weak self] needBlock in
            guard let self = self else { return }
            guard !needBlock else {
                self.viewModel.rxToastStatus.accept(.tips(I18n.Calendar_Detail_NoPermitEditHover))
                return
            }
            self.viewModel.calendarDependency?
                .jumpToSelectAndUploadImage(from: self, anchorView: self.avatarCell) { [weak self] (key, image) in
                    self?.viewModel.updateAvatar(with: key, image: image)
                }
        }

        titleCell.onClick = { [weak self] _ in
            guard let self = self else { return }
            let title = self.viewModel.rxCalendar.value.pb.summary
            let canEdit = self.viewModel.permission.isCalSummaryEditable
            let titleEditVC = TitleEditViewController(text: title, canEdit: canEdit)
            titleEditVC.finishEdit = { [weak self] title in
                self?.viewModel.updateSummary(with: title)
            }
            self.navigationController?.pushViewController(titleEditVC, animated: true)
        }

        colorCell.onClick = { [weak self] needBlock in
            // color 目前都可编辑
            guard let self = self, !needBlock else { return }
            let index = self.viewModel.rxCalendar.value.pb.personalizationSettings.colorIndex.rawValue
            let pickerVC = ColorEditViewController(selectedIndex: index)
            pickerVC.colorSelectedHandler = { [weak self] index in
                self?.viewModel.updateColor(with: index)
            }
            self.navigationController?.pushViewController(pickerVC, animated: true)
        }

        descriptionCell.onClick = { [weak self] _ in
            guard let self = self else { return }
            let description = self.viewModel.rxCalendar.value.pb.description_p
            let canEdit = self.viewModel.permission.isDescEditable
            let vc = DescriptionEditViewController(text: description, canEdit: canEdit)
            vc.finishEdit = { [weak self] description in
                self?.viewModel.updateDescription(with: description)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }

        authInOrgCell.onClick = { [weak self] needBlock in
            guard !needBlock else {
                self?.viewModel.rxToastStatus.accept(.tips(I18n.Calendar_Setting_NoChangePermitAllStaff))
                return
            }

            guard let authVM = self?.viewModel.defaultAuthSettingVM else { return }
            let vc = DefaultAuthSettingViewController(of: .inner, viewModel: authVM)
            vc.settingSelectedHandler = { [weak self] settings in
                self?.viewModel.updateAuthSettings(with: settings, type: .inner)
                let authValue = settings.defaultShareOption.cd.shareOptionTracerDesc
                self?.viewModel.trace(.editInnerAuth(authValue: authValue))
            }
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        authOutOfOrgCell.onClick = { [weak self] needBlock in
            guard !needBlock else {
                self?.viewModel.rxToastStatus.accept(.tips(I18n.Calendar_Setting_NoChangePermitAllStaff))
                return
            }

            guard let authVM = self?.viewModel.defaultAuthSettingVM else { return }
            let vc = DefaultAuthSettingViewController(of: .external, viewModel: authVM)
            vc.settingSelectedHandler = { [weak self] settings in
                self?.viewModel.updateAuthSettings(with: settings, type: .external)
                let authValue = settings.crossDefaultShareOption.cd.shareOptionTracerDesc
                self?.viewModel.trace(.editExternalAuth(authValue: authValue))
            }
            self?.navigationController?.pushViewController(vc, animated: true)
        }

        // Buttons
        addMembersButton.onClick = { [weak self] in
            self?.handleAddMembersBtnClick()
        }

        unSubscribeButton.onClick = { [weak self] in
            self?.viewModel.unsubscribe()
        }

        deleteButton.onClick = { [weak self] in
            self?.viewModel.delete()
            self?.viewModel.trace(.deleteCalendar)
        }

        #if !LARK_NO_DEBUG
        addDebugGesture()
        #endif
    }

    private func bindViewResponses() {
        viewModel.rxToastStatus
            .bind(to: rx.toast).disposed(by: disposeBag)

        viewModel.rxAlert
            .subscribeForUI(onNext: { [weak self] alert in
                guard let self = self else { return }
                switch alert {
                case .deleteConfirm(let doAlert):
                    EventAlert.showDeleteOwnedCalendarAlert(controller: self, confirmAction: doAlert)
                    CalendarTracerV2.CalendarDeleteConfirm.traceView {
                        $0.calendar_id = self.viewModel.modelTupleBeforeEditing.calendar.serverID
                    }
                case .successorUnsubscribe(let doUnsubscribe, let delete):
                    let pop = UDActionSheet(config: UDActionSheetUIConfig(style: .normal, isShowTitle: true))
                    pop.setTitle(BundleI18n.Calendar.Calendar_Detail_UnsubscribeResignedPersonCalendar)
                    pop.addDefaultItem(text: I18n.Calendar_Detail_UnsubscribeButton, action: doUnsubscribe)
                    pop.addDestructiveItem(text: BundleI18n.Calendar.Calendar_Detail_DeleteCalendar, action: delete)
                    pop.setCancelItem(text: BundleI18n.Calendar.Calendar_Common_Cancel)
                    self.present(pop, animated: true, completion: nil)
                case .comfirmAlert(let title, let content):
                    let dialog = UDDialog(config: UDDialogUIConfig())
                    dialog.setTitle(text: title)
                    dialog.setContent(text: content)
                    dialog.addPrimaryButton(text: I18n.Calendar_Common_GotIt)
                    self.present(dialog, animated: true)
                case .ownedCalUnsubAlert(let doUnsubscribe):
                    EventAlert.showUnsubscribeOwnedCalendarAlert(controller: self, confirmAction: doUnsubscribe)
                }
            }).disposed(by: disposeBag)

        viewModel.rxDismissNoti
            .subscribeForUI { [weak self] _ in
                self?.dismiss(animated: true)
            }.disposed(by: disposeBag)

        viewModel.rxViewStatus
            .subscribeForUI { [weak self] status in
                guard let self = self else { return }
                // reset
                self.failedRetryView.isHidden = true
                self.fullScreenTipView.isHidden = true
                self.loadingView.isHidden = true

                switch status {
                case .loading:
                    self.loadingView.isHidden = false
                    self.isNavigationBarHidden = true
                case .error(let errorType):
                    if case .fetchError = errorType {
                        self.failedRetryView.isHidden = false
                    }
                    if case .apiError(let errorInfo) = errorType {
                        self.fullScreenTipView.isHidden = false
                        self.fullScreenTipView.image = errorInfo.definedType.defaultImage()
                        self.fullScreenTipView.title = errorInfo.tip
                        CalendarBiz.detailLogger.error(errorInfo.tip)
                    }
                    self.isNavigationBarHidden = true
                case .dataLoaded:
                    self.fullScreenCloseButton.isHidden = true
                    self.isNavigationBarHidden = false
                }
            }.disposed(by: disposeBag)
    }

    private func handleLeftBtnClick() {
        if viewModel.modelTupleBeforeEditing.calendar == viewModel.rxCalendar.value.pb,
           viewModel.modelTupleBeforeEditing.members == viewModel.rxCalendarMembers.value {
            dismiss(animated: true, completion: nil)
        } else {
            EventAlert.showDismissModifiedCalendarAlert(controller: self) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }

    private func handleRightBtnClick() {
        guard !viewModel.isSaving else { return }
        viewModel.save()

        let originCalendar = viewModel.modelTupleBeforeEditing.calendar
        let editedCalendar = viewModel.rxCalendar.value.pb
        let titleChanged = originCalendar.summary != editedCalendar.summary
        let descChanged = originCalendar.description_p != editedCalendar.description_p

        viewModel.trace(.save(isTitleAlias: titleChanged.description, isDescAlias: descChanged.description))
    }

    private func handleAddMembersBtnClick() {
        viewModel.calendarDependency?
            .jumpToCalendarMemberSelectorController(
                from: self,
                pickerDelegate: self,
                naviConfig: (I18n.Calendar_ChatFindTime_ChooseMember, I18n.Calendar_Common_Confirm),
                searchPlaceHolder: I18n.Calendar_Common_Search,
                preSelectMembers: viewModel.preSelectedMembers
            )
        viewModel.trace(.addShareMember)
    }

    @objc
    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if !LARK_NO_DEBUG
// MARK: 编辑页便捷调试
extension CalendarEditViewController: ConvenientDebug {
    func addDebugGesture() {
        guard FG.canDebug else { return }
        self.view.rx.gesture(Factory<UILongPressGestureRecognizer> { _, _ in })
            .when([.began])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showActionSheet(debugInfo: self.viewModel, in: self)
            })
            .disposed(by: disposeBag)
    }
}
#endif
