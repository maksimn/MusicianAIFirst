import Foundation

struct Book: Decodable, Identifiable, Hashable {
    let name: String
    let type: String
    let year: Int
    let cover: String
    let storeUrl: String
    let medianColor: String

    // Stable id derived from name and year; good enough for list identity
    var id: String { "\(name)_\(year)" }

    enum CodingKeys: String, CodingKey {
        // Common names
        case name
        case title
        case type
        case book_type
        case category
        case year
        case published
        case publication_year
        case cover
        case image
        case cover_url
        case store
        case store_url
        case url
        case link
        case median_color
        case medianColor
        case color
    }

    init(name: String, type: String, year: Int, cover: String, storeUrl: String, medianColor: String) {
        self.name = name
        self.type = type
        self.year = year
        self.cover = cover
        self.storeUrl = storeUrl
        self.medianColor = medianColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Name / Title
        let name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? ""

        // Type / Category
        let type = try container.decodeIfPresent(String.self, forKey: .type)
            ?? container.decodeIfPresent(String.self, forKey: .book_type)
            ?? container.decodeIfPresent(String.self, forKey: .category)
            ?? ""

        // Year / Published
        let year = try container.decodeIfPresent(Int.self, forKey: .year)
            ?? container.decodeIfPresent(Int.self, forKey: .published)
            ?? container.decodeIfPresent(Int.self, forKey: .publication_year)
            ?? 0

        // Cover URL
        let cover = try container.decodeIfPresent(String.self, forKey: .cover)
            ?? container.decodeIfPresent(String.self, forKey: .image)
            ?? container.decodeIfPresent(String.self, forKey: .cover_url)
            ?? ""

        // Store URL / Link
        let storeUrl = try container.decodeIfPresent(String.self, forKey: .store)
            ?? container.decodeIfPresent(String.self, forKey: .store_url)
            ?? container.decodeIfPresent(String.self, forKey: .url)
            ?? container.decodeIfPresent(String.self, forKey: .link)
            ?? ""

        // Median color hex
        let medianColor = try container.decodeIfPresent(String.self, forKey: .median_color)
            ?? container.decodeIfPresent(String.self, forKey: .medianColor)
            ?? container.decodeIfPresent(String.self, forKey: .color)
            ?? "#FFFFFF"

        self.init(name: name, type: type, year: year, cover: cover, storeUrl: storeUrl, medianColor: medianColor)
    }
}
