//
//  ActionSheetViewController.swift
//  LarkUIKitDemo
//
//  Created by ChalrieSu on 22/01/2018.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkActionSheet

class ActionSheetViewController: UIViewController {

    private var showActionSheetButton = UIButton()
    private var showScrollableActionSheetButton = UIButton()
    private var showAlertButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        showActionSheetButton.setTitle("展示ActionSheet", for: .normal)
        showActionSheetButton.addTarget(self, action: #selector(showActionSheetButtonDidClicked), for: .touchUpInside)
        showActionSheetButton.setTitleColor(UIColor.black, for: .normal)
        showActionSheetButton.backgroundColor = UIColor.white
        view.addSubview(showActionSheetButton)
        showActionSheetButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        showAlertButton.setTitle("展示AlertViewController", for: .normal)
        showAlertButton.addTarget(self, action: #selector(showAlertButtonDidClicked), for: .touchUpInside)
        showAlertButton.setTitleColor(UIColor.black, for: .normal)
        showAlertButton.backgroundColor = UIColor.white
        view.addSubview(showAlertButton)
        showAlertButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(showActionSheetButton.snp.bottom).offset(24)
        }

        showScrollableActionSheetButton.setTitle("展示可滚动ActionSheet", for: .normal)
        showScrollableActionSheetButton.addTarget(self, action: #selector(onTappedShowScrollableActionSheet), for: .touchUpInside)
        showScrollableActionSheetButton.setTitleColor(UIColor.black, for: .normal)
        showScrollableActionSheetButton.backgroundColor = UIColor.white
        view.addSubview(showScrollableActionSheetButton)
        showScrollableActionSheetButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(showAlertButton.snp.bottom).offset(24)
        }
    }

    @objc
    private func showAlertButtonDidClicked() {

//        let alert = CustomAlertViewController(
//            title: "我是标题",
//            body: "我是对话框的正文",
//            confrimText: "OK",
//            confrimCallBack: nil
//        )

        let alert = CustomAlertViewController(
            title: "我是标题 我是标题 我是标题 我是标题 我是标题 我是标题 我是标题",
            body: "我是对话框的正文 我是对话框的正文 我是对话框的正文 我是对话框的正文 我是对话框的正文",
            leftBtnText: "Cancel",
            rightBtnText: "OK"
        )

//        let alert = UIAlertController(title: "123", message: "123", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc
    private func showActionSheetButtonDidClicked() {

        let alert = ActionSheet(title: "123")
        alert.addItem(title: "普通话", icon: UIImage(named: "selected"), action: {
            print("123")
        })
        alert.addItem(title: "456", action: {
            print("456")
        })
        alert.addRedCancelItem(title: "cancel")
        self.present(alert, animated: true, completion: {
            print("completion")
        })
    }

    @objc
    private func onTappedShowScrollableActionSheet() {
        let actionSheet = ActionSheet(title: "标题标题标题标题标题标题标题标题标题标题标题标题标")

        for i in 0 ..< 10 {
            actionSheet.addItem(title: "选项\(i+1)", action: {
                print(i)
            })
        }

        actionSheet.addRedCancelItem(title: "cancel")
        self.present(actionSheet, animated: true, completion: {
            print("completion")
        })

        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
            actionSheet.removeAllItemView()
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            for i in 0 ..< 3 {
                actionSheet.addItem(title: "选项\(i+1)", action: {
                    print(i)
                })
            }
        }
    }
}
