//
//  AppLockCoverViewControllerV2
//  LarkEMM
//
// Created by chenjinglin on 2023/11/3.
//

import UIKit
import UniverseDesignColor
import SnapKit
import LarkUIKit
import LarkBlur
import UniverseDesignEmpty
import UniverseDesignFont

extension AppLockSettingV2 {
    final class AppLockCoverViewController: BaseUIViewController {
        private let emptyView: UDEmpty = {
            let description = UDEmptyConfig.Description(descriptionText: BundleI18n.AppLock.Lark_Lock_Toast_LockedGoToMainPage(),
                                                        font: UIFont.ud.body1)
            let empty = UDEmpty(config: UDEmptyConfig(title: nil,
                                                      description: description,
                                                      imageSize: 100,
                                                      spaceBelowImage: 12,
                                                      spaceBelowTitle: 0,
                                                      spaceBelowDescription: 0,
                                                      spaceBetweenButtons: 0,
                                                      type: .noAccess))
            return empty
        }()

        override func viewDidLoad() {
            super.viewDidLoad()
            let bgView = AppLockBackgroundView(frame: view.bounds)
            view.addSubview(bgView)
            view.addSubview(emptyView)
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            emptyView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalTo(45)
                $0.trailing.equalTo(-45)
            }
        }
    }
}
