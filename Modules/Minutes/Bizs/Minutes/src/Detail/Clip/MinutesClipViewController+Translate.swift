//
//  MinutesClipViewController+Translate.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

extension MinutesClipViewController {

    // MARK: - showOriginalTextView
    func showOriginalTextView(_ attributedString: NSAttributedString) {

        var useAnimation: Bool = true
        if let previous = self.originalTextView {
            previous.removeFromSuperview()
            useAnimation = false
        }

        let originalTextView = MinutesOriginalTextView(frame: CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: 320))
        self.originalTextView = originalTextView

        originalTextView.contentTextView.attributedText = attributedString
        self.view.addSubview(originalTextView)

        if useAnimation {
            UIView.animate(withDuration: 0.2) {
                originalTextView.frame = CGRect(x: 0, y: self.view.bounds.height - 320, width: self.view.bounds.width, height: 320)
            }
        } else {
            originalTextView.frame = CGRect(x: 0, y: self.view.bounds.height - 320, width: self.view.bounds.width, height: 320)
        }
    }

    func exitOriginalTextViewIfNeeded() {
        originalTextView?.removeFromSuperview()
    }
}
