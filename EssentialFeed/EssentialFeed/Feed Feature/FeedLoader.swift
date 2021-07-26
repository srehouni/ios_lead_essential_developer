//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Said Rehouni on 26/7/21.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
