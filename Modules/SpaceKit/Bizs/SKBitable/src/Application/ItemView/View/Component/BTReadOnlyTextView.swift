//
// Created by duanxiaochen.7 on 2021/12/12.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignColor


protocol BTReadOnlyTextViewDelegate: AnyObject {
    func readOnlyTextViewDidFinishLayout(_: BTReadOnlyTextView)
    func readOnlyTextView(_: BTReadOnlyTextView, handleTapFromSender: UITapGestureRecognizer)
}

extension BTReadOnlyTextViewDelegate {
    func readOnlyTextViewDidFinishLayout(_: BTReadOnlyTextView) {}
}

final class BTReadOnlyTextView: SKBaseTextView, NSLayoutManagerDelegate {

    weak var btDelegate: BTReadOnlyTextViewDelegate?

    var tapGesture: UITapGestureRecognizer

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        tapGesture = UITapGestureRecognizer()
        super.init(frame: frame, textContainer: textContainer)
        addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(textViewTapped(sender:)))
        initialTextView()
    }

    private func initialTextView() {
        backgroundColor = .clear
        autocorrectionType = .no
        isScrollEnabled = false
        isSelectable = false
        isEditable = false
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        layoutManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        btDelegate?.readOnlyTextViewDidFinishLayout(self)
    }

    @objc
    private func textViewTapped(sender: UITapGestureRecognizer) {
        btDelegate?.readOnlyTextView(self, handleTapFromSender: sender)
    }
}
