//
//  ViewPager.swift
//  Musician2
//
//  Created by Maksim Ivanov on 29.08.2026.
//

import SwiftUI

/// One page of a `ViewPager`: the title shown in the tab bar and the content shown when
/// that tab is selected. The content is type erased so that pages of different view types
/// can live in the same page list.
struct ViewPagerPage: Identifiable {

    let id = UUID()

    let title: String

    let content: AnyView

    init<Content: View>(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = AnyView(content())
    }
}

/// Collects the pages declared inside a `ViewPager { ... }` block, so that pages can be
/// written one after another the way SwiftUI views usually are.
@resultBuilder
enum ViewPagerBuilder {

    static func buildBlock(_ pages: ViewPagerPage...) -> [ViewPagerPage] {
        pages
    }
}

/// A container view behaving like the Android `ViewPager`: a tab bar pinned at the top and
/// horizontally swipeable pages below it, with the tab bar and the pages kept in sync —
/// tapping a tab scrolls to its page, swiping to a page selects its tab.
///
/// It is built on a page-styled `TabView`, whose own page indicator is hidden because the
/// tab bar plays that role here.
struct ViewPager: View {

    private let pages: [ViewPagerPage]

    @State private var selectedIndex = 0

    /// The namespace lets the selection indicator slide from tab to tab instead of
    /// disappearing under one title and reappearing under another.
    @Namespace private var indicatorNamespace

    init(selectedIndex: Int = 0, @ViewPagerBuilder pages: () -> [ViewPagerPage]) {
        self.selectedIndex = selectedIndex
        self.pages = pages()
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            TabView(selection: $selectedIndex) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    page.content
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                tab(page, at: index)
            }
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
        }
        // Keeps the indicator sliding when the selection is changed by a page swipe
        // rather than by a tab tap.
        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
    }

    private func tab(_ page: ViewPagerPage, at index: Int) -> some View {
        let isSelected = index == selectedIndex

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedIndex = index
            }
        } label: {
            Text(page.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isSelected ? Color.black : Color.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
