//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Said Rehouni on 25/7/22.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeadks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potencial memory leak", file: file, line: line)
        }
    }
}
