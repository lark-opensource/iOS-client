//
//  FaceToFaceCreateGroupViewController.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/8.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import LarkMessengerInterface
import SnapKit
import RxSwift
import RxCocoa
import LarkAlertController
import LarkTab
import LarkNavigation
import LarkModel
import LarkExtensions
import RustPB
import UniverseDesignToast
import UniverseDesignDialog
import LarkContainer

final class FaceToFaceCreateGroupViewController: BaseUIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    private let viewModel: FaceToFaceCreateGroupViewModel
    private let fromType: CreateGroupWithFaceToFaceBody.FromType // 来源，埋点使用

    private var headerView: FaceToFaceHeadView?
    private lazy var keyboardView = FaceToFaceKeyboardView()
    private lazy var bottomContainerView = UIView()

    private var hud: UDToast?
    private var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    // 初始化提供占位 Item
    private var colleactionDatasource: [RustPB.Im_V1_FaceToFaceApplicant] = [RustPB.Im_V1_FaceToFaceApplicant()]
    // 总人数
    private var totalCount = 0
    // 允许展示的人数限制
    private let displayLimit = 200
    private let disposeBag = DisposeBag()

    private lazy var enterButton: UIButton = {
        let enterButton = UIButton()
        enterButton.setTitle(BundleI18n.LarkContact.Lark_NearbyGroup_EnterChat, for: .normal)
        enterButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        enterButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        enterButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        enterButton.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        enterButton.layer.cornerRadius = 6
        enterButton.layer.masksToBounds = true
        enterButton.alpha = 0
        enterButton.addTarget(self, action: #selector(clickEnterButton), for: .touchUpInside)
        return enterButton
    }()

    private lazy var bottomSepratorLine: UIView = {
        let bottomSepratorLine = UIView()
        bottomSepratorLine.backgroundColor = UIColor.ud.lineDividerDefault
        bottomSepratorLine.alpha = 0
        return bottomSepratorLine
    }()

    init(viewModel: FaceToFaceCreateGroupViewModel, fromType: CreateGroupWithFaceToFaceBody.FromType, resolver: UserResolver) {
        self.viewModel = viewModel
        self.fromType = fromType
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkContact.Lark_NearbyGroup_Title
        self.view.backgroundColor = UIColor.ud.bgBase

        self.bottomContainerView.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(bottomContainerView)
        bottomContainerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom)
            make.height.lessThanOrEqualToSuperview().multipliedBy(0.45)
            make.height.equalTo(self.view.snp.width).multipliedBy(0.8).priority(.high)
        }

        let headerView = FaceToFaceHeadView(statusDriver: self.viewModel.statusDriver, codeNumberLimit: self.viewModel.codeNumberLimit)
        self.view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomContainerView.snp.top)
        }
        self.headerView = headerView

        self.bottomContainerView.addSubview(self.keyboardView)
        keyboardView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.92)
            make.top.bottom.equalToSuperview().inset(16)
        }

        self.bindViewModel()
    }

    private func bindViewModel() {
        keyboardView.keyboardObservable
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                self.viewModel.handleKeyboardAction(action)
            }).disposed(by: self.disposeBag)

        self.viewModel
            .processDriver
            .drive(onNext: { [weak self] processType in
                guard let self = self else { return }
                switch processType {
                case .locationAccessDenied:
                    let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkContact.Lark_Core_LocationAccess_Title,
                                                             detail: BundleI18n.LarkContact.Lark_Core_EnableLocationAccess_ToJoinNearbyGroup())
                    self.navigator.present(dialog, from: self)
                case .verifySuccess(let applicants):
                    self.bottomContainerView.addSubview(self.bottomSepratorLine)
                    self.bottomContainerView.addSubview(self.enterButton)
                    self.enterButton.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview().inset(16)
                        make.height.equalTo(48)
                        make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(24)
                    }
                    self.bottomSepratorLine.snp.makeConstraints { (make) in
                        make.left.right.equalToSuperview()
                        make.bottom.equalTo(self.enterButton.snp.top).offset(-8)
                        make.height.equalTo(0.5)
                    }
                    self.totalCount = applicants.count
                    self.colleactionDatasource.insert(contentsOf: applicants, at: 0)
                    self.setupCollectionView()
                    self.view.layoutIfNeeded()

                    UIView.animate(withDuration: 0.5) {
                        self.keyboardView.alpha = 0
                    } completion: { _ in
                        UIView.animate(withDuration: 0.5) {
                            self.bottomContainerView.snp.remakeConstraints { (make) in
                                make.left.right.equalToSuperview()
                                make.bottom.equalTo(self.view.snp.bottom)
                                make.height.equalToSuperview().multipliedBy(0.66)
                            }
                            self.enterButton.alpha = 1
                            self.bottomSepratorLine.alpha = 1
                            self.view.layoutIfNeeded()
                        } completion: { _ in
                            UIView.animate(withDuration: 0.5) {
                                self.collectionView.alpha = 1
                            }
                        }
                    }
                case .hasNewApplicants(let applicants):
                    self.totalCount += applicants.count

                    if let view = self.collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).first as? FaceToFaceApplicantCollectionHeader {
                        view.set(number: self.totalCount)
                    }

                    // exceed limit
                    if self.totalCount - applicants.count > self.displayLimit {
                        self.collectionView.reloadItems(at: [IndexPath(item: self.colleactionDatasource.count - 1, section: 0)])
                        return
                    }

                    if self.colleactionDatasource.count == self.displayLimit, let applicant = applicants.first {
                        UIView.animate(withDuration: 0.5) {
                            self.collectionView.performBatchUpdates {
                                self.colleactionDatasource.removeLast()
                                self.collectionView.deleteItems(at: [IndexPath(item: self.displayLimit - 1, section: 0)])
                                self.colleactionDatasource.append(applicant)
                                self.collectionView.insertItems(at: [IndexPath(item: self.displayLimit - 1, section: 0)])
                            }
                        }
                        return
                    }

                    UIView.animate(withDuration: 0.5) {
                        self.collectionView.performBatchUpdates {
                            let removedIndex = self.colleactionDatasource.count - 1
                            let removedItem = self.colleactionDatasource.removeLast()
                            self.collectionView.deleteItems(at: [IndexPath(item: removedIndex, section: 0)])
                            if self.colleactionDatasource.count + applicants.count < self.displayLimit {
                                self.colleactionDatasource.append(contentsOf: applicants)
                                self.colleactionDatasource.append(removedItem)
                                let start = self.colleactionDatasource.count - applicants.count - 1
                                let end = self.colleactionDatasource.count - 1
                                self.collectionView.insertItems(at: [Int](start...end).map { IndexPath(item: Int($0), section: 0) })
                            } else {
                                let prefixCount = self.displayLimit - self.colleactionDatasource.count
                                self.colleactionDatasource.append(contentsOf: applicants.prefix(prefixCount))
                                let start = self.colleactionDatasource.count - prefixCount
                                let end = self.colleactionDatasource.count - 1
                                self.collectionView.insertItems(at: [Int](start...end).map { IndexPath(item: Int($0), section: 0) })
                            }
                        }
                    }
                    self.collectionView.scrollToItem(at: IndexPath(item: self.colleactionDatasource.count - 1, section: 0), at: .bottom, animated: true)
                case .requestFailure(let msg):
                    let alertController = LarkAlertController()
                    alertController.setContent(text: msg)
                    alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Sure)
                    self.navigator.present(alertController, from: self)
                case .enableKeyboard(let enable):
                    self.keyboardView.isUserInteractionEnabled = enable
                case .hudStatusChanged(let hudStatus):
                    switch hudStatus {
                    case .initHud:
                        self.hud = UDToast()
                    case .loadingHud:
                        self.hud?.showLoading(with: BundleI18n.LarkContact.Lark_Legacy_BaseUiLoading, on: self.view, disableUserInteraction: true)
                    case .removeHud:
                        self.hud?.remove()
                        self.hud = nil
                    case .showFailure(let msg):
                        self.hud?.showFailure(with: msg, on: self.view)
                        self.hud = nil
                    }
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.startUpdatingLocation()
    }

    private func setupCollectionView() {
        let layout = FaceToFaceApplicantFlowLayout()
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.clear
        collection.alpha = 0
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(FaceToFaceApplicantViewCell.self,
                            forCellWithReuseIdentifier: String(describing: FaceToFaceApplicantViewCell.self))
        collection.register(FaceToFaceApplicantPlaceholderViewCell.self,
                            forCellWithReuseIdentifier: String(describing: FaceToFaceApplicantPlaceholderViewCell.self))
        collection.register(FaceToFaceApplicantCollectionHeader.self,
                            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                            withReuseIdentifier: String(describing: FaceToFaceApplicantCollectionHeader.self))
        self.bottomContainerView.addSubview(collection)
        collection.snp.makeConstraints({ make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(self.bottomSepratorLine.snp.top)
        })
        collection.reloadData()
        self.collectionView = collection
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.colleactionDatasource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == self.colleactionDatasource.count - 1 {
            if self.totalCount < self.displayLimit {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FaceToFaceApplicantPlaceholderViewCell.self),
                                                                 for: indexPath) as? FaceToFaceApplicantPlaceholderViewCell {
                    cell.setContent(number: 0)
                    return cell
                }
                return UICollectionViewCell()
            }
            if self.totalCount > self.displayLimit {
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FaceToFaceApplicantPlaceholderViewCell.self),
                                                                 for: indexPath) as? FaceToFaceApplicantPlaceholderViewCell {
                    cell.setContent(number: self.totalCount - self.displayLimit + 1)
                    return cell
                }
                return UICollectionViewCell()
            }
        }
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FaceToFaceApplicantViewCell.self),
                                                         for: indexPath) as? FaceToFaceApplicantViewCell {
            let applicant = self.colleactionDatasource[indexPath.item]
            cell.setContent(applicant.avatarKey, userId: "\(applicant.userID)", userName: applicant.name)
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: String(describing: FaceToFaceApplicantCollectionHeader.self),
                                                                         for: indexPath)
        if let headerView = headerView as? FaceToFaceApplicantCollectionHeader {
            headerView.set(number: self.totalCount)
        }
        return headerView
    }

    @objc
    func clickEnterButton(_ button: UIButton) {
        self.viewModel.joinChat(success: { [weak self] chat in
            guard let `self` = self else { return }
            self.navigator.switchTab(
                Tab.feed.url,
                from: self,
                animated: true,
                completion: { [weak self] _ in
                    guard let self = self, let realFrom = (RootNavigationController.shared.viewControllers.first as? UITabBarController)?.selectedViewController else {
                        return
                    }

                    switch self.fromType {
                    case .createGroup:
                        Tracer.faceToFaceEnterChat()
                    case .externalContact:
                        Tracer.contactFaceToFaceEnterChat()
                    }

                    let chatBody = ChatControllerByChatBody(chat: chat)
                    self.navigator.showDetailOrPush(
                        body: chatBody,
                        wrap: LkNavigationController.self,
                        from: realFrom,
                        animated: true
                    )
                }
            )
        })
    }
}
