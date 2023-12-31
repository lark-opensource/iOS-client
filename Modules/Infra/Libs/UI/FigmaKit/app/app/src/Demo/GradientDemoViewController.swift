//
//  GradientDemoViewController.swift
//  FigmaKitDev
//
//  Created by Hayden on 2023/5/25.
//

import UIKit
import FigmaKit

class GradientDemoViewController: UIViewController {

    private lazy var linearGradientView: UIView = {
        let view = FKGradientView()
        view.type = .linear
        view.direction = .diagonal45
        view.colors = [.systemBlue, .systemGreen]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var angularGradientView: UIView = {
        let view = FKGradientView()
        view.type = .angular
        view.direction = .angleInDegree(45)
        view.colors = [.systemBlue, .systemGreen]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var radialGradientView: UIView = {
        let view = FKGradientView()
        view.type = .radial
        view.colors = [.systemBlue, .systemGreen]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var gradientViewStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var solidGradientButton: FKGradientButton = {
        let button = FKGradientButton()
        let font = UIFont.systemFont(ofSize: 24, weight: .regular)
        button.titleLabel?.font = font
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(font: font)
            button.setImage(UIImage(systemName: "command", withConfiguration: config), for: .normal)
        }
        button.setTitle("Gradient Button", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setInsets(iconTitleSpacing: 10)
        button.cornerRadius = 6
        return button
    }()

    private lazy var gradientTextField: UITextField = {
        let textField = UITextField()
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.translatesAutoresizingMaskIntoConstraints = false
//        textField.textColor = UIColor.fromGradientWithDirection(.leftToRight, frame: CGRect(x: 0, y: 0, width: 100, height: 50), colors: [.red, .yellow])
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Gradient"
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        // Do any additional setup after loading the view.

        view.addSubview(gradientViewStack)
        gradientViewStack.addArrangedSubview(linearGradientView)
        gradientViewStack.addArrangedSubview(angularGradientView)
        gradientViewStack.addArrangedSubview(radialGradientView)
        NSLayoutConstraint.activate([
            gradientViewStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gradientViewStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gradientViewStack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40),
            linearGradientView.widthAnchor.constraint(equalTo: gradientViewStack.heightAnchor),
            radialGradientView.widthAnchor.constraint(equalTo: gradientViewStack.heightAnchor),
            angularGradientView.widthAnchor.constraint(equalTo: gradientViewStack.heightAnchor)
        ])

        view.addSubview(gradientTextField)
        NSLayoutConstraint.activate([
            gradientTextField.topAnchor.constraint(equalTo: gradientViewStack.bottomAnchor, constant: 20),
            gradientTextField.heightAnchor.constraint(equalToConstant: 60),
            gradientTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gradientTextField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        ])

        view.addSubview(solidGradientButton)
        NSLayoutConstraint.activate([
            solidGradientButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            solidGradientButton.heightAnchor.constraint(equalToConstant: 60),
            solidGradientButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            solidGradientButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        ])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

public class FKGradientTextField: UITextField {

    struct GradientColors {

        var backgroundColor: [UIColor]
        var borderColor: [UIColor]
        var titleColor: [UIColor]

        static var `default` = GradientColors(
            backgroundColor: [UIColor.systemYellow, UIColor.systemRed].map { $0.withAlphaComponent(0.1) },
            borderColor: [.systemYellow, .systemRed],
            titleColor: [.systemYellow, .systemRed]
        )
    }

//    public override var isHighlighted: Bool {
//        didSet {
//            updateGradientColors()
//        }
//    }

    var gradientColors: GradientColors = .default

    private lazy var gradientBgLayer: FKGradientLayer = {
        let gradientLayer = FKGradientLayer(type: .linear)
        gradientLayer.direction = .leftToRight
        return gradientLayer
    }()

    private lazy var gradientTitleLayer: FKGradientLayer = {
        let gradientLayer = FKGradientLayer(type: .linear)
        gradientLayer.colors = [UIColor.green, UIColor.blue].map({ $0.cgColor })
        gradientLayer.direction = .leftToRight
        return gradientLayer
    }()

    private lazy var gradientImageLayer: FKGradientLayer = {
        let gradientLayer = FKGradientLayer(type: .angular)
        gradientLayer.direction = .leftToRight
        return gradientLayer
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
//        layer.addSublayer(gradientBgLayexr)
        layer.addSublayer(gradientTitleLayer)
//        layer.addSublayer(gradientImageLayer)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
//        gradientBgLayer.frame = bounds
        gradientTitleLayer.frame = bounds
//        gradientImageLayer.frame = bounds
        updateGradientColors()
    }

    private func updateGradientColors() {
//        if isHighlighted {
//            gradientBgLayer.colors = gradientColors.backgroundColor.map { $0.withAlphaComponent(1.0).cgColor }
//            gradientTitleLayer.colors = [UIColor.white, UIColor.white].map { $0.cgColor }
//            gradientImageLayer.colors = [UIColor.white, UIColor.white].map { $0.cgColor }
// //            setGradientBorder(width: 2, colors: gradientColors.borderColor, direction: .leftToRight, cornerRadius: 30)
//        } else {
//            gradientBgLayer.colors = gradientColors.backgroundColor.map { $0.cgColor }
            gradientTitleLayer.colors = gradientColors.titleColor.map { $0.cgColor }
//            gradientImageLayer.colors = gradientColors.titleColor.map { $0.cgColor }
//            setGradientBorder(width: 2, colors: gradientColors.borderColor, direction: .leftToRight, cornerRadius: 30)
//        }
        gradientTitleLayer.mask = self.layer
//        gradientImageLayer.mask = text
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateGradientColors()
            }
        }
    }
}
