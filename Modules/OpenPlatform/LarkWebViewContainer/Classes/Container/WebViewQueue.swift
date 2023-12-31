//
//  WebViewQueue.swift
//  LarkWebViewContainer
//
//  Created by Ryan on 2020/8/27.
//

import UIKit

protocol WebViewQueueDelegate: AnyObject {
    func queueDidBecomeEmpty()
}

struct WebViewQueue {
    weak var delegate: WebViewQueueDelegate?
    private var items = [LarkWebView]() {
        didSet {
            if items.isEmpty {
                asyncCallDelegateBecomeEmpty()
            }
        }
    }
    let capacity: Int
    var isEmpty: Bool {
        return items.isEmpty
    }

    init(capacity: Int) {
        self.capacity = capacity
    }

    /// Asynchronously call delegate func in case the delegate call 'items' property which causes thread access issue
    func asyncCallDelegateBecomeEmpty() {
        DispatchQueue.main.async {
            self.delegate?.queueDidBecomeEmpty()
        }
    }

    /// Get a webview instance from the queue
    /// - returns: A larkwebview instance
    mutating func getItem() -> LarkWebView? {
        guard !items.isEmpty else {
            return nil
        }
        return items.removeFirst()
    }

    /// Get a template ready webview instance from the queue
    /// - returns: A template ready larkwebview instance
    mutating func getTemplateReadyItem() -> LarkWebView? {
        if let idx = items.firstIndex(where: { $0.isTemplateReady }) {
            return items.remove(at: idx)
        } else {
            return nil
        }
    }

    /// Append a webview instance at the end of the queue
    /// - parameter item: the webview to append into the queue
    mutating func append(item: LarkWebView) {
        defer {
            items.sort(by: { $0.renderTimes > $1.renderTimes })
        }
        guard !items.contains(item) else {
            return
        }
        if items.count == capacity {
            // If the upcomming item's render times is more than the first item's render times in the queue, then no need to append it into the queue
            if item.renderTimes < items.first!.renderTimes {
                items.removeFirst()
                items.append(item)
            }
        } else {
            items.append(item)
        }
    }

    /// Remove a webview from the queue
    /// - parameter item: the webview to append into the queue
    /// - returns: A larkwebview instance
    @discardableResult
    mutating func remove(item: LarkWebView) -> Bool {
        guard let idx = items.firstIndex(of: item) else { return false }
        items.remove(at: idx)
        return true
    }
}
