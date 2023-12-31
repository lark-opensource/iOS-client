//
//  BaseFolderBrowerViewController.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/15.
//

import Foundation
import UIKit

class BaseFolderBrowserViewController: UIViewController {
    weak var router: FolderBrowserRouter?
    private let displayTopContainer: Bool
    private lazy var topContainer: UIView = {
        let topContainer = UIView()
        topContainer.backgroundColor = UIColor.ud.bgBody
        topContainer.autoresizingMask = .flexibleWidth
        topContainer.lu.addBottomBorder()

        let itemButton = UIButton()
        itemButton.setTitle(self.title, for: .normal)
        itemButton.setTitleColor(UIColor.ud.textCaption, for: .normal)
        itemButton.titleLabel?.lineBreakMode = .byTruncatingTail
        itemButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        itemButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        itemButton.layer.cornerRadius = 4
        topContainer.addSubview(itemButton)
        itemButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(8)
            make.right.lessThanOrEqualToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
        return topContainer
    }()
    lazy var contentContainer: UIView = {
        let contentContainer = UIView()
        contentContainer.backgroundColor = UIColor.ud.bgBody
        return contentContainer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.displayTopContainer {
            self.view.addSubview(topContainer)
            topContainer.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(44)
            }
            self.view.addSubview(contentContainer)
            contentContainer.snp.makeConstraints { (make) in
                make.top.equalTo(topContainer.snp.bottom)
                make.left.bottom.right.equalToSuperview()
            }
        } else {
            self.view.addSubview(contentContainer)
            contentContainer.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        // Do any additional setup after loading the view.
    }

    init(displayTopContainer: Bool = false) {
        self.displayTopContainer = displayTopContainer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getCanOpenWithOtherApp() -> Bool {
        return false
    }

    func getStyleButtonisHidden() -> Bool {
        return false
    }
}
