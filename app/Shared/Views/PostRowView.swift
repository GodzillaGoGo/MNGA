//
//  PostRowView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/28/21.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct PostRowUserView: View {
  let post: Post
  let user: User?

  @State var showId = false

  init(post: Post) {
    self.post = post
    self.user = try! (logicCall(.localUser(.with { $0.userID = post.authorID })) as LocalUserResponse).user
  }

  @ViewBuilder
  var avatar: some View {
    let placeholder = Image(systemName: "person.circle.fill")
      .resizable()

    if let url = URL(string: user?.avatarURL ?? "") {
      WebImage(url: url)
        .resizable()
        .placeholder(placeholder)
    } else {
      placeholder
    }
  }

  var body: some View {
    HStack {
      avatar
        .foregroundColor(.accentColor)
        .frame(width: 36, height: 36)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 2) {
        Group {
          if showId {
            Text(post.authorID)
          } else {
            Text(user?.name ?? post.authorID)
          }
        } .font(.subheadline)
          .onTapGesture { withAnimation { self.showId.toggle() } }

        HStack(spacing: 6) {

          HStack(spacing: 2) {
            Image(systemName: "text.bubble")
            Text("\(user?.postNum ?? 0)")
          }
          HStack(spacing: 2) {
            Image(systemName: "calendar")
            Text(Date(timeIntervalSince1970: TimeInterval(user?.regDate ?? 0)), style: .date)
          }
          HStack(spacing: 2) {
            Image(systemName: "flag")
            Text("\(user?.fame ?? 0)")
          }

        } .font(.footnote)
          .foregroundColor(.secondary)
      }
    }
  }
}

struct PostRowView: View {
  let post: Post

  @State var delta: Int32 = 0
  @State var voteState: VoteState

  @State var showPostId = false

  @EnvironmentObject var postScroll: PostScrollModel

  init(post: Post) {
    self.post = post
    self._voteState = .init(wrappedValue: post.voteState)
  }

  @ViewBuilder
  var header: some View {
    HStack {
      PostRowUserView(post: post)
      Spacer()
      (Text("#").font(.footnote) + Text(showPostId ? post.id.pid : "\(post.floor)").font(.callout))
        .fontWeight(.medium)
        .foregroundColor(.accentColor)
        .onTapGesture { withAnimation { self.showPostId.toggle() } }
    }
  }

  @ViewBuilder
  var footer: some View {
    HStack {
      voter
      Spacer()
      DateTimeTextView(timestamp: post.postDate)
        .foregroundColor(.secondary)
        .font(.footnote)
    }
  }

  @ViewBuilder
  var voter: some View {
    HStack(spacing: 4) {
      Image(systemName: voteState == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
        .foregroundColor(voteState == .up ? .accentColor : .secondary)
        .frame(height: 24)
        .onTapGesture { vote(.upvote) }

      Text("\(max(Int32(post.score) + delta, 0))")
        .foregroundColor(voteState != .none ? .accentColor : .secondary)
        .font(.subheadline.monospacedDigit())

      Image(systemName: voteState == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
        .foregroundColor(voteState == .down ? .accentColor : .secondary)
        .frame(height: 24)
        .onTapGesture { vote(.downvote) }
    }
  }

  @ViewBuilder
  var content: some View {
    PostContentView(spans: post.content.spans)
      .equatable()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      content
      footer
    } .padding(.vertical, 4)
      .contextMenu {
      Button(action: { copyContent(post.content.raw) }) {
        Label("Copy Raw Content", systemImage: "doc.on.doc")
      }
    } .listRowBackground(postScroll.pid == self.post.id.pid ? Color.tertiarySystemBackground : nil)
  }

  func copyContent(_ content: String) {
    #if os(iOS)
      UIPasteboard.general.string = content
    #elseif os(macOS)
      let pb = NSPasteboard.general
      pb.clearContents()
      pb.writeObjects([content as NSString])
    #endif
  }

  func vote(_ operation: PostVoteRequest.Operation) {
    logicCallAsync(.postVote(.with {
      $0.postID = post.id
      $0.operation = operation
    })) { (response: PostVoteResponse) in
      if !response.hasError {
        withAnimation {
          self.voteState = response.state
          self.delta += response.delta
        }
      } else {
        // error
      }
    }
  }
}
