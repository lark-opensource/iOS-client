//
//  ViewController.swift
//  LarkPopoverKitDev
//
//  Created by 李晨 on 2020/3/19.
//

import Foundation
import UIKit
import LarkPopoverKit
import RxSwift
import SnapKit

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    var popoverTransition: PopoverTransition?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.green
        let btn1 = UIButton()
        btn1.frame = CGRect(x: 100, y: 100, width: 200, height: 44)
        btn1.setTitle("none", for: .normal)
        btn1.backgroundColor = UIColor.red
        btn1.addTarget(self, action: #selector(clickBtn1(sender:)), for: .touchUpInside)
        self.view.addSubview(btn1)

        let btn2 = UIButton()
        btn2.frame = CGRect(x: 100, y: 200, width: 200, height: 44)
        btn2.setTitle("fullScreen", for: .normal)

        btn2.backgroundColor = UIColor.red
        btn2.addTarget(self, action: #selector(clickBtn2(sender:)), for: .touchUpInside)
        self.view.addSubview(btn2)

        let btn3 = UIButton()
        btn3.frame = CGRect(x: 100, y: 300, width: 200, height: 44)
        btn3.setTitle("overFullScreen", for: .normal)
        btn3.backgroundColor = UIColor.red
        btn3.addTarget(self, action: #selector(clickBtn3(sender:)), for: .touchUpInside)
        self.view.addSubview(btn3)

        let btn4 = UIButton()
        btn4.frame = CGRect(x: 100, y: 400, width: 200, height: 44)
        btn4.setTitle("system popover", for: .normal)
        btn4.backgroundColor = UIColor.red
        btn4.addTarget(self, action: #selector(clickBtn4(sender:)), for: .touchUpInside)
        self.view.addSubview(btn4)

        let btn5 = UIButton()
        btn5.frame = CGRect(x: 100, y: 500, width: 200, height: 44)
        btn5.setTitle("system auto", for: .normal)
        btn5.backgroundColor = UIColor.red
        btn5.addTarget(self, action: #selector(clickBtn5(sender:)), for: .touchUpInside)
        self.view.addSubview(btn5)
    }

    @objc
    func clickBtn1(sender: UIButton) {
        let transitioningDelegate = PopoverTransition(sourceView: sender)
        transitioningDelegate.presentStypeInCompact = .none
        popoverTransition = transitioningDelegate
        let vc = ViewController2()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitioningDelegate
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func clickBtn2(sender: UIButton) {
        let transitioningDelegate = PopoverTransition(sourceView: sender)
        transitioningDelegate.presentStypeInCompact = .fullScreen
        popoverTransition = transitioningDelegate
        let vc = ViewController2()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitioningDelegate
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func clickBtn3(sender: UIButton) {
        let transitioningDelegate = PopoverTransition(sourceView: sender)
        transitioningDelegate.presentStypeInCompact = .overFullScreen
        popoverTransition = transitioningDelegate
        let vc = ViewController2()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = transitioningDelegate
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func clickBtn4(sender: UIButton) {
        let vc = ViewController2()
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.delegate = self
        vc.popoverPresentationController?.sourceView = sender
        self.present(vc, animated: true, completion: nil)
    }

    @objc
    func clickBtn5(sender: UIButton) {
        let vc = ViewController2()
        self.present(vc, animated: true, completion: nil)
    }

//    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
//        return .none
//    }
}

class ViewController2: UIViewController {

    var whiteBGView = UIView()

    let disposeBag = DisposeBag()

    var top: Constraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear

        whiteBGView.backgroundColor = UIColor.white
        self.view.addSubview(whiteBGView)
        whiteBGView.snp.makeConstraints { (maker) in
            maker.bottom.left.right.equalToSuperview()
            top = maker.top.equalToSuperview().offset(100).constraint
        }

        let btn1 = UIButton()
        btn1.setTitle("dismiss", for: .normal)
        btn1.backgroundColor = UIColor.red
        btn1.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)
        whiteBGView.addSubview(btn1)
        btn1.snp.makeConstraints { (maker) in
            maker.top.equalTo(100)
            maker.left.equalTo(100)
            maker.right.equalTo(-100)
            maker.height.equalTo(44)
        }

        let btn2 = UIButton()
        btn2.setTitle("change size", for: .normal)
        btn2.backgroundColor = UIColor.red
        btn2.addTarget(self, action: #selector(clickBtn2), for: .touchUpInside)
        whiteBGView.addSubview(btn2)
        btn2.snp.makeConstraints { (maker) in
            maker.top.equalTo(200)
            maker.left.equalTo(100)
            maker.right.equalTo(-100)
            maker.height.equalTo(44)
        }
        print("viewDidLoad isInPoperover \(self.isInPoperover)")

        self.preferredContentSize = CGSize(width: 320, height: 320)

        self.isInPopoverObservable().subscribe(onNext: { [weak self] (isInPoperOver) in
            print("isInPopoverObservable isInPoperover \(isInPoperOver)")
            self?.updateBGView()
        }).disposed(by: self.disposeBag)
    }

    @objc
    func clickBtn() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    func clickBtn2() {
        var size = self.preferredContentSize
        size.height += 50
        self.preferredContentSize = size
    }

    func updateBGView() {
        if self.view.bounds.height < 800 {
            top.update(offset: 0)
        } else {
            top.update(offset: 100)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear isInPoperover \(self.isInPoperover)")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("viewWillTransition isInPoperover \(self.isInPoperover)")
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print("willTransition")
        super.willTransition(to: newCollection, with: coordinator)
    }
}


