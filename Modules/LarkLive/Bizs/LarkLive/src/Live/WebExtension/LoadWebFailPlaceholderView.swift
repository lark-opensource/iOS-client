//
//  LoadWebFailPlaceholderView.swift
//  LarkWebViewController
//
//  Created by houjihu on 2020/10/1.
//

import LarkUIKit
import UniverseDesignEmpty

/// webview fail view
class LoadWebFailPlaceholderView: LoadFaildRetryView {
    override var image: UIImage? {
        return UDEmptyType.loadingFailure.defaultImage()
    }
}
