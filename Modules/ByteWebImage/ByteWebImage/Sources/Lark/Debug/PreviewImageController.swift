//
//  PreviewImageController.swift
//  ByteWebImage
//
//  Created by Saafo on 2022/9/5.
//

import UIKit

class PreviewImageController: UIViewController {

    var textField: UITextField!
    var imageView: ByteImageView!
    var label: UILabel = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .dynamicBackground
        imageView = ByteImageView()
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 290),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 290),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        if #available(iOS 13, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            imageView.addInteraction(interaction)
            imageView.isUserInteractionEnabled = true
        }
        label = UILabel()
        label.numberOfLines = 10
        label.font = .systemFont(ofSize: 12)
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
            label.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32)
        ])
        textField = UITextField()
        textField.placeholder = "输入图片的Key或者URL"
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.autocorrectionType = .no
        textField.delegate = self
        view.addSubview(textField)
        textField.font = .systemFont(ofSize: 14)
        textField.layer.borderWidth = 1 / UIScreen.main.scale
        textField.layer.borderColor = UIColor.gray.cgColor
        textField.layer.cornerRadius = 8
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            textField.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
}

// MARK: UITextFieldDelegate

extension PreviewImageController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let key = textField.text {
            imageView.bt.setLarkImage(.default(key: key), completion: { [weak self] result in
                self?.label.text = "\(result)"
            })
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: UIContextMenuInteractionDelegate

@available(iOS 13.0, *)
extension PreviewImageController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { suggestedActions in
            UIMenu(title: "", children: [
                UIMenu(title: "系统操作", children: suggestedActions),
                UIAction(title: NSLocalizedString("导出", comment: ""),
                         image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                             guard let self = self, let imageView = self.imageView,
                                   let image = imageView.image else { return }
                             let transparentVC = UIViewController() // 防止 UIActivityViewController 的 bug 把整个 debug 菜单 dismiss
                             transparentVC.modalPresentationStyle = .overFullScreen
                             let activityViewController = UIActivityViewController(activityItems: [image],
                                                                                   applicationActivities: nil)
                             activityViewController.popoverPresentationController?.sourceView = imageView
                             activityViewController.completionWithItemsHandler = { [weak transparentVC] _, _, _, _ in
                                 if let presentingVC = transparentVC?.presentingViewController {
                                     presentingVC.dismiss(animated: false)
                                 } else {
                                     transparentVC?.dismiss(animated: false)
                                 }
                             }
                             self.present(transparentVC, animated: false) { [weak transparentVC] in
                                 transparentVC?.present(activityViewController, animated: true)
                             }
                         },
                UIMenu(title: "删除", image: UIImage(systemName: "trash"), options: .destructive, children: [
                    UIAction(title: "从内存中清除",
                             image: UIImage(systemName: "memorychip"),
                             attributes: .destructive) { [weak self] _ in
                                 guard let self = self,
                                       let key = (self.imageView.image as? ByteImage)?.bt.requestKey?.targetCacheKey() else { return }
                                 LarkImageService.shared.removeCache(resource: .default(key: key), options: .memory)
                                 self.label.text = "从内存中清除成功"
                                 self.imageView.image = nil
                             },
                    UIAction(title: "从内存和磁盘中清除",
                             image: UIImage(systemName: "opticaldiscdrive"),
                             attributes: .destructive) { [weak self] _ in
                                 guard let self = self,
                                       let key = (self.imageView.image as? ByteImage)?.bt.requestKey else { return }
                                 LarkImageService.shared.removeCache(resource: .default(key: key.targetCacheKey()), options: .memory)
                                 LarkImageService.shared.removeCache(resource: .default(key: key.sourceCacheKey()), options: .all)
                                 self.label.text = "从内存和磁盘中清除成功"
                                 self.imageView.image = nil
                             }
                ])
            ])
        })
    }
}
