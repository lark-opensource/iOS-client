//
//  AudioKeyboardContentCell.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/31.
//

import UIKit
import Foundation

final class AudioKeyboardContentCell: UICollectionViewCell {
    private weak var keyboardView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(keyboardView: UIView) {
        if keyboardView == self.keyboardView &&
            keyboardView.superview == self.contentView {
            return
        }
        if self.keyboardView?.superview == self.contentView {
            self.keyboardView?.removeFromSuperview()
        }
        self.keyboardView = keyboardView
        self.contentView.addSubview(keyboardView)
        keyboardView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
}
