//
//  DocsContainerViewController.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/10.
//  


import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon

class DocsContainerViewController: BaseViewController {
    weak var docComponentHostDelegate: DocComponentHostDelegate?
    var contentVC: DocComponentHost
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.contentVC.supportedInterfaceOrientations
    }
    
    init(contentHost: DocComponentHost) {
        self.contentVC = contentHost
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.docComponentHostDelegate?.docComponentHostWillClose(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupContentVC(contentVC)
    }
    
    
    private func setupContentVC(_ vc: DocComponentHost) {
        addContentVC(vc)
        setNavigationBarHidden(true, animated: false)
        self.contentVC = vc
        DocsLogger.info("setupContentVC, vc:\(String(describing: type(of: vc)))", component: LogComponents.docComponent)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DocsLogger.info("ContainerVC viewWillAppear ", component: LogComponents.docComponent)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DocsLogger.info("ContainerVC viewDidAppear ", component: LogComponents.docComponent)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DocsLogger.info("ContainerVC viewWillDisappear ", component: LogComponents.docComponent)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DocsLogger.info("ContainerVC viewDidDisappear ", component: LogComponents.docComponent)
    }
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        DocsLogger.info("ContainerVC willMove parent:\(parent != nil) ", component: LogComponents.docComponent)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        DocsLogger.info("ContainerVC didMove parent:\(parent != nil) ", component: LogComponents.docComponent)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DocsLogger.info("ContainerVC viewWillTransition ", component: LogComponents.docComponent)
    }
}
