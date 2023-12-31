//
//  EditViewDemoController.swift
//  LarkUIKit
//
//  Created by lichen on 2018/4/8.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import EditTextView
import SnapKit

// swiftlint:disable line_length

class EditViewDemoController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextPasteDelegate {

    let editView = EditTextView()
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Edit text view"
        self.view.backgroundColor = UIColor.white

        let naviItem = UIBarButtonItem(
            title: "Insert",
            style: .done,
            target: self,
            action: #selector(insertImageAttachment))
        self.navigationItem.rightBarButtonItem = naviItem
        self.edgesForExtendedLayout = [.left, .right, .bottom]

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .center

        self.view.addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
        }

        let containerView = UIView()
        stackView.addArrangedSubview(containerView)
        containerView.backgroundColor = UIColor.red
        containerView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.greaterThanOrEqualTo(37)
        }

        editView.isScrollEnabled = false
        editView.font = UIFont.systemFont(ofSize: 18)
        editView.placeholder = "This is placeholder This is placeholder"
        editView.placeholderTextColor = UIColor.red
        editView.textColor = UIColor.yellow
        editView.text = "123123123123"
        editView.pasteDelegate = self
        editView.setAcceptablePaste(types: [UIImage.self, NSAttributedString.self])
        containerView.addSubview(editView)
        editView.snp.makeConstraints { (maker) in
            maker.left.equalTo(15)
            maker.right.equalTo(-15)
            maker.top.equalTo(5)
            maker.bottom.equalTo(-5)
            maker.height.greaterThanOrEqualTo(37)
            maker.height.lessThanOrEqualTo(125)
        }

        let emptyView = UIView()
        emptyView.backgroundColor = UIColor.orange
        stackView.addArrangedSubview(emptyView)
        emptyView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(100)
        }

        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        tableView.rowHeight = 44
        tableView.dataSource = self
        self.view.addSubview(tableView)
        tableView.backgroundColor = UIColor.blue
        tableView.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.bottom.equalTo(stackView.snp.top)
        }
        insertImageAttachment()
        imageSize = 50
    }
    var imageSize: CGFloat = 100

    @objc
    func insertImageAttachment() {
//        let attr = NSAttributedString(string: """
//            THIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A TEST STRINGTHIS IS A
//        """)
//        self.editView.insert(attr)

        ///*
        guard let attr = editView.attributedText else {
            return
        }
        let mutable = NSMutableAttributedString(attributedString: attr)
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            imageView.image = UIImage(systemName: "multiply.circle.fill")
            imageView.tintColor = .black
        }
//        imageView.backgroundColor = UIColor.red
        let attachment = CustomTextAttachment(
            customView: imageView,
            bounds: CGRect(x: 0, y: -20, width: imageSize, height: imageSize)
        )
//        let placeholder = NSTextAttachment()
//        placeholder.bounds = CGRect(origin: .zero, size: CGSize(width: 1, height: 0))
//        let place = NSAttributedString(attachment: placeholder)
//        let attachmentText = NSMutableAttributedString()
//        attachmentText.append(place)
//        let temp = NSAttributedString(attachment: attachment)
//        attachmentText.append(temp)
//        attachmentText.append(place)
        let attachmentText = NSMutableAttributedString(attachment: attachment)
//        attachmentText.addAttribute(.kern, value: 20, range: NSRange(location: 0, length: attachmentText.length))

        let select = editView.selectedRange

        if select.length == 0 {
            mutable.insert(attachmentText, at: select.location)
        } else {
            mutable.replaceCharacters(in: select, with: attachmentText)
        }
        editView.attributedText = mutable
        editView.selectedRange = NSRange(location: select.location + 1, length: 0)
         //*/
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 100
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.rowHeight = 50.0 + CGFloat(arc4random() % 50)
        tableView.reloadData()
    }
    // MARK: - UITextPasteDelegate
    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
        guard let string = itemStrings.first else {
            return NSAttributedString()
        }
        let mutableString = NSMutableAttributedString(attributedString: string)
        mutableString.fixAttributes(in: NSRange(location: 0, length: string.length))
        mutableString.addAttributes(typingAttributes, range: NSRange(location: 0, length: string.length))
        return mutableString
    }

    let typingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 17),
        .foregroundColor: UIColor.ud.N600,
        .paragraphStyle: {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            return paragraphStyle
        }()
    ]
}

extension UIImageView: AttachmentPreviewableView {}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
