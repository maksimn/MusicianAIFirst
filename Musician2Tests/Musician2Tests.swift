//
//  Musician2Tests.swift
//  Musician2Tests
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import Foundation
import Testing
@testable import Musician2

struct Musician2Tests {

    @Test func example() async throws {
        let mock = NetworkDataLoaderMock { _ in Data() }

        let result = try await mock.download(URL(string: "https://example.com")!)

        #expect(result == Data())
    }
}
