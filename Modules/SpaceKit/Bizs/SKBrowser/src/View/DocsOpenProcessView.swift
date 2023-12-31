//
//  DocsOpenInfoView.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/20.
//

import Foundation
import SnapKit
import SKCommon
import SKUIKit
import UniverseDesignToast
import SKInfra
import LarkEMM

/// 打开文档时，展示给用户的当前文档打开的信息，用于调试
class DocsOpenProcessView: UIView {
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        return textView
    }()

    private var tapGesture: UITapGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateInfo(_ info: String) {
        DispatchQueue.main.async {
            self.textView.text = "双击可以复制 \n\n" + info
        }
    }

    @objc
    private func onDoubleTap() {
        //debug下使用，用默认的defaultConfig管控
        SCPasteboard.general(SCPasteboard.defaultConfig()).string = textView.text
        self.removeFromSuperview()
        UDToast.showSuccess(with: "复制成功", on: self)
    }
}
