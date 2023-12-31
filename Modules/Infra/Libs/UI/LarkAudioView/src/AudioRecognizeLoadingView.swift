//
//  AudioRecognizeLoadingView.swift
//  LarkCore
//
//  Created by 李晨 on 2019/3/9.
//

import Foundation
import UIKit
import UniverseDesignColor
import LarkExtensions

public final class AudioRecognizeLoadingView: UIView {

    public let loadingIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = Resources.voiceTextLoading
        return icon
    }()
    public let loadingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N500
        return label
    }()

    public var text: String {
        didSet {
            self.loadingLabel.text = text
        }
    }

    public init(text: String) {
        self.text = text
        super.init(frame: .zero)
        self.loadingLabel.text = text
        self.addSubview(self.loadingIcon)
        self.addSubview(self.loadingLabel)
        self.loadingIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        self.loadingLabel.frame = CGRect(x: 25, y: 0, width: self.textLength, height: 20)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var attachmentBounds: CGRect {
        return CGRect(x: 0, y: 0, width: 25 + self.textLength, height: 20)
    }

    public var textLength: CGFloat {
        let size = self.loadingLabel.sizeThatFits(CGSize(width: 100, height: 20))
        return size.width
    }

    public func startAnimationIfNeeded() {
        if self.loadingIcon.layer.animation(forKey: "lu.rotateAnimation") == nil {
            self.loadingIcon.lu.addRotateAnimation()
        }
    }

    public func stopAnimation() {
        self.loadingIcon.lu.removeRotateAnimation()
    }
}
