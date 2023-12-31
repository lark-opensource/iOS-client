//
//  ShowOriginButton.swift
//  LarkAssetsBrowser
//
//  Created by qihongye on 2021/8/2.
//

import UIKit
import Foundation

final class ShowOriginButton: UILabel {
    enum State {
        case start(key: String, fileSize: UInt64)
        case progress(key: String, value: Float)
        case end(key: String)
    }

    var state: State = .start(key: "", fileSize: 0) {
        didSet {
            setupState(state)
        }
    }

    var activeKey: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.textAlignment = .center
        self.numberOfLines = 1
        setupState(state)
    }

    init(fileSize: UInt64) {
        super.init(frame: .zero)
        self.textAlignment = .center
        self.numberOfLines = 1
        setupState(state)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: 30 + size.width, height: size.height)
    }

    func setupState(_ state: State) {
        switch state {
        case .start(let key, let fileSize):
            if key != activeKey {
                return
            }
            if fileSize > 0 {
                self.text = "\(BundleI18n.LarkAssetsBrowser.Lark_Legacy_FullImage) (\(convertFileSizeToString(fileSize)))"
            } else {
                self.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_FullImage
            }
        case .progress(let key, let value):
            if key != activeKey {
                return
            }
            self.text = "\(value < 1 ? Int(value * 100) : 100)%"
        case .end(let key):
            if key != activeKey {
                return
            }
            self.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_Loaded
        }
    }

    private func convertFileSizeToString(_ fileSize: UInt64) -> String {
        if fileSize < 1_024 {
            return "\(fileSize)B"
        }
        let fileSizeKB = CGFloat(fileSize / 1_024)
        if fileSizeKB < 1_024 {
            return String(format: "%.0fKB", fileSizeKB)
        }
        let fileSizeMB = fileSizeKB / 1_024
        if fileSizeMB < 1_024 {
            return String(format: "%.2fMB", fileSizeMB)
        }
        return String(format: "%.2fGB", fileSizeMB / 1_024)
    }
}
