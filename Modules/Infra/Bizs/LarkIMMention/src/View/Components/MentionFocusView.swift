//
//  MentionFocusView.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/1/4.
//

import UIKit
import Foundation
import RustPB
import SnapKit
#if canImport(LarkFocus)
import LarkFocus

class MentionFocusView: UIView {
    var tagView = FocusTagView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tagView)
        tagView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setStatus(status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?) -> Bool {
        if let focusStatus = status?.topActive {
            tagView.config(with: focusStatus)
            return true
        } else {
            return false
        }
    }
}
#else

class MentionFocusView: UIView {
    func setStatus(status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?) -> Bool {
        if let status = status, !status.isEmpty {
            self.backgroundColor = .red
            self.snp.makeConstraints {
                $0.size.equalTo(CGSize(width: 24, height: 24))
            }
            return true
        } else {
            self.snp.removeConstraints()
            self.backgroundColor = .blue
            return false
        }
    }
}

#endif
