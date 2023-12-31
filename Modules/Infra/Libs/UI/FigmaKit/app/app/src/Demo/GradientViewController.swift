//
//  GradientViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit
import FigmaKit

class GradientViewController: UIViewController {

    private lazy var container = UIView()

    private lazy var figmaView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "gradient_figma")
        return imageView
    }()

    private lazy var xcodeView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "gradient_xcode")
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gradients"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupSubviews()
    }

    private func setupSubviews() {
        container.translatesAutoresizingMaskIntoConstraints = false
        figmaView.translatesAutoresizingMaskIntoConstraints = false
        xcodeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        container.addSubview(figmaView)
        container.addSubview(xcodeView)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        NSLayoutConstraint.activate([
            figmaView.widthAnchor.constraint(equalToConstant: 150),
            figmaView.heightAnchor.constraint(equalToConstant: 520),
            figmaView.topAnchor.constraint(equalTo: container.topAnchor),
            figmaView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            figmaView.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        ])
        NSLayoutConstraint.activate([
            xcodeView.widthAnchor.constraint(equalToConstant: 150),
            xcodeView.heightAnchor.constraint(equalToConstant: 520),
            xcodeView.topAnchor.constraint(equalTo: container.topAnchor),
            xcodeView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            xcodeView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            xcodeView.leadingAnchor.constraint(equalTo: figmaView.trailingAnchor, constant: 20)
        ])
        addGradientViews()
    }

    private func addGradientViews() {
        let view1 = LinearGradientView()
        view1.frame = CGRect(x: 0, y: 0, width: 150, height: 80)
        view1.direction = .diagonal45
        view1.colors = [#colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1), #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)]
        xcodeView.addSubview(view1)

        let view2 = LinearGradientView()
        view2.frame = CGRect(x: 0, y: 100, width: 150, height: 150)
        view2.direction = .leftToRight
        view2.colors = [#colorLiteral(red: 0.1411764706, green: 0.5411764706, blue: 0.2392156863, alpha: 1), #colorLiteral(red: 0.2, green: 0.7803921569, blue: 0.3490196078, alpha: 1)]
        xcodeView.addSubview(view2)

        let view3 = LinearGradientView()
        view3.frame = CGRect(x: 0, y: 270, width: 150, height: 200)
        view3.direction = .diagonal135
        view3.colors = [#colorLiteral(red: 0.3529411765, green: 0.7843137255, blue: 0.9803921569, alpha: 1), #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)]
        xcodeView.addSubview(view3)
    }
}
