//
//  SCDebugTextViewController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/28.
//

import Foundation
import LarkSecurityComplianceInfra
import UniverseDesignColor
import UniverseDesignIcon

class SCDebugTextViewController: UIViewController {
    var getText: (() -> String)?

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.placeholder = "请输入"
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }()

    let textView: SCDebugTextView = {
        let view = SCDebugTextView()
        view.backgroundColor = .white
        view.isEditable = false
        view.isSelectable = true
        view.contentInset = UIEdgeInsets(horizontal: 5, vertical: 5)
        view.font = UIFont.systemFont(ofSize: 14)
        view.keyboardDismissMode = .onDrag
        return view
    }()

    let searchBarPreButton: UIButton = {
        let searchBarPreButton = UIButton()
        let preIcon = UDIcon.getIconByKey(.leftOutlined).ud.withTintColor(.systemBlue)
        searchBarPreButton.setImage(preIcon, for: .normal)
        return searchBarPreButton
    }()

    let searchBarNextButton: UIButton = {
        let searchBarNextButton = UIButton()
        let nextIcon = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(.systemBlue)
        searchBarNextButton.setImage(nextIcon, for: .normal)
        return searchBarNextButton
    }()

    private var searchRanges: [NSRange] = []{
        didSet {
            textView.textStorage.removeAttribute(.backgroundColor,
                                                 range: .init(location: 0, length: textView.textStorage.length))
            searchRanges.forEach {
                textView.textStorage.addAttributes([.backgroundColor: UIColor.orange], range: $0)
            }
            if searchRanges.isEmpty {
                focusRangeIndex = nil
            } else {
                focusRangeIndex = 0
            }
        }

    }

    private var focusRangeIndex: Int? {
        didSet {
            guard let focusRangeIndex else { return }
            if let oldValue = oldValue {
                let oldFocusRange = searchRanges[oldValue]
                self.textView.textStorage.addAttributes([.backgroundColor: UIColor.orange],
                                                        range: oldFocusRange)
            }
            let currentFocusRange = searchRanges[focusRangeIndex]
            self.textView.textStorage.addAttributes([.backgroundColor: UIColor.yellow],
                                                    range: currentFocusRange)
            textView.scrollRangeToVisible(currentFocusRange)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        let containerView = UIView()
        view.addSubview(containerView)
        containerView.addSubview(searchBar)
        containerView.addSubview(searchBarPreButton)
        containerView.addSubview(searchBarNextButton)
        containerView.addSubview(textView)

        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(4)
        }
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin)
            $0.left.equalToSuperview()
            $0.right.equalToSuperview().inset(60)
            $0.height.equalTo(40)
        }
        searchBarPreButton.snp.makeConstraints {
            $0.top.bottom.equalTo(searchBar)
            $0.left.equalTo(searchBar.snp.right).offset(0)
            $0.width.equalTo(20)
        }
        searchBarNextButton.snp.makeConstraints {
            $0.top.bottom.equalTo(searchBar)
            $0.left.equalTo(searchBarPreButton.snp.right).offset(10)
            $0.width.equalTo(20)
        }
        textView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        searchBar.delegate = self
        searchBarPreButton.addTarget(self, action: #selector(goToPreRange(_:)), for: .touchUpInside)
        searchBarNextButton.addTarget(self, action: #selector(goToNextRange(_:)), for: .touchUpInside)
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh,
                                            target: self,
                                            action: #selector(refreshButtonClicked(_:)))
        navigationItem.rightBarButtonItem = refreshButton
        updateUI()
    }

    private func updateUI() {
        textView.text = getText?()
        if let searchText = searchBar.text {
            searchBar(searchBar, textDidChange: searchText)
        }
    }

    private func changeFocus(isNext: Bool) {
        guard let focusRangeIndex else { return }
        let offset = isNext ? 1 : -1
        self.focusRangeIndex = (focusRangeIndex + offset + searchRanges.count) % searchRanges.count
    }

    @objc
    private func goToPreRange(_ button: UIButton) {
        changeFocus(isNext: false)
    }

    @objc
    private func goToNextRange(_ button: UIButton) {
        changeFocus(isNext: true)
    }

    @objc
    private func refreshButtonClicked(_ button: UIButton) {
        updateUI()
    }
}

extension SCDebugTextViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchRanges = (textView.text ?? "").ranges(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = nil
        searchRanges = []
    }
}

private extension String {
    func ranges(_ searchString: String) -> [NSRange] {
        var result = [NSRange]()
        guard !isEmpty,
              !searchString.isEmpty else { return result }
        var separatedArray = self.components(separatedBy: searchString)
        // 根据 separatedArray 的元素的 endIndex 推算出需要高亮的区域
        // 所以最后一个 separatedArray 元素没有用，提前移除掉
        separatedArray.removeLast()
        guard separatedArray.count > 0 else { return result }
        let length = searchString.count
        var location = 0
        for (_, element) in separatedArray.enumerated() {
            location += element.count
            result.append(NSRange(location: location, length: length))
            location += length
        }
        return result
    }
}
