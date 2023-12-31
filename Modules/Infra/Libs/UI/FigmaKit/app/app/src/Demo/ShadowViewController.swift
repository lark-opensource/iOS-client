//
//  ShadowViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit

class ShadowViewController: UIViewController {

    let figmaImage = UIImageView(image: UIImage(named: "figma_shadow")!)
    private lazy var container = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Shadows"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupSubviews()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView)))
    }

    private func setupSubviews() {
        figmaImage.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        view.addSubview(container)
        view.addSubview(figmaImage)
        NSLayoutConstraint.activate([
            figmaImage.widthAnchor.constraint(equalToConstant: 300),
            figmaImage.heightAnchor.constraint(equalToConstant: 560),
            figmaImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            figmaImage.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalTo: figmaImage.widthAnchor),
            container.heightAnchor.constraint(equalTo: figmaImage.heightAnchor),
            container.centerXAnchor.constraint(equalTo: figmaImage.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: figmaImage.centerYAnchor)
        ])
        makeShadowViews()
    }

    @objc
    private func didTapView() {
        figmaImage.isHidden.toggle()
    }

    private func makeShadowViews() {

        let logo = UIImageView()
        logo.image = UIImage(named: "xcode_icon")
        logo.frame = CGRect(x: 130, y: 4, width: 40, height: 40)
        container.addSubview(logo)

        let view1 = UIView()
        view1.backgroundColor = .white
        view1.frame = CGRect(x: 50, y: 80, width: 200, height: 80)
        view1.layer.dropShadow(
            color: .black,
            alpha: 0.25,
            x: 0,
            y: 4,
            blur: 4,
            spread: 0
        )
        container.addSubview(view1)

        let view2 = UIView()
        view2.backgroundColor = .white
        view2.frame = CGRect(x: 50, y: 200, width: 200, height: 80)
        view2.layer.dropShadow(
            color: .black,
            alpha: 0.25,
            x: 2,
            y: 4,
            blur: 8,
            spread: 0
        )
        container.addSubview(view2)

        let view3 = UIView()
        view3.backgroundColor = .white
        view3.frame = CGRect(x: 50, y: 320, width: 200, height: 80)
        view3.layer.dropShadow(
            color: .black,
            alpha: 0.25,
            x: 2,
            y: 4,
            blur: 8,
            spread: 2
        )
        container.addSubview(view3)

        let view4 = UIView()
        view4.backgroundColor = .white
        view4.frame = CGRect(x: 50, y: 440, width: 200, height: 80)
        view4.layer.dropShadow(
            color: .black,
            alpha: 0.25,
            x: 2,
            y: 4,
            blur: 10,
            spread: -2
        )
        container.addSubview(view4)
    }
}
