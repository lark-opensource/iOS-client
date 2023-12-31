//
//  ChoiceSearchContainerView.swift
//  ByteView
//
//  Created by Zipei Shuai on 2022/9/8.
//
import SnapKit

class ChoiceSearchContainerView: SearchContainerView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        loadingView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }
        noResultDefaultView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-4)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
