//
//  BTFieldGroupingSetAnimateViewController.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import Foundation
import SKCommon
import SKBrowser
import LarkUIKit
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import EENavigator
import UIKit

protocol BTFieldGroupingSetAnimateViewControllerDelegate: AnyObject {
    func didOpenSetView(fieldEditModel: BTFieldEditModel)
}

final class BTFieldGroupingSetAnimateViewController: SKPanelController {

    private var isFirstOpen = true
    private var currentOrientation: UIInterfaceOrientation = .portrait
    private var fieldEditModel: BTFieldEditModel
    private weak var hostVC: UIViewController?
    weak var delegate: BTFieldGroupingSetAnimateViewControllerDelegate?
    private var groupSetVC: BTFieldGroupingSetViewController?
    private var reportCommonParams: [String: Any]

    private var maxViewHeight: CGFloat {
        SKDisplay.windowBounds(self.view).height * 0.8
    }

    init(fieldEditModel: BTFieldEditModel,
         hostVC: UIViewController?,
         reportCommonParams: [String: Any]) {
        self.fieldEditModel = fieldEditModel
        self.reportCommonParams = reportCommonParams
        self.hostVC = hostVC
        super.init(nibName: nil, bundle: nil)

        self.dismissalStrategy = []
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()

        groupSetVC = BTFieldGroupingSetViewController(groupingStatisticsSetItems: fieldEditModel.statTypeList,
                                                      delegate: self,
                                                      selectedItemId: fieldEditModel.statTypeId,
                                                      fieldId: fieldEditModel.fieldId,
                                                      callbackString: fieldEditModel.callback,
                                                      hostVC: hostVC,
                                                      reportCommonParams: reportCommonParams)
        guard let groupSetVC = groupSetVC else {
            return
        }

        self.addChild(groupSetVC)
        self.containerView.addSubview(groupSetVC.view)

        let groupSetVCHeight = min(CGFloat((fieldEditModel.statTypeList.count + 1) * 48 + 58), maxViewHeight)

        groupSetVC.didMove(toParent: self)
        groupSetVC.view.snp.makeConstraints { make in
            make.height.equalTo(groupSetVCHeight)
            make.edges.equalTo(containerView.safeAreaLayoutGuide)
        }

        self.navigationController?.navigationBar.isHidden = true
    }


    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
        }) { [self] _ in
            guard let groupSetVC = groupSetVC else {
                return
            }

            if UIApplication.shared.statusBarOrientation != currentOrientation {
                currentOrientation = UIApplication.shared.statusBarOrientation

                let groupSetVCHeight = min(CGFloat((fieldEditModel.statTypeList.count + 1) * 48 + 58), maxViewHeight)

                groupSetVC.view.snp.updateConstraints { make in
                    make.height.equalTo(groupSetVCHeight)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentOrientation = UIApplication.shared.statusBarOrientation
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstOpen {
            delegate?.didOpenSetView(fieldEditModel: fieldEditModel)
        }
        isFirstOpen = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
}

extension BTFieldGroupingSetAnimateViewController: BTFieldGroupingSetViewControllerDelegate {
    func didClickClosePage() {
        self.dismiss(animated: true)
    }
}
