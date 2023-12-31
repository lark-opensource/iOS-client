//
//  SquircleViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/1.
//

import Foundation
import UIKit
import FigmaKit

class SquircleViewController: UIViewController {

    private var roundView: SquircleView = {
        let view = SquircleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var roundSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private var smoothLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var smoothButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Squircle"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupSubviews()

        let initialRadius: CGFloat = 50
        roundView.backgroundColor = .systemGray
        roundView.cornerRadius = initialRadius
        roundView.cornerSmoothness = .max

        roundSlider.minimumValue = 0
        roundSlider.maximumValue = 150
        roundSlider.value = Float(initialRadius)

        smoothLabel.text = "点击切换平滑度"

        roundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapView)))
        roundSlider.addTarget(self, action: #selector(didChangeCornerRadius(_:)), for: .valueChanged)

        smoothButton.addTarget(self, action: #selector(didTapSmoothButton(_:)), for: .touchUpInside)
    }

    private func setupSubviews() {
        view.addSubview(roundView)
        view.addSubview(roundSlider)
        roundView.addSubview(smoothLabel)
        view.addSubview(smoothButton)

        NSLayoutConstraint.activate([
            roundView.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            roundView.widthAnchor.constraint(equalToConstant: 300),
            roundView.heightAnchor.constraint(equalToConstant: 300),
            roundView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        NSLayoutConstraint.activate([
            roundSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roundSlider.leadingAnchor.constraint(equalTo: roundView.leadingAnchor),
            roundSlider.trailingAnchor.constraint(equalTo: roundView.trailingAnchor),
            roundSlider.topAnchor.constraint(equalTo: roundView.bottomAnchor, constant: 50)
        ])
        NSLayoutConstraint.activate([
            smoothLabel.centerXAnchor.constraint(equalTo: roundView.centerXAnchor),
            smoothLabel.centerYAnchor.constraint(equalTo: roundView.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            smoothButton.topAnchor.constraint(equalTo: roundSlider.bottomAnchor, constant: 80),
            smoothButton.widthAnchor.constraint(equalToConstant: 300),
            smoothButton.heightAnchor.constraint(equalToConstant: 100),
            smoothButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

//        smoothButton.layer.ux.setMask { bounds in
//            UIBezierPath.squircle(
//                forRect: bounds,
//                cornerRadii: [8.0, 30.0, 8.0, 30.0],
//                cornerSmoothness: .max)
//        }
        smoothButton.layer.ux.setSmoothCorner(radius: 20)
        smoothButton.layer.ux.setSmoothBorder(width: 1, color: .black)
    }

    @objc
    private func didTapView() {
        var newSmoothness: CornerSmoothLevel = .none
        switch roundView.cornerSmoothness {
        case .none:     newSmoothness = .natural
        case .natural:  newSmoothness = .max
        case .max:      newSmoothness = .none
        }
        roundView.cornerSmoothness = newSmoothness
        smoothLabel.text = "Smoothness: \(newSmoothness)"
    }

    @objc
    private func didChangeCornerRadius(_ sender: UISlider) {
        roundView.cornerRadius = CGFloat(sender.value)
    }

    @objc
    private func didTapSmoothButton(_ sender: UIButton) {
        if smooth {
            smoothButton.layer.ux.removeSmoothCorner()
        } else {
            smoothButton.layer.ux.setMask(by: UIBezierPath.squircle(
                                            forRect: smoothButton.bounds,
                                            cornerRadii: [8.0, 30.0, 8.0, 30.0],
                                            cornerSmoothness: .max))
            smoothButton.layer.ux.setSmoothBorder(width: 1, color: .black)
        }
        smooth.toggle()
    }

    var smooth: Bool = false
}
