//
//  SheetUploadImageViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/12/23.
//  用在 toolkit 工具箱里面的上传图片

import Foundation
import LarkUIKit
import Photos
import Kingfisher
import SKBrowser
import SKCommon
import SKResource
import LarkAssetsBrowser
import SKFoundation

protocol SheetUploadImageViewControllerDelegate: AnyObject {
    var rootVC: UIViewController? { get }
    var distanceToWindowBottom: CGFloat { get }
    func didFinishPickingMedia(params: [String: Any])
    func exitUploadImageController()
}

class SheetUploadImageViewController: SheetBaseToolkitViewController, SKPickMediaDelegate {

    weak var delegate: SheetUploadImageViewControllerDelegate?

    private var uploadManager: SKPickMediaManager?

    private var suiteView: AssetPickerSuiteView?

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.uploadImage.rawValue
    }

    init(delegate: SheetUploadImageViewControllerDelegate, info: ToolBarItemInfo) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        let cameraType: CameraType = UserScopeNoChangeFG.LJW.cameraStoragePermission ? .systemAutoSave(true) : .system
        let uploadImageManager = SKPickMediaManager(delegate: self,
                                                    assetType: .imageOnly(maxCount: 1),
                                                    cameraType: cameraType,
                                                    rootVC: delegate.rootVC)
        self.uploadManager = uploadImageManager
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(navigationBarHeight)
            make.top.equalToSuperview().offset(draggableViewHeight)
            make.left.equalToSuperview()
        }
        navigationBar.setTitleText(info.title)
        let newSuiteView = uploadImageManager.suiteView
        suiteView = newSuiteView
        view.addSubview(newSuiteView)
        newSuiteView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        newSuiteView.addGestureRecognizer(pan)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let bottom = delegate?.distanceToWindowBottom,
           bottom > 0,
           let pickView = suiteView?.subviews.first(where: { $0 is PhotoPickView }) as? PhotoPickView {
            pickView.bottomOffset = 0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        guard let suiteView = suiteView else { return }
        let point = gesture.location(in: suiteView)
        if gesture.state == .began {
            navBarGestureDelegate?.panBegin(point, allowUp: allowUpDrag)
        } else if gesture.state == .changed {
            navBarGestureDelegate?.panMove(point, allowUp: allowUpDrag)
        } else {
            navBarGestureDelegate?.panEnd(point, allowUp: allowUpDrag)
        }
    }

    func didFinishPickingMedia(params: [String: Any]) {
        delegate?.didFinishPickingMedia(params: params)
    }
    
    override func willExistControllerByUser() {
        delegate?.exitUploadImageController()
    }
}
