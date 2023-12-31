//
//  ImageViewWrapper.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/8/30.
//

import UIKit
import Foundation
import LarkInteraction
import ByteWebImage

public final class ImageViewWrapper: ByteImageView {
    public typealias ImageViewTapped = () -> Void
    public typealias SetImageTask = (UIImageView, @escaping SetImageCompletion) -> Void
    public typealias SetImageCompletion = (_ image: UIImage?, _ error: Error?) -> Void

    // 当图片的短边≥56时，显示固定尺寸的加载（24 * 24）与加载失败裂图（32 * 32）
    public static let errorViewLimitWidth: CGFloat = 56

    public var onTap: ImageViewTapped? {
        didSet {
            // Tap
            if onTap == nil {
                self.isUserInteractionEnabled = false
                if let gesture = tapGesture {
                    self.removeGestureRecognizer(gesture)
                    self.tapGesture = nil
                }
            } else if tapGesture == nil {
                self.isUserInteractionEnabled = true
                let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
                addGestureRecognizer(gesture)
                self.tapGesture = gesture
            } else {
                self.isUserInteractionEnabled = true
            }

            // Pointer
            if #available(iOS 13.4, *) {
                if onTap != nil, self.lkInteractions.isEmpty {
                    let pointer = self.pointer ?? PointerInteraction(
                        style: .init(
                            effect: .highlight,
                            shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                                guard let view = interaction.view else {
                                    return (.zero, 0)
                                }
                                return (CGSize(width: view.bounds.width + 16, height: view.bounds.height + 16), 8)
                            })
                        )
                    )
                    self.pointer = pointer
                    self.addLKInteraction(pointer)
                } else if let pointer = self.pointer {
                    self.removeLKInteraction(pointer)
                    self.pointer = nil
                }
            }
        }
    }

    public var setImageTask: SetImageTask? {
        didSet {
            if let task = setImageTask {
                // reset
                self.subviews.forEach({ $0.removeFromSuperview() })
                task(self, { [weak self] image, error in
                    guard let self = self else { return }
                    let minSize = min(self.bounds.width, self.bounds.height)
                    if image == nil, error != nil {
                        if minSize >= Self.errorViewLimitWidth {
                            self.addSubview(self.errorView)
                            self.errorView.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
                        } else {
                            // 对齐其他端，加载失败给个灰色背景，backgroundColor的重置在UIImageViewComponent中
                            self.backgroundColor = UIColor.ud.N300
                        }
                    }
                })
            } else {
                self.image = nil
                self.subviews.forEach({ $0.removeFromSuperview() })
            }
        }
    }

    private var tapGesture: UITapGestureRecognizer?

    private var _pointer: Any?
    @available(iOS 13.4, *)
    private var pointer: PointerInteraction? {
        get {
            return _pointer as? PointerInteraction
        }
        set {
            _pointer = newValue
        }
    }

    private lazy var errorView: UIImageView = {
        let errorView = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        errorView.image = BundleResources.imageFailOutlined.ud.withTintColor(UIColor.ud.iconDisabled)
        return errorView
    }()

    @objc
    func tapped() {
        onTap?()
    }
}
