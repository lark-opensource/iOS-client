//
//  LanguagePickerPanel.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import UIKit
import Foundation
import UniverseDesignActionPanel
import EENavigator
import LarkLocalizations
import RxSwift
import RxCocoa
import LarkNavigator

final class LanguagePickerActionPanel: UDActionPanel {

    private var disposeBag = DisposeBag()

    init(navigator: Navigatable, languagePickerVC: LanguagePickerViewController, supportLangs: [Lang]) {
        let tableViewHeight: CGFloat = CGFloat(supportLangs.count * 48)
        let headerHeight: CGFloat = 48
        let bottomSpaceHeight: CGFloat = 12
        let safeAreaBottomInset = navigator.mainSceneWindow?.safeAreaInsets.bottom ?? .zero
        let panelHeight = tableViewHeight + headerHeight + safeAreaBottomInset + bottomSpaceHeight
        var config = UDActionPanelUIConfig()
        config.originY = UIScreen.main.bounds.height - panelHeight
        config.canBeDragged = false
        config.showIcon = false
        super.init(customViewController: languagePickerVC, config: config)
        self.view.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
