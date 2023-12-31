//
//  UserNickNameSelectViewController.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import UIKit
import Foundation
import LarkUIKit
import LarkAlertController
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkRustClient
import LarkInteraction
import LarkFeatureGating
import LarkContainer
import LarkSetting

final class UserNickNameSelectViewController: BaseUIViewController,
                                              UserResolverWrapper,
                                              UICollectionViewDelegate,
                                              UICollectionViewDataSource,
                                              UICollectionViewDelegateFlowLayout {
    let userResolver: UserResolver
    /// 自定义导航栏
    lazy var navBar: TitleNaviBar = {
        let nav = TitleNaviBar(titleString: BundleI18n.Moment.Lark_Community_SelectNicknameTitle)
        nav.rightViews = [configBtn]
        nav.addCloseButton { [weak self] in
            self?.closeBtnTapped()
        }
        return nav
    }()
    lazy var configBtn: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.Moment.Lark_Community_SelectNicknameDone, for: .normal)
        button.setTitleColor(UIColor.ud.textDisable, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(configBtnClick), for: .touchUpInside)
        button.addPointer(.highlight)
        return button
    }()

    lazy var collectionView: UICollectionView = {
        let layout = UserNickNameLeftAlignedLayout()
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(UserNickNameCell.self, forCellWithReuseIdentifier: UserNickNameCell.reuseId)
        collectionView.register(UserNickNameSelectHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserNickNameSelectHeaderView.reuseId)
        collectionView.register(UserNickNameSelectFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UserNickNameSelectFooterView.reuseId)
        return collectionView
    }()
    private let viewModel: UserNickNameViewModel
    private var isLoadingNikeNames = false
    private let headerViewModel: UserNickNameSelectHeaderViewModel
    private let circleId: String
    private var isEditNickName: Bool
    private var nickNameSettingStyle: NickNameSettingStyle
    let completeBlock: ((_ momentUser: RawData.RustMomentUser, _ renewNicknameTime: Int64) -> Void)?
    let margin: CGFloat = 16
    /// 默认不为花名修改页面，即isEditNickName为false，根据传入的花名设置style赋值
    init(userResolver: UserResolver,
         circleId: String,
         completeBlock: ((_ momentUser: RawData.RustMomentUser, _ renewNicknameTime: Int64) -> Void)?,
         nickNameSettingStyle: NickNameSettingStyle = .select) {
        self.circleId = circleId
        self.completeBlock = completeBlock
        self.nickNameSettingStyle = nickNameSettingStyle
        switch nickNameSettingStyle {
        case .select:
            self.isEditNickName = false
        case .modify(let nickNameID, let nickName, let avatarKey):
            self.isEditNickName = true
        }
        viewModel = UserNickNameViewModel(userResolver: userResolver, nickNameSettingStyle: nickNameSettingStyle)
        headerViewModel = UserNickNameSelectHeaderViewModel(userResolver: userResolver)
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        headerViewModel.layout = UserNickNameHeaderLayout(maxWidth: self.view.frame.size.width - 2 * margin)
    }

    private func setupUI() {
        isNavigationBarHidden = true
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let hudView = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_LoadingToast, on: self.view.window ?? self.view, disableUserInteraction: true)
        self.viewModel.refreshUserNikeNames(finish: { [weak self] (error) in
            guard let self = self else { return }
            /// 根据花名设置style判断当前是否将要展示当前的花名和头像，展示完后将isEditNickName置为false，下次刷新将不展示原花名
            switch self.nickNameSettingStyle {
            case .modify(nickNameID: let nickNameID, nickName: let nickName, avatarKey: let avatarKey):
                if !self.viewModel.datas.isEmpty && self.isEditNickName {
                    self.headerViewModel.nickNameData = self.viewModel.datas[0].data
                    self.headerViewModel.selectedIcon = avatarKey
                    self.isEditNickName = false
                }
            case .select:
                break
            }
            self.collectionView.reloadData()
            hudView.remove()
            if error != nil {
                let toastOnView: UIView = self.presentingViewController?.view ?? self.view
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_LoadingFailed, on: toastOnView.window ?? toastOnView)
                self.closeBtnTapped()
            }
        })
        /// 当花名设置style为选择模式时更新头像，修改设置，用原头像，不修改（不需要刷新头像）
        if case .select = self.nickNameSettingStyle {
            self.headerViewModel.refreshIcon { [weak self] (error) in
                if error == nil {
                    self?.updateHeaderViewUI()
                }
            }
        }
    }
    @objc
    func configBtnClick() {
        guard configBtn.isSelected,
              let nickNameData = self.headerViewModel.nickNameData,
              let avatarKey = self.headerViewModel.selectedIcon else { return }
        let alertVC = LarkAlertController()
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false
        if fgValue {
            switch self.nickNameSettingStyle {
            case .modify(nickNameID: let nickNameID, nickName: let nickName, avatarKey: let avatarKey):
                alertVC.setTitle(text: BundleI18n.Moment.Moments_Settings_UseThisNickname_Title("\(nickNameData.nickname)"))
                alertVC.setContent(text: BundleI18n.Moment.Moments_Settings_UseThisNickname_Desc(MomentTab.tabTitle()))
            case .select:
                alertVC.setTitle(text: BundleI18n.Moment.Lark_Community_ConfirmNicknameTitle)
                alertVC.setContent(text: BundleI18n.Moment.Moments_ConfirmNicknameDesc_Text("\(nickNameData.nickname)", MomentTab.tabTitle()))
            }
        } else {
            /// FG关闭的时候 设置没有花名的展示选项
            alertVC.setTitle(text: BundleI18n.Moment.Lark_Community_ConfirmNicknameTitle)
            alertVC.setContent(text: BundleI18n.Moment.Lark_Community_ConfirmNicknameDesc("\(nickNameData.nickname)"))
        }
        alertVC.addCancelButton()
        alertVC.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_ConfirmNicknameButton, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            var isRenwal: Bool = false
            switch self.nickNameSettingStyle {
            case .select:
                isRenwal = false
            case .modify:
                isRenwal = true
            }
            self.viewModel.confirmNickName(circleId: self.circleId,
                                           avatarKey: avatarKey,
                                           nickName: nickNameData,
                                           isRenewal: isRenwal) { [weak self] (error) in
                guard let error = error else {
                    if let nickNameInfo = self?.viewModel.nickNameInfo {
                        self?.completeBlock?(nickNameInfo.momentUser, nickNameInfo.renewNicknameTime)
                    }
                    self?.dismiss(animated: true, completion: nil)
                    return
                }
                var errorMessage = BundleI18n.Moment.Lark_Community_UnableSelectNickname
                if let rcError = error as? RCError {
                    switch rcError {
                    case .businessFailure(errorInfo: let info) where !info.displayMessage.isEmpty:
                        errorMessage = info.displayMessage
                    default:
                        break
                    }
                }
                UDToast.showFailure(with: errorMessage, on: self?.view.window ?? UIView())
            }
        })
        userResolver.navigator.present(alertVC, from: self)
    }

    private func updateConfigBtnStatus() {
        /// 根据花名设置style判断当前是否需要设置当选取原花名时保存按钮为不可点击状态
        switch self.nickNameSettingStyle {
        case .select:
            configBtn.isSelected = headerViewModel.canConfirm()
        case .modify(nickNameID: let nickNameID, nickName: let nickName, avatarKey: let avatarKey):
            configBtn.isSelected = headerViewModel.canConfirm(curNickNameID: nickNameID)
        }
    }

    // MARK: - collectionView代理
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.datas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserNickNameCell.reuseId, for: indexPath)
        if let nickNameCell = cell as? UserNickNameCell {
            nickNameCell.item = viewModel.datas[indexPath.row]
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentItem = viewModel.datas[indexPath.row]
        if !currentItem.selected {
            viewModel.datas.forEach { $0.selected = false }
            currentItem.selected = true
            headerViewModel.nickNameData = currentItem.data
        } else {
            currentItem.selected = false
            headerViewModel.nickNameData = nil
            if let cell = collectionView.cellForItem(at: indexPath) as? UserNickNameCell {
                cell.item = currentItem
            }
        }

        headerViewModel.layout?.title = headerViewModel.nickNameData?.nickname
        getCollectionViewHeader()?.viewModel = headerViewModel
        updateConfigBtnStatus()
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: UserNickNameSelectHeaderView.reuseId, for: indexPath)
            if let nikeNameHeader = header as? UserNickNameSelectHeaderView {
                nikeNameHeader.viewModel = headerViewModel
            }
            return header
        }
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UserNickNameSelectFooterView.reuseId, for: indexPath)
        if let nikeNameFooter = footer as? UserNickNameSelectFooterView {
            nikeNameFooter.isLoading = isLoadingNikeNames
            nikeNameFooter.refreshCallBack = { [weak self] in
                self?.viewModel.refreshUserNikeNames(finish: { [weak self] _ in
                    self?.collectionView.reloadData()
                })
            }
        }
        return footer
    }
    // MARK: - collectionViewLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = viewModel.datas[indexPath.row].width + 32
        return CGSize(width: min(width, view.frame.size.width - 32), height: 36)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: headerViewModel.layout?.suggestHeight ?? 250)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 70)
    }

    private func getCollectionViewHeader() -> UserNickNameSelectHeaderView? {
        return collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(row: 0, section: 0)) as? UserNickNameSelectHeaderView
    }

    private func updateHeaderViewUI() {
        getCollectionViewHeader()?.viewModel = headerViewModel
    }
}
