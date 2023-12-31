//
//  LiveSettingsViewController.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/3/24.
//

import Foundation
import RxSwift
import RxCocoa
import RichLabel
import RxDataSources
import Action
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import UIKit
import UniverseDesignIcon

final class LiveSettingsCell: UITableViewCell {

    private weak var embeddedView: UIView?
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var line: UIView = {
        let view = UIView()
        return view
    }()

    var showsLine: Bool {
        get {
            return !line.isHidden
        }
        set {
            line.isHidden = !newValue
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
        updateLayout()

        line.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.equalTo(containerView.snp.left)
            make.right.equalTo(containerView.snp.right)
            make.bottom.equalToSuperview()
            make.height.equalTo(1.0 / self.vc.displayScale)
        }
        line.isHidden = true
        self.line = line
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateLayout()
    }

    private func updateLayout() {
        containerView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
    }

    override func prepareForReuse() {
        setEmbeddedView(nil)
        super.prepareForReuse()
    }

    func setEmbeddedView(_ view: UIView?) {
        embeddedView?.removeFromSuperview()

        if let view = view {
            containerView.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            embeddedView = view
        }
    }

}

final class LiveSettingsViewController: VMViewController<LiveSettingsViewModel>, UITableViewDelegate {

    enum Layout {
        static let buttonPortraintLeft: CGFloat = 16
        static let buttonPortraintHeight: CGFloat = 48
        static let buttonLandscapeWidth: CGFloat = 494
        static let buttonLandscapeHeight: CGFloat = 40
        static let buttonGapToLegal: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 30
        static let legalPortraintBottom: CGFloat = 30
        static let legalLandscapeBottom: CGFloat = 18
    }

    private var lastBounds: CGRect?

    // 指引
    weak var guideView: GuideView?
    lazy var viewForGuide: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    private let viewFirstAppearRelay = PublishRelay<Void>()
    private let liveInfoForLayoutRelay = PublishRelay<Void>()

    var layoutCollection: ChoicesCollectionView<LiveLayout>?

