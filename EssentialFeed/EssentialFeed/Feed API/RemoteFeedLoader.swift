//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Said Rehouni on 28/7/21.
//

import Foundation

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.get(from: url)
    }
}

public protocol HTTPClient {
    func get(from url: URL)
}
