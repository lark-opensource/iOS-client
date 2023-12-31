//
//  AtPickerHeaderView.swift
//  LarkChat
//
//  Created by Yuri on 2023/7/19.
//

import UIKit
import SnapKit

class AtPickerHeaderView: UIView {

    struct State {
        var hasAi: Bool = false
        var hasAll: Bool = false
    }

    let stackView = UIStackView()

    private var atAllView: AtPickerAtAllView
    private var myAiView: AtPickerMyAiView

    var state: State = State() {
        didSet {
            self.myAiView.isHidden = !state.hasAi
            self.atAllView.isHidden = !state.hasAll
        }
    }

    init(atAllView: AtPickerAtAllView, myAiView: AtPickerMyAiView) {
        self.atAllView = atAllView
        self.myAiView = myAiView
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(myAiView)
        stackView.addArrangedSubview(atAllView)

        myAiView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(68)
        }
        atAllView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(68)
        }
        self.snp.makeConstraints {
            $0.bottom.equalTo(stackView.snp.bottom)
        }
    }
}
