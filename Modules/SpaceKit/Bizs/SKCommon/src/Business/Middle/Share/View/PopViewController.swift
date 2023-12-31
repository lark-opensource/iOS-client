//
//  PopViewController.swift
//  TestCollectionView
//
//  Created by 吴珂 on 2020/4/16.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import UIKit
import SnapKit
import SKFoundation
import UniverseDesignColor

public final class PopViewController: UIViewController {
    
    public var shouldDismissWhenTouchInOutsideOfContentView = true
    
    var contentView: UIView?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        //设置灰色
        modalPresentationStyle = .overCurrentContext
        view.backgroundColor = UDColor.bgMask
    }
    
    public func setContent(view contentView: UIView, padding: UIEdgeInsets) {
        self.contentView = contentView
        view.addSubview(contentView)

        contentView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(padding.left)
            make.right.equalToSuperview().offset(-padding.right)
        }
    }

    public func setContent(view contentView: UIView, with layout: (_ make: ConstraintMaker) -> Void) {
        self.contentView = contentView
        view.addSubview(contentView)
        contentView.snp.makeConstraints(layout)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        var shouldDismiss = true
        if let touch = touches.first, let contentView = contentView {
            let originPoint = touch.location(in: view)
            let transPoint = contentView.layer.convert(originPoint, from: view.layer)
            
            shouldDismiss = !contentView.bounds.contains(transPoint)
        }
        if shouldDismiss && shouldDismissWhenTouchInOutsideOfContentView {
            dismiss(animated: false, completion: nil)
        }
    }
    
    deinit {
        DocsLogger.info("deinit")
    }
}
