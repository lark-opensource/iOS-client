//
//  DriveNoPermissionController.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/2/12.
//

import UIKit
import SwiftyJSON
import EENavigator
import SKCommon
import SKUIKit
import SKResource
import SKFoundation

class DriveRequestPermissionController: SKRequestPermissionController, DKViewModeChangable {
    private let tapHandler = DriveTapEnterFullModeHandler()
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    private var cacCardModeBlockView: UIView = {
        let view = DriveCACBlockView()
        return view
    }()
    
    var displayMode: DrivePreviewMode = .normal
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapHandler.addTapGestureRecognizer(targetView: view) { [unowned self] in
            if self.screenModeDelegate?.isInFullScreenMode() ?? false {
                self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
            }
        }
        if case .previewControlByCAC = defaultBlockType {
            changeMode(displayMode, animate: true)
        }
    }
    
    //在卡片态加一个 DriveCACBlockView 盖住，对卡片态UI适配同层
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        switch mode {
        case .normal:
            cacCardModeBlockView.removeFromSuperview()
        case .card:
            guard cacCardModeBlockView.superview == nil else {
                return
            }
            view.addSubview(cacCardModeBlockView)
            cacCardModeBlockView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}
