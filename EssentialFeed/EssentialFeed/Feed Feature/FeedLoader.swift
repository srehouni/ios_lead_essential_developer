//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Said Rehouni on 26/7/21.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
