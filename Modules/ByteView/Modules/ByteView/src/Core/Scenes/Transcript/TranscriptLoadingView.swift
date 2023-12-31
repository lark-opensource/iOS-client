//
//  TranscriptLoadingView.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/6/26.
//

import Foundation
import ByteViewUI
import Lottie

class TranscriptLoadingView: UIView {

    private lazy var lottiView: LOTAnimationView = {
        let lov: LOTAnimationView
        if let path = Bundle.localResources.path(forResource: "transcript_loading", ofType: "json") {
            lov = LOTAnimationView(filePath: path)
        } else {
            lov = LOTAnimationView()
        }
        lov.loopAnimation = true
        return lov
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(lottiView)
        lottiView.snp.makeConstraints { make in
            make.left.equalTo(52)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        lottiView.play()
    }

    func stop() {
        lottiView.stop()
    }
}
