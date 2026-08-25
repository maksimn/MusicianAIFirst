//
//  CacheService.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import Foundation

protocol CacheService {

    func save(_ data: Data, to fileName: String) throws

    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T?
}

final class FileCacheService: CacheService {

    private let fileManager: FileManager = .default
    private let decoder = JSONDecoder()

    func save(_ data: Data, to fileName: String) throws {
        let url = try cacheURL(for: fileName)

        try data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T? {
        let url = try cacheURL(for: fileName)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }

    // MARK: - Helpers

    private func cacheURL(for fileName: String) throws -> URL {
        let cachesDirectory = try fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return cachesDirectory.appendingPathComponent(fileName)
    }
}
