//
//  AppLockCoverswift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/8/11.
//

import UIKit
import UniverseDesignColor
import SnapKit
import LarkUIKit
import LarkBlur
import UniverseDesignEmpty
import UniverseDesignFont

extension UIWindow {
    var blurView: AppLockBlurView? {
        subviews.first(where: { $0.isKind(of: AppLockBlurView.self) }) as? AppLockBlurView
    }
}

final class AppLockBlurView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let blurView = LarkBlurEffectView()
        blurView.blurRadius = 16
        blurView.colorTint = UDColor.primaryOnPrimaryFill
        blurView.colorTintAlpha = 0.01
        addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
}

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
        if #available(iOS 13.0, *) {
            empty.overrideUserInterfaceStyle = .dark
        }
        return empty
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let bgView = AppLockBackgroundView(frame: view.bounds)
        view.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(45)
            $0.trailing.equalTo(-45)
        }
    }
}
