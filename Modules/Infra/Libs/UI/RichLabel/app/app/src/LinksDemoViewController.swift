//
//  LinksDemoViewController.swift
//  RichLabelDev
//
//  Created by qihongye on 2020/12/3.
//

import Foundation
import UIKit
import RichLabel

class RegularManager {
    static func linkRegular() -> NSRegularExpression? {
        var reguar: NSRegularExpression?
        do {
            reguar = try NSRegularExpression(pattern: "((http|https|ftp|ftps)://"
                                                + "([A-Za-z0-9_][-[A-Za-z0-9_]~.]{0,30}(:[A-Za-z0-9_][-[A-Za-z0-9_]~.!$*+]{0,50})?@)?"
                                                + "(([-[A-Za-z0-9_]~]){1,30}\\.){1,5}[a-z]{2,15}|(([-[A-Za-z0-9_]~])+\\.){1,5}"
                                                + "(zw|zm|za|yt|ye|xyz|xxx|xin|wtf|ws|work|wf|wang|vu|vn|vip|vi|vg|ve|vc|va|uz|uy|us|um|uk|ug|ua"
                                                + "|tz|tw|tv|tt|tr|tp|top|to|tn|tm|tl|tk|tj|th|tg|tf|td|tc|sz|sy|sx|sv|su|st|ss|sr|so|sn|sm|sl|sk|sj|site|si|shop|sh|sg|se|sd|sc|sb|sa"
                                                + "|rw|ru|rs|ro|red|re|qa|py|pw|pt|ps|pro|pr|pn|pm|pl|pk|ph|pg|pf|pe|pa|org|one|om|nz|nu|nr|np|no|nl|ni|ng|nf|net|ne|nc|name|na"
                                                + "|mz|my|mx|mw|mv|mu|mt|ms|mr|mq|mp|mobi|mo|mn|mm|ml|mk|mil|mh|mg|mf|me|md|mc|ma|ly|lv|lu|ltd|lt|ls|lr|lk|link|li|lc|lb|land|la"
                                                + "|kz|ky|kw|kr|kp|kn|km|kim|ki|kh|kg|ke|jp|jo|jm|it|is|ir|iq|io|int|ink|info|in|im|il|ie|id|hu|ht|hr|hn|hm|hk|help"
                                                + "|gy|gw|gu|gt|gs|group|gr|gp|gov|gn|gm|gl|gi|gh|gf|ge|gd|gb|ga|fr|fo|fm|fk|fj|fi|eu|et|es|er|engineering|eh|eg|ee|edu|ec"
                                                + "|dz|do|dm|dk|dj|de|cz|cy|cx|cw|cv|cu|cr|com|co|cn|cm|club|cloud|cl|ck|ci|ch|cg|cf|cc|ca|bz|by|bw|bv|bt|bs|br|bo|bn|bm|bj|biz|bi"
                                                + "|bh|bg|bf|be|bd|bb|ba|az|ax|aw|au|at|as|ar|aq|ao|an|am|al|ai|ag|af|ae|ad|ac)"
                                                +
                                                ")(:[1-9]\\d{1,4})?(/[-[A-Za-z0-9_].~:\\[\\]@!%$()*+,;=]{1,500})*/?"
                                                + "(\\?([[A-Za-z0-9_]%]{1,100}(=[[A-Za-z0-9_]\\-_.~:/\\[\\]()'*+,;%]{0,1000})?&?)*)?" + "(#([-[A-Za-z0-9_].~:@$()+=&]{0,100}))?", options: [])
        } catch { }
        return reguar
    }
}

class LinksDemoViewController: UIViewController {
    lazy var forceLayoutLKLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = UIColor.clear
        label.autoDetectLinks = true
        label.isFuzzyPointAt = true
        label.fuzzyEdgeInsets = .init(top: -10, left: -2, bottom: -10, right: -2)
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false

//        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue
//                                                            + NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        label.textCheckingDetecotor = RegularManager.linkRegular()

        label.linkAttributes = [
            .foregroundColor: UIColor.blue.cgColor
        ]
        label.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor(white: 0, alpha: 0.1)
        ]
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(forceLayoutLKLabel)
        forceLayoutLKLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(200)
            maker.left.equalTo(50)
            maker.right.equalTo(50)
        }

        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineHeightMultiple = 0
        paragraphStyle.maximumLineHeight = 0
        paragraphStyle.minimumLineHeight = font.pointSize + 2
        let attrStr = NSMutableAttributedString(
            string: """
@字节跳动，链接测试
字节跳动
字节跳动 字节跳动
https://bytedance.com/en/
bytedance.com

www.baidu.com
""",
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )

        let range = NSRange(location: 0, length: 5)
        attrStr.addAttribute(LKAtAttributeName, value: UIColor.green, range: range)

        forceLayoutLKLabel.lineSpacing = 2
        forceLayoutLKLabel.attributedText = attrStr
        forceLayoutLKLabel.rangeLinkMapper = [
            NSRange(location: 0, length: 5): URL(string: "https://bytedance.com/en/")!
        ]
        forceLayoutLKLabel.addHyperlinkStyle(links: [:])
        var textlink1 = LKTextLink(range: NSRange(location: 11, length: 4), type: .link)
        textlink1.linkTapBlock = { (_, _) in
            print("A")
        }
        forceLayoutLKLabel.addLKTextLink(link: textlink1)
        var textlink2 = LKTextLink(range: NSRange(location: 16, length: 4), type: .link)
        textlink2.linkTapBlock = { (_, _) in
            print("B")
        }
        forceLayoutLKLabel.addLKTextLink(link: textlink2)
        forceLayoutLKLabel.delegate = self
        var textlink3 = LKTextLink(range: NSRange(location: 21, length: 4), type: .link)
        textlink3.linkTapBlock = { (_, _) in
            print("C")
        }
        forceLayoutLKLabel.addLKTextLink(link: textlink3)
        forceLayoutLKLabel.delegate = self

        self.title = "LKlabel Demo"

        self.view.backgroundColor = UIColor.white
    }
}

extension LinksDemoViewController: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        print(url)
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        print(text)
        return false
    }
}
