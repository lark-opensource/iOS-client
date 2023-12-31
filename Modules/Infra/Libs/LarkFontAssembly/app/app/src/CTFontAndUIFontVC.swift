//
//  CTFontAndUIFontVC.swift
//  LarkFontAssemblyDev
//
//  Created by 白镜吾 on 2023/4/17.
//

import UIKit
import UniverseDesignFont

class CTFontAndUIFontVC: UIViewController {
    lazy var textField = UITextField()

    lazy var label0 = UILabel()
    lazy var label1 = UILabel()
    lazy var label2 = UITextView()
    lazy var label3 = UITextView()
    lazy var line = UIView()
    //    lazy var textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        let text = "ỎẲ Abcg13你好"
        self.view.backgroundColor = .ud.bgBase
        self.view.addSubview(label0)
        self.view.addSubview(label1)
        self.view.addSubview(label2)
        self.view.addSubview(label3)
        self.view.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.width.equalTo(300)
            make.height.equalTo(30)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }
        textField.borderStyle = .none
        textField.text = text
        textField.font = UIFont.ud.systemFont(ofSize: 20)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            self.view.endEditing(true)
        })
        //        label1.snp.makeConstraints { make in
        //            make.width.equalTo(300)
        ////            make.height.equalTo(100)
        //            make.centerX.equalToSuperview()
        //            make.top.equalToSuperview().offset(150)
        //        }
        //        label0.snp.makeConstraints { make in
        //            make.width.equalTo(300)
        ////            make.height.equalTo(100)
        //            make.centerX.equalToSuperview()
        //            make.top.equalTo(label1.snp.bottom).offset(12)
        //        }
        //        label2.snp.makeConstraints { make in
        //            make.width.equalTo(300)
        //            make.height.equalTo(90)
        //            make.centerX.equalToSuperview()
        //            make.top.equalTo(label0.snp.bottom).offset(12)
        //        }
        //        label3.snp.makeConstraints { make in
        //            make.width.equalTo(300)
        //            make.height.equalTo(90)
        //            make.centerX.equalToSuperview()
        //            make.top.equalTo(label2.snp.bottom).offset(12)
        //        }
        label0.font = UIFont.systemFont(ofSize: 32)
        //        label0.text = text
        label0.attributedText = getAttr(UIFont.ud.boldSystemFont(ofSize: 28))
        label0.numberOfLines = 2
        let fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle:.body)
        let font = UIFont(descriptor: fontDescriptor, size: 0)

        //        print(UIFont.fontNames(forFamilyName: "PingFang SC"))
        label1.font = UIFont.ud.systemFont(ofSize: 32)
        label1.text = text
        label1.numberOfLines = 2
        //        label1.backgroundColor = .systemPink
        //        label1.attributedText = getAttr(UIFont.systemFont(ofSize: 28))
        //        label1.clipsToBounds = true
        //        label1.layer.masksToBounds = true

        label2.font = UIFont.ud.systemFont(ofSize: 28)
        label2.text = text
        //        label2.backgroundColor = .gray
        //        label2.attributedText = getAttr(UIFont.systemFont(ofSize: 28))
        label2.textContainerInset = .zero//UIEdgeInsets(edges: 10)
        //        label2.contentInset = .zero
        //        label2.numberOfLines = 0

        //        let font1 = UIFont(name: "PingFang SC", size: 36)
        //        let font2 = UIFont(name: "PingFangSC-Medium", size: 36)

        label3.font = UIFont.systemFont(ofSize: 28)
        label3.text = text
        //        label3.isEditable = true
        //        label3.attributedText = getAttr(UIFont.systemFont(ofSize: 28))
        label3.textContainerInset = .zero//UIEdgeInsets(edges: 10)
        //        label3.numberOfLines = 0

        label0.showGrid = true
        label1.showGrid = true
        label2.showGrid = true
        label3.showGrid = true

        label0.backgroundColor = .yellow
        label1.backgroundColor = .gray
        label2.backgroundColor = .red
        label3.backgroundColor = .blue

        label0.layer.masksToBounds = true
        label1.layer.masksToBounds = true
    }

    var defaultTypingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.ud.boldSystemFont(ofSize: 17),
        .foregroundColor: UIColor.ud.N600,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            return paragraphStyle
        }()
    ]

    //    func createCTFontWith(font: CTFont, size: CGFloat) -> CTFont {
    //        var symbolicTrait: UInt32 = 0
    //        var fontName: CFString = UIFont.systemFont(ofSize: size).fontName as CFString
    //        fontName = UIFont.boldSystemFont(ofSize: size).fontName as CFString
    //        return CTFontCreateWithName("PingFangSC-Medium" as CFString, size, nil)
    //    }

    enum FontWeight {
        case bold
        case normal
    }

    func createCTFontWith(font: CTFont, size: CGFloat, weight: FontWeight) -> CTFont {

        var symbolicTrait: UInt32 = 0
        switch weight {
        case .bold:
            symbolicTrait += CTFontSymbolicTraits.traitBold.rawValue
        default:
            break
        }

        let traits: [CFString: Any] = [
            kCTFontSymbolicTrait: NSNumber(value: symbolicTrait),
            kCTFontWeightTrait: NSNumber(value: UIFont.Weight.medium.rawValue)
        ]
        let attributes = NSMutableDictionary(
            dictionary: CTFontDescriptorCopyAttributes(CTFontCopyFontDescriptor(font))
        )
        attributes[kCTFontTraitsAttribute] = traits
        if attributes[kCTFontNameAttribute] != nil {
            attributes.removeObject(forKey: kCTFontNameAttribute)
        }
        if attributes[kCTFontFamilyNameAttribute] == nil {
            attributes[kCTFontFamilyNameAttribute] = CTFontCopyFamilyName(font)
        }

        return CTFontCreateWithFontDescriptor(
            CTFontDescriptorCreateWithAttributes(attributes),
            size,
            nil
        )
    }

    func getAttr(_ font: UIFont) -> NSAttributedString {
        let fontFigmaHeight = font.figmaHeight
        let baselineOffset = (fontFigmaHeight - font.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontFigmaHeight
        paragraphStyle.maximumLineHeight = fontFigmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        return NSAttributedString(
            string: "Ỏ Ẳ 123 你好",
            attributes: defaultTypingAttributes
        )
    }
}
