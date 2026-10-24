import SwiftUI
import MapKit

struct SearchScreen: View {
    @EnvironmentObject var state: AppState
    @EnvironmentObject var location: LocationManager
    @StateObject private var search = SearchService()
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // barra di ricerca
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("", text: $search.query, prompt: Text("Cerca").foregroundColor(Color.white.opacity(0.4)))
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                        .tint(Color(hex: 0x2F8CFF))
                        .focused($focused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit {
                            search.searchText { item in
                                if let item = item { state.select(mapItem: item) }
                            }
                        }
                    if search.query.isEmpty {
                        Circle().fill(Color.white.opacity(0.35)).frame(width: 10, height: 10)
                    } else {
                        Button { search.query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 50)
                .background(Capsule().fill(Color(white: 0.04)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))

                Button {
                    focused = false
                    state.showSearch = false
                } label: {
                    ZStack {
                        Circle().fill(Color(white: 0.04))
                        Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(PressableStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 18)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !search.query.isEmpty {
                        resultsList
                    } else if let category = search.activeCategory {
                        categoryList(category)
                    } else {
                        historySection
                        nearbySection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            if let loc = location.location {
                search.region = MKCoordinateRegion(center: loc.coordinate, latitudinalMeters: 30_000, longitudinalMeters: 30_000)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true }
        }
    }

    // MARK: Sezioni

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !state.history.isEmpty {
                HStack {
                    Text("Cronologia")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Cancella") { state.history = [] }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color(hex: 0xFF3B4E))
                }
                ForEach(state.history) { place in
                    Button {
                        state.addToHistory(place)
                        state.showSearch = false
                        state.pin(place)
                    } label: {
                        ResultRow(title: place.name, subtitle: place.address)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 22)
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trova nelle vicinanze")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
            VStack(spacing: 0) {
                ForEach(SearchService.nearbyCategories, id: \.self) { category in
                    Button {
                        focused = false
                        search.searchCategory(category)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(category)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .frame(height: 58)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(white: 0.06)))
        }
    }

    private var resultsList: some View {
        VStack(spacing: 10) {
            ForEach(Array(search.completions.enumerated()), id: \.offset) { _, completion in
                Button {
                    focused = false
                    search.resolve(completion) { item in
                        if let item = item { state.select(mapItem: item) }
                    }
                } label: {
                    ResultRow(title: completion.title, subtitle: completion.subtitle)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func categoryList(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    search.activeCategory = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold))
                        Text(category).font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(.bottom, 4)

            if search.isSearching {
                ProgressView().tint(.white).frame(maxWidth: .infinity).padding(.top, 30)
            } else if search.categoryResults.isEmpty {
                Text("Nessun risultato nelle vicinanze")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(.top, 20)
            } else {
                ForEach(Array(search.categoryResults.enumerated()), id: \.offset) { _, item in
                    Button { state.select(mapItem: item) } label: {
                        ResultRow(title: item.name ?? category,
                                  subtitle: distanceText(item) + Place.formatShort(item.placemark))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func distanceText(_ item: MKMapItem) -> String {
        guard let loc = location.location, let itemLoc = item.placemark.location else { return "" }
        return "\(state.units.value(loc.distance(from: itemLoc))) \(state.units.shortLabel) • "
    }
}

struct ResultRow: View {
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 22))
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0x4FA3FF), Color(hex: 0x1D6BFF)],
                                                    startPoint: .top, endPoint: .bottom))
                Circle().fill(Color(hex: 0x0A1E3D)).frame(width: 7, height: 7).offset(y: -2)
            }
            .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.isEmpty ? "Posizione" : title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(white: 0.07)))
        .contentShape(Rectangle())
    }
}
