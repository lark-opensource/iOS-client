//
//  MeetingRoomFormViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/3/28.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import LarkContainer
import LarkAssetsBrowser
import LarkUIKit

final class MeetingRoomFormViewController: BaseUIViewController, UIGestureRecognizerDelegate, UserResolverWrapper {

    @ScopedInjectedLazy private var calendarDependency: CalendarDependency?

    let userResolver: UserResolver

    private lazy var topView: MeetingRoomFormTopView = {
        let view = MeetingRoomFormTopView()
        return view
    }()

    private lazy var bottomView: MeetingRoomFormBottomView = {
        let view = MeetingRoomFormBottomView()
        return view
    }()

    private lazy var optionsScrollView: MeetingRoomFormOptionsScrollView = {
        let view = MeetingRoomFormOptionsScrollView()
        view.preservesSuperviewLayoutMargins = true
        return view
    }()

    private var bag = DisposeBag()

    let confirmSignal = PublishRelay<Rust.ResourceCustomization>()
    let cancelSignal = PublishRelay<Void>()

    typealias ViewModel = MeetingRoomFormViewModel
    let viewModel: ViewModel
    private let resourceCustomization: Rust.ResourceCustomization

    init(resourceCustomization: Rust.ResourceCustomization, userResolver: UserResolver) {
        self.resourceCustomization = resourceCustomization
        self.userResolver = userResolver
        viewModel = ViewModel(originalForm: resourceCustomization.customizationData, contactUserIDs: resourceCustomization.contactIds, userResolver: self.userResolver)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody
        navigationItem.hidesBackButton = true

        title = BundleI18n.Calendar.Calendar_MeetingRoom_Reservation

        view.addSubview(topView)
        view.addSubview(bottomView)
        view.addSubview(optionsScrollView)

        topView.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leadingMargin)
            make.trailing.equalTo(view.snp.trailingMargin)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        optionsScrollView.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leadingMargin)
            make.trailing.equalTo(view.snp.trailingMargin)
            make.top.equalTo(topView.snp.bottom).offset(24)
            make.bottom.equalTo(bottomView.snp.top).offset(-24)
        }

        isNavigationBarHidden = false
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }
        naviPopGestureRecognizerEnabled = false

        bind()

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc
    private func hideKeyboard() {
        view.endEditing(true)
    }

    private func bind() {
        // 收到更新表单的信号 更新view
        viewModel.updateFormRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] form, selections, inputs in
                guard let self = self else { return }
                self.optionsScrollView.update(form: form, currentSelections: selections, currentInputs: inputs)
            })
            .disposed(by: bag)

        // 用户输入/选择通知VM
        optionsScrollView.selectionRelay
            .subscribe(onNext: { [weak self] input in
                guard let self = self else { return }
                self.viewModel.update(questionKey: input.0, selections: input.1)
            })
            .disposed(by: bag)
        optionsScrollView.userInputRelay
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] input in
                guard let self = self else { return }
                self.viewModel.update(questionKey: input.0, userInput: input.1)
            })
            .disposed(by: bag)

        // 更新底部联系人信息
        viewModel.contactUpdateRelay
            .subscribeForUI(onNext: { [weak self] contact in
                guard let self = self else { return }
                self.bottomView.update(contact: contact)
            })
            .disposed(by: bag)

        // 图片预览
        optionsScrollView.previewImageRelay
            .subscribeForUI(onNext: { [weak self] (image, url) in
                guard let self = self else { return }
                var asset = LKDisplayAsset()
                asset.visibleThumbnail = UIImageView(image: image)
                asset.originalUrl = url
                let imageController = LKAssetBrowserViewController(assets: [asset], pageIndex: 0)
                imageController.getExistedImageBlock = { _ in image }
                imageController.isSavePhotoButtonHidden = true
                imageController.longPressEnable = false
                self.present(imageController, animated: true, completion: nil)
            })
            .disposed(by: bag)

        // 取消按钮 如果有过选择的变化
        bottomView.cancelButton.rx.tap
            .flatMapLatest { _ -> Observable<Void> in
                let editChange: Bool = { [weak self] in
                    guard let self = self else { return false }
                    return !(self.viewModel.currentFormRelay.value == self.viewModel.originalForm)
                }()
                if editChange {
                    return Observable<Void>.create { [weak self] observer in
                        guard let self = self else {
                            observer.onNext(())
                            observer.onCompleted()
                            return Disposables.create()
                        }
                        let alert = UIAlertController(title: BundleI18n.Calendar.Calendar_Edit_UnSaveTip, message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_Cancel, style: .cancel) { _ in observer.onCompleted() })
                        let confirmAction = UIAlertAction(title: BundleI18n.Calendar.Calendar_Common_Confirm, style: .default) { _ in
                            observer.onNext(())
                            observer.onCompleted()
                        }
                        alert.addAction(confirmAction)
                        self.present(alert, animated: true)
                        return Disposables.create {
                            alert.dismiss(animated: true)
                        }
                    }
                } else {
                    return .just(())
                }
            }
            .bind(to: cancelSignal)
            .disposed(by: bag)

        bottomView.rx.chatterTapped
            .drive(onNext: { [weak self] id in
                guard let self = self else { return }
                self.calendarDependency?.jumpToProfile(chatterId: id, eventTitle: "", from: self)
            })
            .disposed(by: bag)

        // 更新确认按钮的可点击状态
        viewModel.allRequiredQuestionHasAnswer
            .distinctUntilChanged()
            .do(onNext: { [weak self] enabled in
                DispatchQueue.main.async {
                    self?.bottomView.confirmButton.backgroundColor = enabled ? MeetingRoomFormBottomView.enabledBackgoundColor : MeetingRoomFormBottomView.disabledBackgoundColor
                }
            })
            .bind(to: bottomView.confirmButton.rx.isEnabled)
            .disposed(by: bag)

        // 提交事件 组合一个表单
        viewModel.currentFormRelay
            .sample(bottomView.confirmButton.rx.tap)
            .subscribe(onNext: { [weak self] form in
                guard let self = self else { return }
                var custom = self.resourceCustomization
                custom.customizationData = form
                self.confirmSignal.accept(custom)
            })
            .disposed(by: bag)
    }

    override func backItemTapped() {
        bottomView.cancelButton.sendActions(for: .touchUpInside)
    }

    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
