//
//  OCRExtractController.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/8/23.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit
import UniverseDesignIcon
import LKCommonsLogging
import LKCommonsTracker

final class OCRExtractController: UIViewController, UITextViewDelegate {
    static let logger = Logger.log(OCRExtractController.self, category: "LarkOCR")

    let textView: ExtractTextView = ExtractTextView()

    let result: NSAttributedString

    weak var delegate: ImageOCRDelegate?

    var menuItems: [UIMenuItem] = [
        UIMenuItem(title: BundleI18n.LarkOCR.Lark_IM_ImageToText_Copy_Button_Mobile, action: #selector(OCRExtractController.copyResult)),
        UIMenuItem(title: BundleI18n.LarkOCR.Lark_IM_ImageToText_Forward_Button_Mobile, action: #selector(OCRExtractController.forwardResult))
    ]

    init(result: NSAttributedString, delegate: ImageOCRDelegate?) {
        self.result = result
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIMenuController.shared.menuItems = []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkOCR.Lark_IM_ImageToText_ExtractText_Title
        self.view.backgroundColor = UDColor.bgBase

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: BundleI18n.LarkOCR.Lark_IM_ImageToText_ExtractText_Close_Button,
            style: .plain,
            target: self,
            action: #selector(closeVC)
        )

        self.textView.isEditable = false
        var attributedText = NSMutableAttributedString(attributedString: self.result)
        var para = NSMutableParagraphStyle()
        para.lineSpacing = 4
        para.paragraphSpacing = 8
        attributedText.addAttribute(
            .paragraphStyle,
            value: para,
            range: .init(location: 0, length: attributedText.length)
        )
        self.textView.attributedText = attributedText
        self.textView.font = UIFont.systemFont(ofSize: 16)
        self.textView.vc = self
        self.textView.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.textView.textContainerInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        } else {
            self.textView.textContainerInset = .init(top: 16, left: 12, bottom: 16, right: 12)
        }
        self.view.addSubview(self.textView)
        self.textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        Tracker.post(TeaEvent("public_identity_select_accurate_character_view"))
    }

    @objc
    private func closeVC() {
        Self.logger.info("click close btn in extract vc")
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc
    func forwardResult() {
        guard let selectedRange = self.textView.selectedTextRange,
              let text = self.textView.text(in: selectedRange) else {
            return
        }
        self.textView.resignFirstResponder()
        self.textView.selectedTextRange = nil
        Self.logger.info("click forward btn in extract vc")
        Tracker.post(TeaEvent("public_identity_select_accurate_character_click", params: ["click": "forward", "target": "public_multi_select_share_view"]))
        self.delegate?.ocrResultForward(result: text, from: self, dismissCallback: { [weak self] result in
            if result {
                var vc = self?.presentingViewController
                self?.dismiss(animated: false, completion: {
                    vc?.dismiss(animated: false)
                })
            }
        })
    }

    @objc
    func copyResult() {
        guard let selectedRange = self.textView.selectedTextRange,
              let text = self.textView.text(in: selectedRange) else {
            return
        }
        self.textView.resignFirstResponder()
        self.textView.selectedTextRange = nil
        Self.logger.info("click copy btn in extract vc")
        Tracker.post(TeaEvent("public_identity_select_accurate_character_click", params: ["click": "copy", "target": "none"]))

        self.delegate?.ocrResultCopy(result: text, from: self, dismissCallback: { [weak self] result in
            if result {
                var vc = self?.presentingViewController
                self?.dismiss(animated: false, completion: {
                    vc?.dismiss(animated: false)
                })
            }
        })
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.selectedRange.length > 0 {
            UIMenuController.shared.menuItems = self.menuItems
        } else {
            UIMenuController.shared.menuItems = []
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            var urlStr = URL.absoluteString
            if urlStr.hasPrefix("tel://") {
                Self.logger.info("click tel link in extract vc")
                let number = (urlStr as NSString).replacingOccurrences(of: "tel://", with: "")
                self.delegate?.ocrResultTapNumber(number: number, from: self, dismissCallback: { [weak self] result in
                    if result {
                        var vc = self?.presentingViewController
                        self?.dismiss(animated: false, completion: {
                            vc?.dismiss(animated: false)
                        })
                    }
                })
            } else {
                Self.logger.info("click url link in extract vc")
                self.delegate?.ocrResultTapLink(link: urlStr, from: self, dismissCallback: { [weak self] result in
                    if result {
                        var vc = self?.presentingViewController
                        self?.dismiss(animated: false, completion: {
                            vc?.dismiss(animated: false)
                        })
                    }
                })
            }
        }
        return false
    }

}

final class ExtractTextView: UITextView {
    weak var vc: OCRExtractController?

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(OCRExtractController.forwardResult) ||
            action == #selector(OCRExtractController.copyResult),
           self.selectedRange.length > 0 {
            return true
        }
        return false
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == #selector(OCRExtractController.forwardResult) ||
            aSelector == #selector(OCRExtractController.copyResult) {
            if self.selectedRange.length > 0 {
                return vc
            } else {
                return nil
            }
        }
        return super.forwardingTarget(for:aSelector)
    }
}
