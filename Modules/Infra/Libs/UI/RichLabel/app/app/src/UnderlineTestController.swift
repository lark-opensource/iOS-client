//
//  UnderlineTestController.swift
//  RichLabelDev
//
//  Created by ZhangHongyun on 2021/2/10.
//

import Foundation
import UIKit
import RichLabel
import SnapKit
import UniverseDesignColor

private enum UI {
    static let singelRowHeight: CGFloat = 30
    static let manyRowHeight: CGFloat = 60
}

class UnderlineTestController: UIViewController {
    private lazy var singeleCNWordLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.clear
        label.autoDetectLinks = true
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var singeleMixWordLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var singeleENWordLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var manyCNWordsLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var manyMixWordsLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byClipping
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        label.isUserInteractionEnabled = true
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var attribute: [NSAttributedString.Key: Any] = {
        return [
            .foregroundColor: UIColor.ud.N900,
            LKLineAttributeName: LKLineStyle(color: UIColor.ud.N900.withAlphaComponent(0.60),
                                             style: .dash(width: 1.5, space: 2.0))
        ]
    }()

    private var paragraphStyle: NSMutableParagraphStyle = {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2
        return paragraphStyle
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "LKLabel Underline Demo"
        self.view.backgroundColor = UIColor.white

        let font = UIFont.systemFont(ofSize: 15)

        let singeleCNWord = "风神"
//        let singeleCNWord = "😄风神"
//        let singeleCNWord = "斜体 斜体加粗"
        let singeleCNWordAttrStr = NSMutableAttributedString(
            string: singeleCNWord,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )

        singeleCNWordAttrStr.addAttributes(attribute, range: NSRange(location: 0, length: 2))

//        singeleCNWordAttrStr.addAttributes(
//            [
//                .foregroundColor: UIColor.ud.N900,
//                LKLineAttributeName: LKLineStyle(
//                    color: UIColor.ud.N900.withAlphaComponent(0.60),
//                    position: .underLineAndStrikeThrough,
//                    style: .line
//                ),
//                .strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
//                .strikethroughColor: UIColor.black,
//                .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
//                .underlineColor: UIColor.black,
//                LKAtAttributeName: UIColor.systemBlue
//            ],
//            range: NSRange(location: 0, length: 4)
//        )

//        singeleCNWordAttrStr.addAttributes(
//            [.font: UIFont.systemFont(ofSize: 15).italic()],
//            range: NSRange(location: 0, length: 2)
//        )
//        singeleCNWordAttrStr.addAttributes(
//            [.font: UIFont.systemFont(ofSize: 15).italicBold()],
//            range: NSRange(location: singeleCNWordAttrStr.length - 4, length: 4)
//        )
        singeleCNWordLKLabel.attributedText = singeleCNWordAttrStr

        let singeleMixWord = "HR值班号"
//        let singeleMixWord = "加粗 斜体加粗"
        let singeleMixWordAttrStr = NSMutableAttributedString(
            string: singeleMixWord,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        singeleMixWordAttrStr.addAttributes(attribute, range: NSRange(location: 0, length: 5))
//        singeleMixWordAttrStr.addAttributes(
//            [.font: UIFont.systemFont(ofSize: 15).bold()],
//            range: NSRange(location: 0, length: 2)
//        )
//        singeleMixWordAttrStr.addAttributes(
//            [.font: UIFont.systemFont(ofSize: 15).italicBold()],
//            range: NSRange(location: singeleMixWordAttrStr.length - 4, length: 4)
//        )
        singeleMixWordLKLabel.attributedText = singeleMixWordAttrStr

        let singeleENWord = "TOS"
        let singeleENWordAttrStr = NSMutableAttributedString(
            string: singeleENWord,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        singeleENWordAttrStr.addAttributes(attribute, range: NSRange(location: 0, length: 3))
        singeleENWordLKLabel.attributedText = singeleENWordAttrStr

        let manyCNWords = "星云占位文字占位文字风神"
        let manyCNWordsAttrStr = NSMutableAttributedString(
            string: manyCNWords,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )
        manyCNWordsAttrStr.addAttributes(attribute, range: NSRange(location: 0, length: 2))
        manyCNWordsAttrStr.addAttributes(attribute, range: NSRange(location: manyCNWordsAttrStr.length - 2, length: 2))
        manyCNWordsLKLabel.attributedText = manyCNWordsAttrStr

//        let manyMixWords = "星云此消息已423423占赛季疯狂董藩as定间疯狂as扥矿洞狂风狂三放开 领赛发卡莱三发动晒垃圾分开算理发卡冬23季风矿洞sdfsafsdfdsfasdfadsf位文字占位文字占位文字占位文字占位文字撤回HR值班号"
        let manyMixWords = "星云此消息34已占位文字占位文字占位文字占位文字占位文字撤回HR值班号"
        let manyMixWordsAttrStr = NSMutableAttributedString(
            string: manyMixWords,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .strikethroughStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
                .strikethroughColor: UIColor.black
            ]
        )
        manyMixWordsAttrStr.addAttributes(attribute, range: NSRange(location: 0, length: 2))
        manyMixWordsAttrStr.addAttributes(attribute, range: NSRange(location: manyMixWordsAttrStr.length - 5, length: 5))
        manyMixWordsLKLabel.attributedText = manyMixWordsAttrStr
//        manyMixWordsLKLabel.outOfRangeText = NSAttributedString(string: "\u{2026}富森东方赛房东方")

        setUpSubViews()
    }

    private func setUpSubViews() {
        view.addSubview(singeleCNWordLKLabel)
        singeleCNWordLKLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(200)
            make.height.equalTo(UI.singelRowHeight)
        }

        view.addSubview(singeleENWordLKLabel)
        singeleENWordLKLabel.snp.makeConstraints { (make) in
            make.top.equalTo(singeleCNWordLKLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(UI.singelRowHeight)
        }
        view.addSubview(singeleMixWordLKLabel)
        singeleMixWordLKLabel.snp.makeConstraints { (make) in
            make.top.equalTo(singeleENWordLKLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(UI.singelRowHeight)
        }
        view.addSubview(manyCNWordsLKLabel)
        manyCNWordsLKLabel.snp.makeConstraints { (make) in
            make.top.equalTo(singeleMixWordLKLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(UI.manyRowHeight)
        }
        view.addSubview(manyMixWordsLKLabel)
        manyMixWordsLKLabel.snp.makeConstraints { (make) in
            make.top.equalTo(manyCNWordsLKLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(UI.manyRowHeight)
        }
    }

}
