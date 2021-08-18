//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Said Rehouni on 26/7/21.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: String
}
