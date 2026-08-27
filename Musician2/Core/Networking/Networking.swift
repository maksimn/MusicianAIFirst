//
//  Networking.swift
//  Musician2
//
//  Created by Maksim Ivanov on 03.07.2026.
//

import Foundation

protocol NetworkDataLoader {

    func download(_ url: URL) async throws -> Data
}

struct URLSessionNetworkDataLoader: NetworkDataLoader {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func download(_ url: URL) async throws -> Data {
        let (data, _) = try await session.data(from: url)
        return data
    }
}
