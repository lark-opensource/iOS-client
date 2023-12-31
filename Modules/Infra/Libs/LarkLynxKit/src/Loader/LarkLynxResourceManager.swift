//
//  LarkLynxResourceManager.swift
//  LarkLynxKit
//
//  Created by Weston Wu on 2023/3/23.
//

import Foundation
import Lynx

public enum LarkLynxLoadError: Error {
    case loaderNotFound
    case allLoadersFailed(errors: [Error])
}

extension LarkLynxResourceManager {
    typealias LoadError = LarkLynxLoadError
    typealias LoaderCompletion = LarkLynxResourceLoader.LoaderCompletion
}

public protocol LarkLynxResourceLoaderDelegate: AnyObject {
    func resourceLoader(_ loader: LarkLynxResourceLoader,
                        didLoadTemplatePath templatePath: String,
                        tag: String)
    func onLoadResourceFailed(templatePath: String, tag: String, error: Error)
}

public class LarkLynxResourceManager {
    let tag: String
    private weak var delegate: LarkLynxResourceLoaderDelegate?

    public init(tag: String, delegate: LarkLynxResourceLoaderDelegate?) {
        self.tag = tag
        self.delegate = delegate
    }

    func load(templatePath: String, completion: @escaping LoaderCompletion) {
        guard let loaders = LarkLynxInitializer.shared.getResourceLoaders(tag: tag),
              !loaders.isEmpty else {
            let error = LoadError.loaderNotFound
            completion(.failure(error))
            delegate?.onLoadResourceFailed(templatePath: templatePath, tag: tag, error: LoadError.loaderNotFound)
            return
        }
        let iterator = loaders.makeIterator()
        load(templatePath: templatePath, previousErrors: [], iterator: iterator, completion: completion)
    }

    private func load(templatePath: String,
                      previousErrors: [Error],
                      iterator: IndexingIterator<[LarkLynxResourceLoader]>,
                      completion: @escaping LoaderCompletion) {
        var nextIterator = iterator
        var nextErrors = previousErrors
        guard let nextLoader = nextIterator.next() else {
            let error = LoadError.allLoadersFailed(errors: nextErrors)
            completion(.failure(error))
            delegate?.onLoadResourceFailed(templatePath: templatePath,
                                           tag: tag,
                                           error: error)
            return
        }
        nextLoader.load(templatePath: templatePath) { [weak self] result in
            switch result {
            case .success:
                completion(result)
                guard let self else { return }
                self.delegate?.resourceLoader(nextLoader, didLoadTemplatePath: templatePath, tag: self.tag)
            case let .failure(error):
                nextErrors.append(error)
                guard let self else {
                    let error = LoadError.allLoadersFailed(errors: nextErrors)
                    completion(.failure(error))
                    return
                }
                self.load(templatePath: templatePath, previousErrors: nextErrors, iterator: nextIterator, completion: completion)
            }
        }
    }
}
