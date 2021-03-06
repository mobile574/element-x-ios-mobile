//
//  MediaProvider.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import MatrixRustSDK
import Kingfisher

struct MediaProvider: MediaProviderProtocol {
    private let client: Client
    private let imageCache: Kingfisher.ImageCache
    private let processingQueue: DispatchQueue
    
    init(client: Client, imageCache: Kingfisher.ImageCache) {
        self.client = client
        self.imageCache = imageCache
        self.processingQueue = DispatchQueue(label: "MediaProviderProcessingQueue", attributes: .concurrent)
    }
    
    func imageFromSource(_ source: MediaSource?) -> UIImage? {
        guard let source = source else {
            return nil
        }

        return imageCache.retrieveImageInMemoryCache(forKey: source.underlyingSource.url(), options: nil)
    }
    
    func loadImageFromSource(_ source: MediaSource, _ completion: @escaping (Result<UIImage, MediaProviderError>) -> Void) {
        if let image = imageFromSource(source) {
            completion(.success(image))
            return
        }
        
        imageCache.retrieveImage(forKey: source.underlyingSource.url()) { result in
            if case let .success(cacheResult) = result,
               let image = cacheResult.image {
                completion(.success(image))
                return
            }
            
            processingQueue.async {
                do {
                    let imageData = try client.getMediaContent(source: source.underlyingSource)
                    
                    guard let image = UIImage(data: Data(bytes: imageData, count: imageData.count)) else {
                        MXLog.error("Invalid image data")
                        DispatchQueue.main.async {
                            completion(.failure(.invalidImageData))
                        }
                        return
                    }
                    
                    imageCache.store(image, forKey: source.underlyingSource.url())
                    
                    DispatchQueue.main.async {
                        completion(.success(image))
                    }
                } catch {
                    MXLog.error("Failed retrieving image with error: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(.failedRetrievingImage))
                    }
                }
            }
        }
    }
    
    func imageFromURL(_ url: String?) -> UIImage? {
        guard let url = url else {
            return nil
        }
        
        return imageFromSource(MediaSource(source: mediaSourceFromUrl(url: url)))
    }
    
    func loadImageFromURL(_ url: String, _ completion: @escaping (Result<UIImage, MediaProviderError>) -> Void) {
        return loadImageFromSource(MediaSource(source: mediaSourceFromUrl(url: url)), completion)
    }
}
