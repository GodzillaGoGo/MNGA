//
//  PostRowView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/28/21.
//

import Foundation
import SwiftUI

struct PostRowView: View {
  let post: Post

  @State var showPostId = false

  @Binding var vote: VotesModel.Vote

  @EnvironmentObject var postScroll: PostScrollModel
  @EnvironmentObject var postReply: PostReplyModel
  @EnvironmentObject var authStorage: AuthStorage

  @ViewBuilder
  var header: some View {
    HStack {
      PostRowUserView.build(post: post)
        .equatable()
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
      Group {
        if !post.alterInfo.isEmpty {
          Image(systemName: "pencil")
        }
        DateTimeTextView.build(timestamp: post.postDate)
        Image(systemName: post.device.icon)
          .frame(width: 10)
      } .foregroundColor(.secondary)
        .font(.footnote)
    }
  }

  @ViewBuilder
  var comments: some View {
    if !post.comments.isEmpty {
      Divider()
      HStack {
        Spacer().frame(width: 6)
        VStack {
          ForEach(post.comments, id: \.hashIdentifiable) { comment in
            PostCommentRowView(comment: comment)
          }
        }
      }
    }
  }

  @ViewBuilder
  var voter: some View {
    HStack(spacing: 4) {
      Button(action: { doVote(.upvote) }) {
        Image(systemName: vote.state == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
          .foregroundColor(vote.state == .up ? .accentColor : .secondary)
          .frame(height: 24)
      } .buttonStyle(.plain)

      Text("\(max(Int32(post.score) + vote.delta, 0))")
        .foregroundColor(vote.state != .none ? .accentColor : .secondary)
        .font(.subheadline.monospacedDigit())

      Button(action: { doVote(.downvote) }) {
        Image(systemName: vote.state == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
          .foregroundColor(vote.state == .down ? .accentColor : .secondary)
          .frame(height: 24)
      } .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  var content: some View {
    PostContentView(spans: post.content.spans)
      .equatable()
  }

  @ViewBuilder
  var menu: some View {
    Button(action: { copyContent(post.content.raw) }) {
      Label("Copy Raw Content", systemImage: "doc.on.doc")
    }
    Button(action: { doQuote() }) {
      Label("Quote", systemImage: "quote.bubble")
    }
    Button(action: { doComment() }) {
      Label("Comment", systemImage: "tag")
    }
    if authStorage.authInfo.inner.uid == post.authorID {
      Button(action: { doEdit() }) {
        Label("Edit", systemImage: "pencil")
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      header
      content
      footer
      comments
    } .padding(.vertical, 4)
      .contextMenu { menu }
    #if os(iOS)
      .listRowBackground(postScroll.pid == self.post.id.pid ? Color.tertiarySystemBackground : nil)
    #endif
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

  func doVote(_ operation: PostVoteRequest.Operation) {
    logicCallAsync(.postVote(.with {
      $0.postID = post.id
      $0.operation = operation
    })) { (response: PostVoteResponse) in
      if !response.hasError {
        withAnimation {
          self.vote.state = response.state
          self.vote.delta += response.delta
          #if os(iOS)
            if self.vote.state != .none {
              HapticUtils.play(style: .light)
            }
          #endif
        }
      } else {
        // not used
      }
    }
  }

  func doQuote() {
    postReply.show(action: .with {
      $0.postID = self.post.id
      $0.operation = .quote
    })
  }
  
  func doComment() {
    postReply.show(action: .with {
      $0.postID = self.post.id
      $0.operation = .comment
    }, pageToReload: Int(self.post.atPage))
  }

  func doEdit() {
    postReply.show(action: .with {
      $0.postID = self.post.id
      $0.operation = .modify
    }, pageToReload: Int(self.post.atPage))
  }
}
