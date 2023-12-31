//
//  UIImageViewCompentent.swift
//  AsyncComponent
//
//  Created by KT on 2019/5/12.
//

import UIKit
import Foundation

public final class UIImageViewSetImageTask {
    public let view: UIImageView

    init(_ view: UIImageView) {
        self.view = view
    }

    public func set(image: UIImage?) {
        view.image = image
    }
}

public final class UIImageViewComponentProps: SafeASComponentProps {
    private var _image: UIImage?
    @available(*, deprecated, message:
    "Will be removed soon. Use `setImage((UIImageViewSetImageTask) -> Void)` instead.")
    public var image: UIImage? {
        get {
            return safeRead({ self._image })
        }
        set {
            safeWrite {
                self._image = newValue
            }
        }
    }
    private var _setImage: ((UIImageViewSetImageTask) -> Void)?
    public var setImage: ((UIImageViewSetImageTask) -> Void)? {
        get {
            return safeRead({ self._setImage })
        }
        set {
            safeWrite {
                self._setImage = newValue
            }
        }
    }
    public var contentMode: UIView.ContentMode?

    fileprivate func update(view: UIImageView) {
        safeRead {
            if let setImage = self._setImage {
                setImage(UIImageViewSetImageTask(view))
            } else if let image = self._image {
                view.image = image
            } else {
                view.image = nil
            }
            if let contentMode = self.contentMode {
                view.contentMode = contentMode
            }
        }
    }
}

public final class UIImageViewComponent<C: AsyncComponent.Context>: ASComponent<
    UIImageViewComponentProps,
    EmptyState,
    UIImageView,
    C
> {

    public override func update(view: UIImageView) {
        super.update(view: view)
        props.update(view: view)
    }
}
