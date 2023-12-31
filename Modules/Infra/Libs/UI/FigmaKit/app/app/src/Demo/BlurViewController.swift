//
//  BlurViewController.swift
//  FigmaKitDev
//
//  Created by Hayden Wang on 2021/9/2.
//

import Foundation
import UIKit
import FigmaKit

class BlurViewController: UIViewController {

    private lazy var exampleView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "figma_blur")
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var imageView1: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "mojave_photo")
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var imageView2: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "mojave_photo")
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var blurLabel1: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 8)
        label.textColor = .white
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    private lazy var blurLabel2: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 8)
        label.textColor = .white
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    let backgroundBlurView = BackgroundBlurView()

    let visualBlurView = VisualBlurView()

    private var blurSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 16
        return slider
    }()

    private var colorSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.01
        return slider
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Blur"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupSubviews()
    }

    private func setupSubviews() {
        exampleView.translatesAutoresizingMaskIntoConstraints = false
        imageView1.translatesAutoresizingMaskIntoConstraints = false
        imageView2.translatesAutoresizingMaskIntoConstraints = false
        blurLabel1.translatesAutoresizingMaskIntoConstraints = false
        blurLabel2.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        visualBlurView.translatesAutoresizingMaskIntoConstraints = false
        blurSlider.translatesAutoresizingMaskIntoConstraints = false
        colorSlider.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(exampleView)
        view.addSubview(imageView1)
        view.addSubview(imageView2)
        imageView1.addSubview(backgroundBlurView)
        imageView1.addSubview(blurLabel1)
        imageView2.addSubview(visualBlurView)
        imageView2.addSubview(blurLabel2)
        view.addSubview(blurSlider)
        view.addSubview(colorSlider)
        NSLayoutConstraint.activate([
            exampleView.widthAnchor.constraint(equalToConstant: 300),
            exampleView.heightAnchor.constraint(equalToConstant: 180),
            exampleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exampleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        NSLayoutConstraint.activate([
            imageView1.widthAnchor.constraint(equalToConstant: 300),
            imageView1.heightAnchor.constraint(equalToConstant: 180),
            imageView1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView1.topAnchor.constraint(equalTo: exampleView.bottomAnchor, constant: 20)
        ])
        NSLayoutConstraint.activate([
            imageView2.widthAnchor.constraint(equalToConstant: 300),
            imageView2.heightAnchor.constraint(equalToConstant: 180),
            imageView2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView2.topAnchor.constraint(equalTo: imageView1.bottomAnchor, constant: 20)
        ])
        NSLayoutConstraint.activate([
            backgroundBlurView.widthAnchor.constraint(equalToConstant: 300),
            backgroundBlurView.heightAnchor.constraint(equalToConstant: 180),
            backgroundBlurView.centerXAnchor.constraint(equalTo: imageView1.centerXAnchor),
            backgroundBlurView.centerYAnchor.constraint(equalTo: imageView1.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            visualBlurView.widthAnchor.constraint(equalToConstant: 300),
            visualBlurView.heightAnchor.constraint(equalToConstant: 180),
            visualBlurView.centerXAnchor.constraint(equalTo: imageView2.centerXAnchor),
            visualBlurView.centerYAnchor.constraint(equalTo: imageView2.centerYAnchor)
        ])
//        blurView.backgroundColor = .white.withAlphaComponent(0.01)
//        blurView.blurRadius = 0
        NSLayoutConstraint.activate([
            colorSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            colorSlider.leadingAnchor.constraint(equalTo: exampleView.leadingAnchor),
            colorSlider.trailingAnchor.constraint(equalTo: exampleView.trailingAnchor)
        ])
        NSLayoutConstraint.activate([
            blurSlider.bottomAnchor.constraint(equalTo: colorSlider.topAnchor, constant: -10),
            blurSlider.leadingAnchor.constraint(equalTo: exampleView.leadingAnchor),
            blurSlider.trailingAnchor.constraint(equalTo: exampleView.trailingAnchor)
        ])
        NSLayoutConstraint.activate([
            blurLabel1.topAnchor.constraint(equalTo: imageView1.topAnchor, constant: 6),
            blurLabel1.rightAnchor.constraint(equalTo: imageView1.rightAnchor, constant: -8)
        ])
        NSLayoutConstraint.activate([
            blurLabel2.topAnchor.constraint(equalTo: imageView2.topAnchor, constant: 6),
            blurLabel2.rightAnchor.constraint(equalTo: imageView2.rightAnchor, constant: -8)
        ])

        blurSlider.addTarget(self, action: #selector(didChangeSliderValue(_:)), for: .valueChanged)
        colorSlider.addTarget(self, action: #selector(didChangeSliderValue(_:)), for: .valueChanged)
        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true

        blurRadius = 16
        fillOpacity = 0.01
    }

    var blurRadius: CGFloat = 16 {
        didSet {
            backgroundBlurView.blurRadius = blurRadius
            visualBlurView.blurRadius = blurRadius
            blurLabel1.text = "BackgroundBlurView\nblur radius: \(Int(blurRadius)) pt\nfill opacity: \(Int(fillOpacity * 100)) %"
            blurLabel2.text = "VisualBlurView\nblur radius: \(Int(blurRadius)) pt\nfill opacity: \(Int(fillOpacity * 100)) %"
        }
    }

    var fillOpacity: CGFloat = 0.01 {
        didSet {
            visualBlurView.fillColor = .white
            visualBlurView.fillOpacity = fillOpacity
            backgroundBlurView.fillColor = .white
            backgroundBlurView.fillOpacity = fillOpacity
            blurLabel1.text = "BackgroundBlurView\nblur radius: \(Int(blurRadius)) pt\nfill opacity: \(Int(fillOpacity * 100)) %"
            blurLabel2.text = "VisualBlurView\nblur radius: \(Int(blurRadius)) pt\nfill opacity: \(Int(fillOpacity * 100)) %"
            blurLabel1.textColor = fillOpacity < 0.5 ? .white : .black
            blurLabel2.textColor = fillOpacity < 0.5 ? .white : .black
        }
    }

    @objc
    private func didChangeSliderValue(_ sender: UISlider) {
        if sender == colorSlider {
            let alpha = CGFloat(sender.value)
            fillOpacity = alpha
        } else {
            let radius = Int(sender.value)
            if backgroundBlurView.blurRadius != CGFloat(radius) {
                blurRadius = CGFloat(radius)
            }
        }

//        self.backgroundView.frame = CGRect(
//            x: self.backgroundView.frame.origin.x,
//            y: self.backgroundView.frame.origin.y + 3,
//            width: self.backgroundView.frame.width,
//            height: self.backgroundView.frame.height
//        )
    }

}
