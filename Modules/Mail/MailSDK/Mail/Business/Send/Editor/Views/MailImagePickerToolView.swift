//
//  File.swift
//  MailSDK
//
//  Created by majx on 2019/6/13.
//

import Foundation
import LarkUIKit
import LarkAssetsBrowser
import UniverseDesignTheme

class MailImagePickerToolView: EditorSubToolBarPanel {
   var suiteView: AssetPickerSuiteView?

   override var frame: CGRect {
        didSet {
            super.frame = frame
        }
    }

    /// Description
    ///
    /// - Parameter frame: frame description
    init(frame: CGRect, sendAction: MailSendAction?, presentVC: UIViewController?) {
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.getRealUserInterfaceStyle())
            UITraitCollection.current = correctTrait
            overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
        }
        self.clipsToBounds = true
        let type: PhotoPickerAssetType
        if sendAction == .outOfOffice {
            type = .imageOnly(maxCount: 9)
        } else {
            type = .imageOrVideo(imageMaxCount: 9, videoMaxCount: 1)
        }
        suiteView = AssetPickerSuiteView(assetType: type, sendButtonTitle: BundleI18n.MailSDK.Mail_Alert_Confirm, presentVC: presentVC)
        suiteView?.set(isOrigin: true)
        if let view = suiteView {
            self.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.leading.trailing.top.bottom.equalToSuperview()
            }
        }
    }

    /// Description
    ///
    /// - Parameter aDecoder: aDecoder description
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
