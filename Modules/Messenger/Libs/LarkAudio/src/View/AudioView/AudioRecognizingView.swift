//
//  AudioRecognizingView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/7/3.
//

import Foundation
import UIKit
import EditTextView

final class AudioRecognizingView: UIView, AttachmentPreviewableView {

    let loadingIcon: UIImageView = {
        let icon = UIImageView()
        icon.animationImages = [
            Resources.loading1,
            Resources.loading2,
            Resources.loading3
        ]
        icon.animationDuration = 1.5
        icon.contentMode = .scaleAspectFit
        return icon
    }()
    let loadingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    var text: String {
        didSet {
            self.loadingLabel.text = text
            self.updateComponentFrame()
        }
    }

    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        self.loadingLabel.text = text
        self.addSubview(self.loadingIcon)
        self.addSubview(self.loadingLabel)
        self.updateComponentFrame()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateComponentFrame() {
        self.loadingLabel.frame = CGRect(x: 0, y: 0, width: self.textLength, height: 20)
        if self.textLength > 0 {
            self.loadingIcon.frame = CGRect(x: self.textLength + 5, y: 0, width: 20, height: 18)
        } else {
            self.loadingIcon.frame = CGRect(x: 5, y: 0, width: 20, height: 20)
        }
    }

    var attachmentBounds: CGRect {
        return CGRect(x: 0, y: 0, width: 27 + self.textLength, height: 18)
    }

    var textLength: CGFloat {
        let size = self.loadingLabel.sizeThatFits(CGSize(width: 100, height: 18))
        return size.width
    }

    func startAnimationIfNeeded() {
        self.loadingIcon.startAnimating()
    }
}
