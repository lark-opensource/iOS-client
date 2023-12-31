//
//  InputPwdView.swift
//  SuiteLogin
//
//  Created by sniperj on 2019/5/14.
//

import Foundation
import UIKit
import LarkUIKit

let numberOfPwd = 4
let collectionViewCellIdentifier = "password"

class InputPwdView: UIView, UITextFieldDelegate {

    public var isShowExisting: Bool = false {
        didSet {
            collectionView.reloadData()
        }
    }

    public var pwdFinishBlock: ((Bool) -> Void)?

    public var pwd: String?

    private let textField = UITextField()
    private lazy var collectionView: UICollectionView = { [weak self] in
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: frame.width / 4, height: frame.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: self?.bounds ?? .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        if let self = self {
            collectionView.dataSource = self
        }
        collectionView.register(InputPwdCell.self, forCellWithReuseIdentifier: collectionViewCellIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = false
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        textField.addTarget(self, action: #selector(textFieldEditingChanged), for: .editingChanged)
        textField.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.tintColor = .clear
        textField.textColor = .clear
        self.addSubview(collectionView)
        self.addSubview(textField)
        self.becomeFirstResponder()
        self.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
    }

    public func clearTextField() {
        textField.text = nil
        pwd = nil
        collectionView.reloadData()
    }

    @objc
    func tapAction() {
        self.becomeFirstResponder()
    }

    @objc
    func textFieldEditingChanged(_ textField: UITextField) {
        if let password = textField.text {
            if password.count > numberOfPwd {
                textField.text = password.substring(to: numberOfPwd)
            }
            pwd = textField.text
            collectionView.reloadData()
            if pwd?.count == numberOfPwd {
                pwdFinishBlock?(true)
            } else {
                pwdFinishBlock?(false)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var canBecomeFirstResponder: Bool {
        return true
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}

extension InputPwdView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPwd
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell: InputPwdCell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as? InputPwdCell else {
            return UICollectionViewCell(frame: .zero)
        }

        if isShowExisting {
            if indexPath.row < pwd?.count ?? 0 {
                if let password = pwd {
                    let index = password.index(password.startIndex, offsetBy: indexPath.row)
                    collectionViewCell.fillContent(fill: true, num: String(password[index]))
                }
            } else {
                collectionViewCell.fillContent(fill: false, num: nil)
            }
        } else {
            if indexPath.row < pwd?.count ?? 0 {
                collectionViewCell.fillContent(fill: true)
            } else {
                collectionViewCell.fillContent(fill: false)
            }
        }

        return collectionViewCell
    }

}

extension InputPwdView {
    struct Layout {
        static let height: CGFloat = 20
        static let width: CGFloat = { CGFloat(numberOfPwd) * (Layout.height + Layout.internalSpace) }()
        static let internalSpace: CGFloat = 34
    }
}

private class InputPwdCell: UICollectionViewCell {

    let blackView = UIView()
    let grayView = UIView()
    let numLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        blackView.frame = CGRect(x: (self.frame.width - self.frame.height) / 2, y: 0, width: self.frame.height, height: self.frame.height)
        blackView.backgroundColor = UIColor.ud.iconN1 //lk.css("#3e4759")
        blackView.layer.cornerRadius = self.frame.height / 2
        blackView.isHidden = true
        self.addSubview(blackView)

        grayView.frame = CGRect(x: (self.frame.width - self.frame.height) / 2, y: 0, width: self.frame.height, height: self.frame.height)
        grayView.backgroundColor = UIColor.ud.textDisabled  // lk.css("#ededf0")
        grayView.layer.cornerRadius = self.frame.height / 2
        grayView.isHidden = true
        self.addSubview(grayView)

        numLabel.frame = grayView.frame
        numLabel.textColor = UIColor.ud.textCaption //lk.css("#141f33")
        numLabel.textAlignment = .center
        numLabel.font = UIFont.systemFont(ofSize: 20)
        numLabel.isHidden = true
        self.addSubview(numLabel)
    }

    public func fillContent(fill: Bool) {
        numLabel.isHidden = true
        if fill {
            blackView.isHidden = false
            grayView.isHidden = true
        } else {
            blackView.isHidden = true
            grayView.isHidden = false
        }
    }

    public func fillContent(fill: Bool, num: String?) {
        blackView.isHidden = true
        numLabel.text = num
        if fill {
            numLabel.isHidden = false
            grayView.isHidden = true
        } else {
            numLabel.isHidden = true
            grayView.isHidden = false
        }
    }
}
