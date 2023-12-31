//
//  FileMenuView.swift
//  LarkFile
//
//  Created by 王元洵 on 2020/10/27.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit
import UniverseDesignColor

protocol FileMenuDelegate: AnyObject {
    func onReturningFromFileMenu(selectedMenu: String?)
}

final class FileMenuView: UIStackView {
    private var fileMenu: [String]

    private var currentTitle: String

    weak var delegate: FileMenuDelegate?

    private var labels: [UILabel] = []
    private let backgroundView = UIView()

    private let menuHeight: CGFloat

    init(fileMenu: [String]) {
        self.fileMenu = fileMenu
        menuHeight = CGFloat(fileMenu.count * 40)
        currentTitle = fileMenu.first ?? ""

        super.init(frame: .zero)

        self.axis = .vertical
        self.alignment = .center

        fileMenu.forEach {
            let label = UILabel()
            label.text = $0
            label.font = .systemFont(ofSize: 16, weight: .regular)
            label.textAlignment = .center
            label.textColor = UIColor.ud.textTitle
            label.backgroundColor = UIColor.ud.bgBody
            addArrangedSubview(label)
            labels.append(label)
            label.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(0)
            }
            label.isUserInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(onLabelTapped)))
        }
        addArrangedSubview(backgroundView)

        backgroundView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
        }

        backgroundView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.0)
        backgroundView.lu.addTapGestureRecognizer(action: #selector(onbackgroundViewTapped),
                                              target: self)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onbackgroundViewTapped() {
        delegate?.onReturningFromFileMenu(selectedMenu: nil)
    }

    @objc
    private func onLabelTapped(gesture: UITapGestureRecognizer) {
        guard let seletedLabel = gesture.view as? UILabel,
              let seletedText = seletedLabel.text else { return }
        currentTitle = seletedText
        delegate?.onReturningFromFileMenu(selectedMenu: seletedText)
    }

    func showAnimation() {
        isHidden = false
        Self.animate(withDuration: 0.2,
                     animations: {
                        self.labels.forEach {
                            guard let text = $0.text else { return }
                            if text == self.currentTitle {
                                $0.textColor = UIColor.ud.primaryContentDefault
                            } else {
                                $0.textColor = UIColor.ud.textTitle
                            }
                            $0.snp.updateConstraints { (make) in
                                make.height.equalTo(50)
                            }
                        }
                        self.backgroundView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
                        self.layoutIfNeeded()
                     })
    }

    func hideAnimation() {
        Self.animate(withDuration: 0.2,
                     animations: {
                        self.labels.forEach {
                            $0.snp.updateConstraints { (make) in
                                make.height.equalTo(0)
                            }
                        }
                        self.backgroundView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.0)
                        self.layoutIfNeeded()
                     }) { _ in
            self.isHidden = true
        }
    }
}