    // NOTE: 静态表视图，未使用复用池
    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    private lazy var liveButton: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10
        button.addInteraction(type: .lift)
        return button
    }()

    private lazy var legalLabel: LKLabel = {
        let label = LKLabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.isHidden = true
        return label
    }()

    private lazy var byteLiveLegalView = {
        let view = LiveSettingLegalView()
        view.isHidden = true
        return view
    }()

    lazy var pickedCollection: LiveSettingPickedView = {
        let view = LiveSettingPickedView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0))
        view.isHidden = true
        view.delegate = self
        return view
    }()

    var pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?

    private var dataSource: RxTableViewSectionedReloadDataSource<LiveSettingsSectionModel>?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func setupViews() {
        title = I18n.View_M_LivestreamSettings
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(bottomView)
        bottomView.addSubview(bottomLine)
        bottomView.addSubview(liveButton)
        bottomView.addSubview(legalLabel)
        bottomView.addSubview(byteLiveLegalView)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalTo(liveButton.snp.top).offset(-8)
        }
        hideTopTableViewHeader()
        layoutBottomSubview()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNavigationBarBgColor(UIColor.ud.bgFloatBase)
        setNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let action = guideView?.sureAction {
            action(.plain(content: ""))
        }
    }

    deinit {
    }

    private func layoutBottomSubview() {
        let insets = VCScene.safeAreaInsets
        let compactLayout = VCScene.rootTraitCollection?.horizontalSizeClass ?? traitCollection.horizontalSizeClass == .compact
        bottomView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(120 + insets.bottom)
        }
        bottomLine.snp.remakeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        // 手机横屏布局规则等于竖屏，因此无需判断是否为横竖屏
        if Display.phone || compactLayout {
            self.liveButton.snp.remakeConstraints { (make) in
                make.left.equalTo(Layout.buttonPortraintLeft + insets.left)
                make.right.equalTo(-(Layout.buttonPortraintLeft + insets.right))
                make.height.equalTo(Layout.buttonPortraintHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-Layout.buttonBottomPadding)
            }
            self.legalLabel.snp.remakeConstraints { (make) in
                make.left.right.equalTo(self.liveButton)
                make.top.equalTo(self.liveButton.snp.bottom).offset(12)
            }
            byteLiveLegalView.snp.remakeConstraints { (make) in
                make.left.greaterThanOrEqualTo(self.liveButton)
                make.centerX.equalToSuperview()
                make.top.equalTo(self.liveButton.snp.bottom).offset(6)
            }
        } else {
            self.liveButton.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.width.equalTo(Layout.buttonLandscapeWidth)
                make.height.equalTo(Layout.buttonLandscapeHeight)
                make.bottom.equalTo(self.legalLabel.snp.top).offset(-Layout.buttonGapToLegal)
            }
            self.legalLabel.snp.remakeConstraints { (make) in
                make.left.right.equalTo(self.liveButton)
                make.bottom.equalTo(-(Layout.legalLandscapeBottom + insets.bottom))
            }
            byteLiveLegalView.snp.remakeConstraints { (make) in
                make.left.greaterThanOrEqualTo(self.liveButton)
                make.centerX.equalToSuperview()
                make.bottom.equalTo(-(Layout.legalLandscapeBottom + insets.bottom))
            }
        }
    }

    private func setNavigationBar() {
        title = I18n.View_M_LivestreamSettings
    }

    private func hideTopTableViewHeader() {
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        tableView.tableHeaderView = UIView(frame: frame)
    }

    override func doBack() {
        super.doBack()
        viewModel.refuseLiveIfNeeded()
    }

    private func bindOnBoarding() {
        // 当视图已加载，且有直播样式（存在collection)时，展示onBoarding
        Observable.zip(viewFirstAppearRelay.asObservable(), liveInfoForLayoutRelay.asObservable().take(1))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                // nolint-next-line: magic number
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.showOnboardingIfNeeded()
                }
            })
            .disposed(by: rx.disposeBag)
    }

    // disable-lint: long function
    override func bindViewModel() {
        viewModel.delegate = self
        bindOnBoarding()
        configPickedConfirmCallback()
        tableViewBindViewModel()
        if let dataSource = dataSource {
            viewModel.itemsObservable
                .observeOn(MainScheduler.instance)
                .do(afterNext: { [weak self] items in
                    guard let self = self else { return }
                    // 避免切换企业直播时候出现的switch跳动问题 https://meego.feishu.cn/bytelive/issue/detail/10251327
                    // nolint-next-line: magic number
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                        guard let self = self else { return }
                        self.updateContentHeight()
                        if items.contains(where: { model -> Bool in
                            return model.items.contains { item -> Bool in
                                guard case .layout = item else { return false }
                                return true
                            }
                        }) {
                            self.layoutCollection?.reload()
                            self.liveInfoForLayoutRelay.accept(())
                        }
                    }
                })
                .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        }
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] in
                self?.tableView.deselectRow(at: $0, animated: true)
            })
            .disposed(by: rx.disposeBag)

        tableView.rx.modelSelected(LiveSettings.self)
            .subscribe(onNext: { [weak self] item in
                self?.viewModel.didSelect(item)
            })
            .disposed(by: rx.disposeBag)

        liveButton.rx.action = viewModel.liveButtonAction
        viewModel.isLiveObserable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLive in
                guard let self = self else { return }
                self.updateLiveButton(isLive)
                if isLive && self.viewModel.isByteLive {
                    self.byteLiveLegalView.selectAndDisableCheckButton()
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.needDismissObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] dismiss in
                if dismiss {
                    self?.doBack()
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.keyDeletedObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] deleted in
                    if deleted {
                        self?.doBack()
                    }
            })
            .disposed(by: rx.disposeBag)

        viewModel.fetchLivePolicy { [weak self] result in
            switch result {
            case .success(let (links, attributedText)):
                Util.runInMainThread {
                    guard let self = self else { return }
                    for link in links {
                        self.legalLabel.addLKTextLink(link: link)
                    }
                    self.legalLabel.attributedText = attributedText
                    self.updateLegalLabelHeight()
                }
            case .failure(let error):
                self?.logger.error("fetchLivePolicy fail error \(error.toVCError())")
            }
        }

        viewModel.liveProviderStatusObservable
            .map { status -> Bool in
                return status.isProviderByteLive
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateLiveButton(self.viewModel.isLiving)
            })
            .disposed(by: rx.disposeBag)

        viewModel.liveProviderStatusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                self?.legalLabel.isHidden = status.isProviderByteLive
                self?.byteLiveLegalView.isHidden = !status.isProviderByteLive
                guard let urlString = status.response?.byteLiveInfo.byteLivePrivacyPolicyUrl else { return }
                if let url = URL(string: urlString) {
                    self?.byteLiveLegalView.updateLink(link: url)
                }
            })
            .disposed(by: rx.disposeBag)
    }

    // disable-lint: long function
    func tableViewBindViewModel() {
        dataSource = LiveSettingDataSource { [weak self] (_, _, _, item) in
            switch item {
            case .copyLink:
                let cell = LiveSettingTableViewCell()
                cell.setRadiusStyle()
                cell.setRadiusStyleBg(bgColor: UIColor.ud.bgBody)
                let image = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20))
                let title = I18n.View_M_CopyLivestreamingLinkNew
                cell.set(image, title: title, height: 48)
                cell.selectionStyle = .none
                cell.hideTopBottomLine(true)
                return cell
            case .privilege(let privilege, let disabledPrivileges, let enableSwitch, let liveProvider):
                let selectedPrivilege: LivePrivilege
                let isOverSea: Bool = self?.viewModel.memberIdentityData?.isOversea ?? false
                let allowExternal = self?.viewModel.memberIdentityData?.allowExternal ?? true
                var validCases: [LivePrivilege] = LivePrivilege.validCases
                if liveProvider == .larkLive {
                    if let realValidCases = self?.getVaildPrivilege(isOversea: isOverSea, allowExternal: allowExternal) {
                        validCases = realValidCases
                    }
                }
                if privilege == .other {
                    validCases.append(.other)
                }
                if validCases.contains(privilege) {
                    selectedPrivilege = privilege
                } else {
                    selectedPrivilege = .employee
                }
                let cell = LiveSettingsCell(style: .default, reuseIdentifier: nil)
                cell.showsLine = false
                guard let self = self else { return cell }
                let items = validCases
                    .map {
                        AnyChoiceItem(base: $0,
                                      isSelected: $0 == selectedPrivilege,
                                      isEnabled: !disabledPrivileges.keys.contains($0) && enableSwitch,
                                      textStyle: .body,
                                      preferredLabelWidth: self.tableView.frame.width,
                                      tapAction: { _ in },
                                      useBasicDisableStyle: true,
                                      disableHoverKey: disabledPrivileges.keys.contains($0) ? disabledPrivileges[$0] : "")
                    }
                let choiceView = ChoiceView(items: items, interitemSpacing: 13, itemImageSize: CGSize(width: 20.0, height: 20.0))
                choiceView.delegate = self
                // 这里的 at 是在 stackView 里面的 index 这里从上至下按顺序布局, 后面可以调整一下布局逻辑, 不再依赖 at 和 magic number
                if items.count > 1 {
                    choiceView.addLineView(at: 1)
                }
                if selectedPrivilege == .custom && !disabledPrivileges.keys.contains(.custom) {
                    choiceView.addPickedView(pickedCollection: self.pickedCollection, at: validCases.contains(.employee) ? 3 : 1, isOversea: isOverSea, allowExternal: allowExternal)
                    self.pickedCollection.isHidden = false
                } else {
                    if !(isOverSea && !allowExternal) {
                        self.pickedCollection.isHidden = true
                        choiceView.addLineView(at: validCases.contains(.employee) ? 3 : 1)
                    }
                }
                if items.count > 3 {
                    choiceView.addLineView(at: 5)
                }
                choiceView.handler = { [weak self] in
                    guard let privilege = $0.first as? LivePrivilege else {
                        return
                    }
                    if privilege == .custom {
                        self?.goToPickerBody()
                    } else {
                        self?.viewModel.selectPrivilege(privilege, nil)
                    }
                }
                cell.setEmbeddedView(choiceView)
                choiceView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview().inset(16)
                    make.top.bottom.equalToSuperview().inset(13)
                }
                cell.selectionStyle = .none
                return cell
            case .layout(let layoutStyle, let enableSwitch, let liveProvider):
                let cell = LiveSettingsCell(style: .default, reuseIdentifier: nil)
                cell.showsLine = false
                cell.selectionStyle = .none
                guard let self = self else { return cell }
                var validCases = LiveLayout.validCases
                if liveProvider == .larkLive {
                    validCases.removeAll { $0 == .speaker }
                }
                let selectedLayout: LiveLayout
                if validCases.contains(layoutStyle) {
                    selectedLayout = layoutStyle
                } else {
                    selectedLayout = .list
                }
                let items = validCases
                    .map { AnyChoiceCollectionItem(base: $0, isSelected: $0 == selectedLayout, isEnable: enableSwitch) }
                if let layoutCollection = self.layoutCollection {
                    layoutCollection.reload(with: items, spacing: 20)
                    cell.setEmbeddedView(layoutCollection)
                } else {
                    self.layoutCollection = ChoicesCollectionView(items: items, spacing: 20)
                    self.layoutCollection?.handler = { [weak self] in
                        guard let layout = $0.first else { return }
                        self?.viewModel.selectLayout(layout)
                    }
                    cell.setEmbeddedView(self.layoutCollection)
                }
                self.layoutCollection?.snp.remakeConstraints({ (make) in
                    make.top.bottom.equalToSuperview().inset(16)
                    make.left.right.equalToSuperview()
                })
                self.viewForGuide = cell.contentView
                return cell
            case .enableChat(let enable, let enableSwitch, _):
                let cell = LiveSettingTableViewCell()
                cell.setRadiusStyle()
                cell.setRadiusStyleBg(bgColor: UIColor.ud.bgBody)
                guard let self = self else { return cell }
                let title = I18n.View_M_AllowLivestreamLiveChat
                cell.bindSwitch(with: nil,
                                title: title,
                                height: 48,
                                isOn: Observable.just(enable).asDriver(onErrorJustReturn: false),
                                isEnabled: Observable.just(enableSwitch).asDriver(onErrorJustReturn: false),
                                action: self.viewModel.liveChatEnableAction)
                cell.selectionStyle = .none
                cell.hideTopBottomLine(true)
                return cell
            case .enablePlayback(let enable, let enableSwitch, _):
                let cell = LiveSettingTableViewCell()
                cell.setRadiusStyle()
                cell.setRadiusStyleBg(bgColor: UIColor.ud.bgBody)
                guard let self = self else { return cell }
                let title = I18n.View_MV_SaveLiveReplay_Switch
                cell.bindSwitch(with: nil,
                                title: title,
                                height: 48,
                                isOn: Observable.just(enable).asDriver(onErrorJustReturn: false),
                                isEnabled: Observable.just(enableSwitch).asDriver(onErrorJustReturn: false),
                                action: self.viewModel.livePlaybackEnableAction)
                cell.selectionStyle = .none
                cell.hideTopBottomLine(true)
                return cell
            case .chooseByteLive(let isByteLive, let enableSwitch, _):
                let cell = LiveSettingTableViewCell()
                cell.setRadiusStyle()
                cell.setRadiusStyleBg(bgColor: UIColor.ud.bgBody)
                guard let self = self else { return cell }
                let title = I18n.View_MV_SwitchToEnterpriseLive
                cell.bindSwitch(title: title,
                                height: 48,
                                isOn: Observable.just(isByteLive).asDriver(onErrorJustReturn: false),
                                isEnabled: Observable.just(enableSwitch).asDriver(onErrorJustReturn: false),
                                action: self.viewModel.chooseByteLiveAction)
                return cell
            }
        }
        tableView.delegate = nil
        tableView.dataSource = nil
        tableView.rx.setDelegate(self).disposed(by: rx.disposeBag)
    }
    // enable-lint: long function

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateContentHeight()

        if isMovingToParent {
            viewFirstAppearRelay.accept(())
        }
        tableView.flashScrollIndicators()

        viewModel.trackSettingStatus()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateContentHeight()
        updateLegalLabelHeight()
    }

    private func updateContentHeight() {
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
        panViewController?.updateBelowLayout()
    }

    private func updateLegalLabelHeight() {
        // https://bytedance.feishu.cn/docs/doccnOwZrJnsBVI3zmJyTwI5HCe#
        if legalLabel.preferredMaxLayoutWidth != legalLabel.frame.size.width {
            legalLabel.preferredMaxLayoutWidth = legalLabel.frame.size.width
            legalLabel.attributedText = legalLabel.attributedText
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if let layoutCollection = self.layoutCollection, layoutCollection.superview != nil {
            layoutCollection.reload()
            self.tableView.reloadData()
            self.layoutBottomSubview()
            self.dismissOnboardingIfNeeded()
        }
    }

    override func viewLayoutContextDidChanged() {
        self.updateLegalLabelHeight()
        self.updateContentHeight()
    }

    var contentHeight: CGFloat {
        return tableView.contentSize.height + view.safeAreaInsets.bottom
    }

    func configPickedConfirmCallback() {
        self.pickedConfirmCallBack = { [weak self] (members) in
            guard let self = self else { return }
            let realMembers = self.viewModel.configMemberData(members)
            self.viewModel.needReload = false
            DispatchQueue.main.async {
                self.updatePickedMemberData(members: realMembers, isFromInit: false)
            }
            self.viewModel.selectPrivilege(.custom, realMembers)
        }
    }

    func getVaildPrivilege(isOversea: Bool, allowExternal: Bool) -> [LivePrivilege] {
        var validCases: [LivePrivilege] = LivePrivilege.validCases
        // 海外且不在fg内
        if isOversea && !allowExternal {
            for i in 0..<validCases.count {
                if validCases[i] == .anonymous {
                    validCases.remove(at: i)
                }
            }
        }
        return validCases
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let dataSource = dataSource else { return 0 }
        return  dataSource.sectionModels[section].headText == nil ? 16 : 16 + 22
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let dataSource = dataSource else { return nil }
        guard let text = dataSource.sectionModels[section].headText else {
            let view = UIView()
            view.backgroundColor = .clear
            return view
        }
        let view = UIView()
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .left
        label.font = VCFontConfig.body.font
        label.attributedText = NSAttributedString(string: text, config: .bodyAssist)
        view.addSubview(label)
        label.snp.makeConstraints { (make) in

            make.left.equalTo(tableView.safeAreaInsets.left + 32)
            make.top.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(2)
        }
        viewForGuide = label
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.5
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func updatePrivilegeStatus() {
        self.pickedCollection.viewModel.privilegeChanged = self.viewModel.checkPrivilegeChanged(privilege: .custom)
    }
}

extension LiveSettingsViewController {
    func updateLiveButton(_ isLive: Bool) {
        if isLive {
            self.liveButton.setTitle(I18n.View_M_StopLivestreamingNew, for: .normal)
            self.liveButton.setTitle(I18n.View_M_StopLivestreamingNew, for: .highlighted)
            self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.functionDangerContentDefault), for: .normal)
            self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.functionDangerContentPressed), for: .highlighted)
        } else {
            self.liveButton.setTitle(I18n.View_M_StartLivestreamingNew, for: .normal)
            self.liveButton.setTitle(I18n.View_M_StartLivestreamingNew, for: .highlighted)
            self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
            self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.primaryContentPressed), for: .highlighted)
        }
    }
}

