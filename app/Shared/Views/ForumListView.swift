//
//  ForumListView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/30/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI
import SwiftUIX

struct ForumView: View {
  let forum: Forum
  let isFavorite: Bool

  var body: some View {
    HStack {
      let defaultIcon = Image("default_forum_icon")

      if let url = URL(string: forum.iconURL) {
        WebImage(url: url)
          .resizable()
          .placeholder(defaultIcon)
          .frame(width: 28, height: 28)
      } else {
        defaultIcon
      }

      HStack {
        Text(forum.name)
        if forum.hasStid {
          Image(systemName: "arrow.uturn.right")
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        Spacer()

        HStack {
          Text(forum.info)
            .multilineTextAlignment(.trailing)
            .font(.footnote)
          if isFavorite {
            Text(Image(systemName: "star.fill"))
              .font(.caption2)
          }
        } .foregroundColor(.secondary)
      }
    }

  }
}

struct UserMenu: View {
  @EnvironmentObject var authStorage: AuthStorage

  @State var user: User? = nil

  var body: some View {
    let uid = authStorage.authInfo.inner.uid
    let shouldLogin = authStorage.shouldLogin

    Menu {
      Section {
        if !shouldLogin {
          if let user = self.user {
            Menu {
              Label(user.id, systemImage: "number")
              Label {
                Text(Date(timeIntervalSince1970: TimeInterval(user.regDate)), style: .date)
              } icon: {
                Image(systemName: "calendar")
              }
              Label("\(user.postNum) Posts", systemImage: "text.bubble")
            } label: {
              Label(user.name, systemImage: "person.fill")
            }
          } else {
            Label(uid, systemImage: "person.fill")
          }
        }
      }
      Section {
        if shouldLogin {
          Button(action: { authStorage.clearAuth() }) {
            Label("Sign In", systemImage: "person.crop.circle.badge.plus")
          }
        } else {
          Button(action: { authStorage.clearAuth() }) {
            Label("Sign Out", systemImage: "person.crop.circle.fill.badge.minus")
          }
        }
      }
    } label: {
      let icon = shouldLogin ? "person.crop.circle" : "person.crop.circle.fill"
      Label("Me", systemImage: icon)
    }
      .imageScale(.large)
      .onAppear { loadData() }
      .onChange(of: authStorage.authInfo) { _ in loadData() }
  }

  func loadData() {
    let uid = authStorage.authInfo.inner.uid
    logicCallAsync(.remoteUser(.with { $0.userID = uid })) { (response: RemoteUserResponse) in
      if response.hasUser {
        self.user = response.user
      }
    }
  }
}

struct ForumListView: View {
  @StateObject var favorites = FavoriteForumsStorage()

  @State var categories = [Category]()
  @State var searchText: String = ""
  @State var isSearching: Bool = false

  @ViewBuilder
  func buildLink(_ forum: Forum, inFavoritesSection: Bool = true) -> some View {
    let isFavorite = favorites.isFavorite(id: forum.id)

    NavigationLink(destination: TopicListView(forum: forum)) {
      ForumView(forum: forum, isFavorite: inFavoritesSection && isFavorite)
        .contextMenu(ContextMenu(menuItems: {
        Button(action: {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation { favorites.toggleFavorite(forum: forum) }
          }
        }) {
          let text: LocalizedStringKey = isFavorite ? "Remove from Favorites" : "Mark as Favorite"
          let image = isFavorite ? "star.slash.fill" : "star"
          Label(text, systemImage: image)
        }
      }))
    }
  }

  var favoritesSection: some View {
    Section(header: Text("Favorites").font(.subheadline).fontWeight(.medium)) {
      if favorites.favoriteForums.isEmpty {
        HStack {
          Spacer()
          Text("No Favorites")
            .font(.footnote)
            .foregroundColor(.secondary)
          Spacer()
        }
      } else {
        ForEach(favorites.favoriteForums, id: \.id) { forum in
          buildLink(forum, inFavoritesSection: false)
        } .onDelete { offsets in
          favorites.favoriteForums.remove(atOffsets: offsets)
        }
      }
    }
  }

  var allForumsSection: some View {
    Group {
      if categories.isEmpty {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
      } else {
        ForEach(categories, id: \.id) { category in
          let forums = category.forums.filter {
            searchText.isEmpty || $0.name.contains(searchText)
          }
          if !forums.isEmpty {
            Section(header: Text(category.name).font(.subheadline).fontWeight(.medium)) {
              ForEach(forums, id: \.id) { forum in
                buildLink(forum)
              }
            }
          }
        }
      }
    }
  }

  var filterMenu: some View {
    Menu {
      Section {
        Picker(selection: $favorites.filterMode.animation(), label: Text("Filter Mode")) {
          ForEach(FavoriteForumsStorage.FilterMode.allCases, id: \.rawValue) { mode in
            HStack {
              Text(LocalizedStringKey(mode.rawValue))
              Spacer()
              Image(systemName: mode.icon)
            } .tag(mode)
          }
        }
      }
    } label: {
      Label("Filters", systemImage: favorites.filterMode.filterIcon)
    }
  }

  var body: some View {
    VStack {
      List {
        if searchText.isEmpty && !isSearching {
          favoritesSection
        }
        if favorites.filterMode == .all || isSearching {
          allForumsSection
        }
      }
    } .onAppear { loadData() }
      .navigationTitle("Forums")
      .navigationSearchBar {
      SearchBar(
        NSLocalizedString("Search Forums", comment: ""),
        text: $searchText,
        isEditing: $isSearching.animation()
      )
    }
      .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        UserMenu()
      }
      ToolbarItem(placement: .navigationBarTrailing) {
        filterMenu.imageScale(.large)
      }
    }
  }

  func loadData() {
    guard categories.isEmpty else { return }

    logicCallAsync(.forumList(.with { _ in }))
    { (response: ForumListResponse) in
      withAnimation {
        categories = response.categories
      }
    }
  }
}

struct ForumListView_Previews: PreviewProvider {
  static var previews: some View {
    AuthedPreview {
      NavigationView {
        ForumListView()
      }
    }
  }
}
