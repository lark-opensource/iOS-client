//
//  SearchBar.swift
//  Alamofire
//
//  Created by weidong fu on 22/11/2017.
//

import Foundation
import SnapKit
import LarkUIKit
import SKFoundation
import SKResource
import UniverseDesignColor

public protocol SearchBarDelegate: AnyObject {
    func searchBarDidClickCancel()
    func searchBarDidActive()
    func searchContentDidChange(_ content: String)
}

public extension SearchBarDelegate {
    func searchBarDidActive() {}
}

public final class DocsHomeSearchBar: SearchBar, UITextFieldDelegate {
    public weak var delegate: SearchBarDelegate?

    public init(frame: CGRect) {
        super.init(style: .search)
        searchTextField.placeholder = BundleI18n.SKResource.Doc_Facade_Search
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        cancelButton.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldContentDidChange), name: UITextField.textDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidActive), name: UITextField.textDidBeginEditingNotification, object: nil)
        // TODO(darkmode): @wuwenjian 在 LarkSearchBar 适配前，暂时override，后续去掉
        backgroundColor = UDColor.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        if let size = cancelButton.titleLabel?.sizeThatFits(CGSize(width: 300, height: 50)) {
            let oriButtonFrame = cancelButton.frame
            let oriSearchTextField = searchTextField.frame
            let newWidth = size.width + 10
            let newX = bounds.width - newWidth
            cancelButton.frame = CGRect(x: newX, y: oriButtonFrame.minY, width: newWidth, height: oriButtonFrame.height)
            searchTextField.frame = CGRect(x: oriSearchTextField.minX, y: oriSearchTextField.minY, width: bounds.width - newWidth - 12, height: oriSearchTextField.height)
        }
    }

    @objc
    private func textFieldContentDidChange(_ notification: Notification) {
        guard let text = (notification.object as? UITextField)?.text else { return }
        delegate?.searchContentDidChange(text)
    }

    @objc
    private func textFieldDidActive(_ notification: Notification) {
        delegate?.searchBarDidActive()
    }

    @objc
    private func didClickCancel(_ sender: UIButton) {
        searchTextField.endEditing(true)
        delegate?.searchBarDidClickCancel()
    }

    override public var intrinsicContentSize: CGSize {
        return self.frame.size
    }

    public func textFieldShouldReturn(_ textField1: UITextField) -> Bool {
        spaceAssert(self.searchTextField == textField1)
        searchTextField.resignFirstResponder()
        return false
    }
}
