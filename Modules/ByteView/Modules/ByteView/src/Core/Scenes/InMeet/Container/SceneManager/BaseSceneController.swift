//
//  BaseSceneController.swift
//  ByteView
//
//  Created by liujianlong on 2023/3/10.
//

import UIKit

class BaseSceneController: UIViewController, InMeetSceneController {
    weak var sceneControllerDelegate: SceneControllerDelegate?
    var content: InMeetSceneManager.ContentMode
    var childVCForStatusBarStyle: InMeetOrderedViewController? {
        nil
    }
    var childVCForOrientation: InMeetOrderedViewController? {
        nil
    }

    private(set) var isMounted: Bool = false
    private(set) weak var container: InMeetViewContainer?

    let containerTopBarExtendGuide = UILayoutGuide()
    let containerBottomBarGuide = UILayoutGuide()

    let viewModel: InMeetViewModel
    init(container: InMeetViewContainer, content: InMeetSceneManager.ContentMode) {
        self.viewModel = container.viewModel
        self.container = container
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if let container = self.container, parent === container {
            if !isMounted {
                isMounted = true
                self.onMount(container: container)
            }
        } else {
            if isMounted {
                isMounted = false
                self.onUnmount()
                self.container = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addLayoutGuide(containerTopBarExtendGuide)
        self.view.addLayoutGuide(containerBottomBarGuide)
        #if DEBUG
        containerTopBarExtendGuide.identifier = "containerTopBarExtendGuide"
        containerBottomBarGuide.identifier = "containerBottomBarGuide"
        #endif
    }

    func onMount(container: InMeetViewContainer) {
        Logger.scene.info("mount \(self)")
        self.containerTopBarExtendGuide.snp.remakeConstraints({ make in
            make.edges.equalTo(container.topExtendContainerGuide)
        })
        self.containerBottomBarGuide.snp.remakeConstraints { make in
            make.edges.equalTo(container.bottomBarGuide)
        }
    }

    func onUnmount() {
        Logger.scene.info("unmount \(self)")
    }
}
