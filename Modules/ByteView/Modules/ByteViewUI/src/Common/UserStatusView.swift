//
//  UserFocusTagView.swift
//  ByteViewUI
//
//  Created by kiri on 2023/5/11.
//

import Foundation

public final class UserFocusTagView: UIView {
    private var view: UserFocusTagViewProtocol?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
        backgroundColor = .clear
        isUserInteractionEnabled = false
        self.view = UIDependencyManager.dependency?.createFocusTagView()
        if let view = self.view {
            addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            fatalError("user status view has not been implemented")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setCustomStatuses(_ customStatuses: [Any]) {
        if let view = self.view {
            view.setCustomStatuses(customStatuses)
            self.isHidden = view.isHidden
        } else {
            self.isHidden = true
        }
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 20)
    }
}
