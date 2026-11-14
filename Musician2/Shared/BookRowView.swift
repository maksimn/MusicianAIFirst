import SwiftUI

struct BookRowView: View {
    let book: Book

    var body: some View {
        let bgColor = Color(hex: book.medianColor) ?? Color(.secondarySystemBackground)
        let textColor = bgColor.toCharacterColor
        let imageHeight: CGFloat = 144

        HStack(alignment: .top, spacing: 0) {
            AsyncImage(url: URL(string: book.cover)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    placeholder
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 96, height: imageHeight)
            .clipped()
            .padding(.leading, 24)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .lineLimit(2)

                Text("\(book.type), \(book.year)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.85))
                    .lineLimit(1)

                if let url = URL(string: book.storeUrl), !book.storeUrl.isEmpty {
                    Link("Store", destination: url)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textColor)
                        .tint(textColor)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: imageHeight)
        .background(bgColor)
        .clipShape(Rectangle())
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay {
                Image(systemName: "book")
                    .foregroundStyle(.secondary)
            }
    }
}