extension LiveSettingsViewController: PickedViewDelegate, ChoiceViewDelegate {
    func refreshPickedLayout() {
        self.bindViewModel()
    }

    func goToPickerBody() {
        //  跳转管理Picker
        updatePrivilegeStatus()
        self.viewModel.trackPickerClicked()
        let router = viewModel.meeting.larkRouter
        let customView: UIView = PickerHeaderCustomView(frame: CGRect(x: 0, y: 0, width: 0, height: 36))
        router.gotoChatterPicker(I18n.View_MV_ViewerSpecific_Title,
                                 displayStatus: self.viewModel.externalDisplayStatus?.rawValue ?? 0,
                                 disableUserKey: self.viewModel.disableUserKey,
                                 disableGroupKey: self.viewModel.disableGroupKey,
                                 customView: customView,
                                 pickedConfirmCallBack: pickedConfirmCallBack,
                                 defaultSelectedMembers: pickedCollection.viewModel.selectedMembers,
                                 from: self)
    }

    func toastI18Key(toastStr: String) {
        self.viewModel.toastByI18Key(toastStr)
    }
}

extension LiveSettingsViewController: LiveSettingViewModelDelegate {
    func isLegalButtonSelected() -> Bool {
        return self.byteLiveLegalView.checkbox.isSelected
    }

    func selectLegalButton() {
        self.byteLiveLegalView.checkbox.isSelected = true
    }

    func updatePickedMemberData(members: [LivePermissionMember], isFromInit: Bool) {
        self.pickedCollection.viewModel.pickedViewWidth = self.view.bounds.width - 48 - 64 - 16
        let isAllResigned = viewModel.isByteLive ? false : (self.viewModel.memberIdentityData?.isAllResigned ?? false)
        self.pickedCollection.viewModel.configData(members: members, isFromInit: isFromInit, isAllResigned: isAllResigned)
    }

    func configDisableLiveButton() {
        self.liveButton.setTitle(I18n.View_M_StartLivestreamingNew, for: .normal)
        self.liveButton.setTitle(I18n.View_M_StartLivestreamingNew, for: .highlighted)
        self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.lineBorderComponent), for: .normal)
        self.liveButton.setBackgroundImage(UIImage.vc.fromColor(UIColor.ud.lineBorderComponent), for: .highlighted)
    }
}
