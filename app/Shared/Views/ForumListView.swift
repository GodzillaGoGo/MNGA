//
//  ForumListView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/30/21.
//

import Foundation
import SwiftUI
import RemoteImage

struct ForumView: View {
  let forum: Forum

  var body: some View {
    HStack {
//      let defaultIcon = Image(systemName: "bubble.left.and.bubble.right")
//        .foregroundColor(.accentColor)
      
      let defaultIcon = Image("default_forum_icon").resizable()

      if let url = URL(string: forum.iconURL) {
        RemoteImage(
          type: .url(url),
          errorView: { _ in defaultIcon },
          imageView: { image in
            image.resizable()
          },
          loadingView: { defaultIcon }
        ) .frame(width: 28, height: 28)
      } else {
        defaultIcon
      }

      VStack(alignment: .leading) {
        Text(forum.name)
        if !forum.info.isEmpty {
          Text(forum.info)
            .font(.footnote)
            .foregroundColor(.secondary)
        }
      }
    }

  }
}

struct ForumListView: View {
  @State var forums = [Forum]()

  public let defaultForum = Forum.with {
    $0.id = "-7"
    $0.name = "网事杂谈"
    $0.info = "大漩涡"
  }

  func buildLink(_ forum: Forum) -> some View {
    return NavigationLink(destination: TopicListView(forum: forum)) {
      ForumView(forum: forum)
    }
  }

  var body: some View {
    VStack {
      let list = List {
        if forums.isEmpty {
          HStack {
            Spacer(); ProgressView(); Spacer()
          } .onAppear { loadData() }
        } else {
//          buildLink(defaultForum)
          ForEach(forums, id: \.id) { forum in
            buildLink(forum)
          }
        }
      }
      #if os(iOS)
        list
      #else
        list
      #endif
    } .navigationTitle("Forums")
  }

  func loadData() {
    guard forums.isEmpty else { return }

    logicCallAsync(.forumList(.with { _ in }))
    { (response: ForumListResponse) in
      forums = response.forums
    }
  }
}

struct ForumListView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      ForumListView()
    }
  }
}
