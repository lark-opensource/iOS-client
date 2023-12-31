//
//  MinutesHomePageViewController+Debug.swift
//  Minutes
//
//  Created by yangyao on 2022/10/11.
//

import UIKit
import EENavigator

#if DEBUG
var debugContainerView: UIView?
var debugTextView: UITextView?
var button2: UIButton?
var button3: UIButton?
var button4: UIButton?
var debugWindow: UIWindow?

#endif


func removeDebugConsole() {
    #if DEBUG
    debugContainerView?.removeFromSuperview()
    debugContainerView = nil
    #endif
}
    
func AddToDebugConsole(_ str: String) {
    #if DEBUG
    print("\(str)")
    DispatchQueue.main.async {
        debugTextView?.text += "\n" + "\(Date()) " + str

        guard let scrollView = debugTextView else { return }

        // disable-lint: magic number
        if scrollView.contentOffset.y + scrollView.bounds.height + 50 >= scrollView.contentSize.height {
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.height)
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
        // enable-lint: magic number

    }
    #endif
}

#if DEBUG
extension MinutesHomePageViewController {
    func mock() {
        if debugContainerView == nil {
            let windowTmp = UIApplication.shared.windows.first
            debugWindow = windowTmp
            let containerView = UIView()
            debugContainerView = containerView
            debugContainerView?.isHidden = true
            debugWindow?.addSubview(containerView)

            let textView = UITextView()
            textView.isEditable = false
            textView.backgroundColor = .black
            textView.text = ""
            textView.textColor = .white
            debugTextView = textView
            debugContainerView?.addSubview(textView)

            let button2tmp = UIButton(type: .roundedRect)
            button2tmp.setTitle("show", for: .normal)
            button2tmp.addTarget(self, action: #selector(onBtnFold), for: .touchUpInside)
            debugWindow?.addSubview(button2tmp)
            button2 = button2tmp

            let button3tmp = UIButton(type: .roundedRect)
            button3tmp.setTitle("clear", for: .normal)
            button3tmp.addTarget(self, action: #selector(onBtnClear), for: .touchUpInside)
            debugWindow?.addSubview(button3tmp)
            button3 = button3tmp

            let button4tmp = UIButton(type: .roundedRect)
            button4tmp.setTitle("copy", for: .normal)
            button4tmp.addTarget(self, action: #selector(onBtnCopy), for: .touchUpInside)
            debugWindow?.addSubview(button4tmp)
            button4 = button4tmp
            
            button2tmp.snp.makeConstraints { maker in
                maker.right.equalToSuperview()
                maker.bottom.equalToSuperview().offset(-720)
            }
            button3tmp.snp.makeConstraints { maker in
                maker.right.equalToSuperview()
                maker.bottom.equalToSuperview().offset(-530)
            }
            button4tmp.snp.makeConstraints { maker in
                maker.right.equalToSuperview()
                maker.bottom.equalToSuperview().offset(-600)
            }
            textView.snp.makeConstraints { maker in
                maker.right.equalToSuperview()
                maker.top.equalToSuperview()
                maker.width.equalTo(200)
                maker.height.equalTo(300)
            }
        }
    }
    
    @objc func onBtnFold() {
        if debugContainerView?.isHidden == true {
            debugContainerView?.isHidden = false
            debugContainerView?.snp.remakeConstraints { maker in
                maker.right.equalToSuperview()
                maker.top.equalToSuperview().offset(400)
                maker.width.equalTo(200)
                maker.height.equalTo(400)
            }
        } else {
            debugContainerView?.isHidden = true
            if let superview = debugWindow {
                debugContainerView?.snp.remakeConstraints { maker in
                    maker.left.equalTo(superview.snp.right)
                    maker.top.equalToSuperview().offset(400)
                    maker.width.equalTo(200)
                    maker.height.equalTo(400)
                }
            }
        }
    }

    @objc func onBtnCopy() {
        UIPasteboard.general.string = debugTextView?.text
    }

    @objc func onBtnClear() {
        debugTextView?.text = ""
    }
}

#endif

