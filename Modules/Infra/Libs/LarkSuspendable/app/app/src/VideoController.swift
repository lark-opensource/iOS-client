//
//  VideoController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/11.
//

import Foundation
import UIKit
import LarkSuspendable

class VideoController: UIViewController {

    var videoView: UIView

    var onFold: ((UIView) -> Void)?

    lazy var finishButton: UIButton = {
        var button = UIButton()
        button.setTitle("结束通话", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        button.layer.cornerRadius = 25
        return button
    }()

    lazy var foldButton: UIButton = {
        var button = UIButton()
        button.setTitle("缩小", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(didTapFoldButton), for: .touchUpInside)
        return button
    }()

    init(videoView video: UIView? = nil) {
        self.videoView = video ?? VideoView()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoView)
        view.addSubview(foldButton)
        view.addSubview(finishButton)
        videoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        foldButton.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(30)
            make.leading.equalToSuperview().offset(10)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        finishButton.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
    }

    @objc
    private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    private func didTapFoldButton() {
        onFold?(videoView)

    }

}
