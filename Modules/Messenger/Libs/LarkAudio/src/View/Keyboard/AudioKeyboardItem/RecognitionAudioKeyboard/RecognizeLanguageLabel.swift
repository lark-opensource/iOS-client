//
//  RecognizeLanguageLabel.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/20.
//

import Foundation
import UIKit
import SnapKit

final class RecognizeLanguageLabel: UIView {

    var label = UILabel()

    init() {
        super.init(frame: .zero)
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.addSubview(label)

        if RecognizeLanguageManager.shared.recognitionLanguage == .un_AUTO {
            label.text = BundleI18n.LarkAudio.Lark_IM_AudioToTextDetectLanguage_DetectingNotice
        } else {
            let languageName: String = RecognizeLanguageManager.shared.recognitionLanguageI18n
            label.text = BundleI18n.LarkAudio.Lark_Chat_AudioRecognitionLanguageTip(languageName)
        }
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        label.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview()
            maker.left.equalTo(18)
        }
    }

}
