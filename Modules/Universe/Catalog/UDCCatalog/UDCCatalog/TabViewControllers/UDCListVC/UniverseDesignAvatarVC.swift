//
//  UniverseDesignAvatarVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/9/7.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignAvatar
import UniverseDesignIcon

class UniverseDesignAvatarVC: UIViewController {
    private lazy var wrapperStack: UIStackView = {
        let wrapperStack = UIStackView()
        wrapperStack.axis = .vertical
        wrapperStack.alignment = .center
        wrapperStack.distribution = .fill
        wrapperStack.spacing = 60
        wrapperStack.isLayoutMarginsRelativeArrangement = true
        wrapperStack.translatesAutoresizingMaskIntoConstraints = false //会影响Auto Layout
        return wrapperStack
    }()

    var avatar: UDAvatar = UDAvatar()
    var avatar1: UDAvatar = UDAvatar()
    var avatar2: UDAvatar = UDAvatar()
    var avatar3: UDAvatar = UDAvatar()
    var avatar4: UDAvatar = UDAvatar()
    var avatar5: UDAvatar = UDAvatar()
    var avatar6: UDAvatar = UDAvatar()
    var avatar7: UDAvatar = UDAvatar()

    lazy var avatarGroup: UDAvatarGroup = UDAvatarGroup(avatars: [avatar1, avatar2, avatar3, avatar4, avatar5, avatar6, avatar7], sizeClass: .middle)

    private lazy var styleBtn: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["circle","square"])
        segmentedCtl.selectedSegmentIndex = 0
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeStyle), for: .valueChanged)
        return segmentedCtl
    }()

    private lazy var sizeBtn1: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["mini","small","middle", "large", "extra-large"])
        segmentedCtl.selectedSegmentIndex = 2
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeAvatarSize), for: .valueChanged)
        return segmentedCtl
    }()

    private lazy var sizeBtn2: UISegmentedControl = {
        let segmentedCtl = UISegmentedControl(items: ["mini","small","middle", "large", "extra-large"])
        segmentedCtl.selectedSegmentIndex = 2
        // 設置切換選項時執行的動作
        segmentedCtl.addTarget(self, action: #selector(changeAvatarGroupSize), for: .valueChanged)
        return segmentedCtl
    }()

    lazy var changeImageBtn: UIButton = {
        let button = UIButton()
        button.setTitle("change image", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(changeImage), for: .touchUpInside)
        button.backgroundColor = UIColor.ud.N300
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.snp.makeConstraints { make in
            make.width.equalTo(160)
        }
        return button
    }()


    @objc private func changeStyle(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            avatar.layer.ux.removeSmoothBorder()
            avatar.configuration.style = .circle
        } else if sender.selectedSegmentIndex == 1 {
            avatar.configuration.style = .square
            avatar.layer.ux.setSmoothCorner(radius: 16)
            avatar.layer.ux.setSmoothBorder(width: 1, color: .black)
        }
    }

    @objc private func changeAvatarSize(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            avatar.configuration.sizeClass = .mini
        } else if sender.selectedSegmentIndex == 1 {
            avatar.configuration.sizeClass = .small
        } else if sender.selectedSegmentIndex == 2 {
            avatar.configuration.sizeClass = .middle
        } else if sender.selectedSegmentIndex == 3 {
            avatar.configuration.sizeClass = .large
        } else if sender.selectedSegmentIndex == 4 {
            avatar.configuration.sizeClass = .extraLarge
        }
    }

    @objc private func changeAvatarGroupSize(sender: UISegmentedControl) {
        var newSize: UDAvatar.Configuration.Size = .middle
        if sender.selectedSegmentIndex == 0 {
            newSize = .mini
        } else if sender.selectedSegmentIndex == 1 {
            newSize = .small
        } else if sender.selectedSegmentIndex == 2 {
            newSize = .middle
        } else if sender.selectedSegmentIndex == 3 {
            newSize = .large
        } else if sender.selectedSegmentIndex == 4 {
            newSize = .extraLarge
        }
        avatarGroup.sizeClass = newSize
    }

    @objc func changeImage() {
        if avatar1.configuration.image == UIImage(named: "ttmoment.jpeg") {
            avatar1.configuration.image = UIImage(named: "flower.jpeg")
            avatar2.configuration.image = UIImage(named: "flower.jpeg")
            avatar3.configuration.image = UIImage(named: "flower.jpeg")
            avatar4.configuration.image = UIImage(named: "flower.jpeg")
            avatar5.configuration.image = UIImage(named: "flower.jpeg")
            avatar6.configuration.image = UIImage(named: "flower.jpeg")
            avatar7.configuration.image = UIImage(named: "flower.jpeg")
        } else {
            avatar1.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar2.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar3.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar4.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar5.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar6.configuration.image = UIImage(named: "ttmoment.jpeg")
            avatar7.configuration.image = UIImage(named: "ttmoment.jpeg")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            wrapperStack.widthAnchor.constraint(equalToConstant: 300),
            wrapperStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wrapperStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

    }

    private func setupSubviews() {
        self.view.addSubview(wrapperStack)
        avatar.configuration.image = UDIcon.addOutlined
        avatar.configuration.backgroundColor = .red
        if avatar.configuration.style == .square {
            avatar.layer.ux.setSmoothCorner(radius: 16)
            avatar.layer.ux.setSmoothBorder(width: 1, color: .black)
        }
        avatar1.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar2.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar3.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar4.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar5.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar6.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        avatar7.configuration.image = #imageLiteral(resourceName: "ttmoment.jpeg")
        wrapperStack.addArrangedSubview(avatar)
        wrapperStack.addArrangedSubview(styleBtn)
        wrapperStack.addArrangedSubview(sizeBtn1)
        wrapperStack.addArrangedSubview(avatarGroup)
        wrapperStack.addArrangedSubview(changeImageBtn)
        wrapperStack.addArrangedSubview(sizeBtn2)
    }

    private func setupAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBase
    }
}
