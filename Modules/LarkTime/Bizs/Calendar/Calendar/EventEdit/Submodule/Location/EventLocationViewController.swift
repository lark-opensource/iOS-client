//
//  EventLocationViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/3/23.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkLocationPicker
import LarkSensitivityControl

/// 日程 - Location 编辑页

protocol EventLocationViewControllerDelegate: AnyObject {
    func didCancelEdit(from viewController: EventLocationViewController)
    func didFinishEdit(from viewController: EventLocationViewController)
}

final class EventLocationViewController: UIViewController {

    weak var delegate: EventLocationViewControllerDelegate?
    internal private(set) var selectedLocation: EventEditLocation?
    // 用户开始编辑前的 selectedLocation，退出取消编辑时，用于判断是否应该弹窗提醒
    internal private(set) var selectedLocationBeforeEditing: EventEditLocation?
    private let disposeBag = DisposeBag()
    private lazy var locationPickerView: LocationPickerView = {
        /// 无地址，默认传空字符串
        let location = selectedLocation?.name ?? ""
        let token = LarkSensitivityControl.Token("LARK-PSDA-Calendar-EventLocationViewController-Location", type: .location)
        return LocationPickerView(forToken: token, location: location, allowCustomLocation: true)
    }()

    init(location: EventEditLocation?) {
        selectedLocation = location
        selectedLocationBeforeEditing = location
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNaviItems()
        setupLocationPickerView()
        bindViewAction()
        navigationController?.presentationController?.delegate = self
    }

    private func setupNaviItems() {
        let cancelItem = LKBarButtonItem(
            title: BundleI18n.Calendar.Calendar_Common_Cancel
        )
        navigationItem.leftBarButtonItem = cancelItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Done, fontStyle: .medium)
        doneItem.button.tintColor = EventEditUIStyle.Color.blueText
        navigationItem.rightBarButtonItem = doneItem
    }

    private func setupLocationPickerView() {
        locationPickerView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(locationPickerView)
        locationPickerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindViewAction() {
        let closeItem = navigationItem.leftBarButtonItem as? LKBarButtonItem
        closeItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.willCancelEdit()
            }
            .disposed(by: disposeBag)

        let doneItem = navigationItem.rightBarButtonItem as? LKBarButtonItem
        doneItem?.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                /// 获取 LocationData
                if let locationData = self.locationPickerView.selectedLocation() {
                    self.selectedLocation = EventEditLocation(
                        name: locationData.name,
                        address: locationData.address,
                        coordinate: locationData.location
                    )
                } else {
                    self.selectedLocation = nil
                }
                self.delegate?.didFinishEdit(from: self)
            }
            .disposed(by: disposeBag)
    }

    private func willCancelEdit() {
        let inPresentation = self.locationPickerView.selectedLocation()?.name != self.selectedLocationBeforeEditing?.name
        if inPresentation {
            let alertTexts = EventEditConfirmAlertTexts(
                message: BundleI18n.Calendar.Calendar_Edit_UnSaveTip
            )
            self.showConfirmAlertController(
                texts: alertTexts,
                confirmHandler: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.didCancelEdit(from: self)
                }
            )
        } else {
            self.delegate?.didCancelEdit(from: self)
        }
    }
}

extension EventLocationViewController: EventEditConfirmAlertSupport {}

extension EventLocationViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        let inPresentation = self.locationPickerView.selectedLocation()?.name != self.selectedLocationBeforeEditing?.name
        return !inPresentation
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        willCancelEdit()
    }
}
