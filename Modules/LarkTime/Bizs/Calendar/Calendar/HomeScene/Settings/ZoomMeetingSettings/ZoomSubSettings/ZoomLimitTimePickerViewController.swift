//
//  ZoomLimitTimePickerViewController.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import LarkContainer
import UniverseDesignToast
import LarkAlertController
import UniverseDesignColor
import UniverseDesignInput
import RxCocoa
import RxSwift
import FigmaKit
import LarkUIKit

final class ZoomLimitTimePickerViewController: BaseUIViewController {

    var onSaveCallBack: ((Server.ZoomMeetingSettings.BeforeHost) -> Void)?
    let pickerView: ZoomCommonListPickerView
    private var info: Server.ZoomMeetingSettings.BeforeHost
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    init (info: Server.ZoomMeetingSettings.BeforeHost) {
        self.info = info
        let pickedPos: Int = info.beforeTimeOptions.firstIndex(of: info.jbhTime) ?? 0
        let pickedList = info.beforeTimeOptions.map {
            if $0 == 0 {
                return I18n.Calendar_Zoom_Anytime
            } else {
                return I18n.Calendar_Zoom_NumMinInAdvance(number: $0)
            }
        }
        pickerView = ZoomCommonListPickerView(picked: pickedPos, pickerList: pickedList)

        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.Calendar_Zoom_SpecifiedTime
        addBackItem()
        layoutTimePickerView()
    }

    // 侧滑返回
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        onSaveCallBack?(info)
        self.navigationController?.popViewController(animated: true)
        return true
    }

    // 按钮返回
    override func backItemTapped() {
        onSaveCallBack?(info)
        self.navigationController?.popViewController(animated: true)
    }

    private func layoutTimePickerView() {
        self.view.addSubview(pickerView)
        pickerView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalToSuperview().offset(17)
        }

        pickerView.didSelectCallBack = { [weak self] picked in
            guard let self = self else { return }
            self.info.jbhTime = self.info.beforeTimeOptions[picked]
        }
    }
}
