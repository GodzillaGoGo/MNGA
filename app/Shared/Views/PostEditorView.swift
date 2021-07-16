//
//  PostEditorView.swift
//  PostEditorView
//
//  Created by Bugen Zhao on 7/16/21.
//

import Foundation
import SwiftUI

struct PostEditorView: View {
  enum DisplayMode: String, CaseIterable {
    case plain = "Plain"
    case preview = "Preview"
  }

  @EnvironmentObject var postReply: PostReplyModel
  @State var displayMode = DisplayMode.plain
  @State var spans = [Span]()

  @ViewBuilder
  var picker: some View {
    Picker("Display Mode", selection: $displayMode) {
      ForEach(DisplayMode.allCases, id: \.rawValue) {
        Text(LocalizedStringKey($0.rawValue)).tag($0)
      }
    } .pickerStyle(.segmented)
  }

  @ViewBuilder
  var inner: some View {
    VStack(alignment: .leading) {
      picker

      switch displayMode {
      case .plain:
        TextEditor(text: $postReply.content)
      case .preview:
        ScrollView {
          PostContentView(spans: spans)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } .onAppear { parseContent() }
      }
    } .padding([.horizontal, .top])
  }

  func parseContent() {
    DispatchQueue.global(qos: .userInitiated).async {
      let response: ContentParseResponse? = try? logicCall(.contentParse(.with { $0.raw = postReply.content }))
      DispatchQueue.main.async {
        self.spans = response?.content.spans ?? []
      }
    }
  }

  var body: some View {
    NavigationView {
      inner
        .modifier(AlertToastModifier())
        .navigationBarTitle(postReply.action?.title ?? "Editor", displayMode: .inline)
        .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(action: { doSend() }) {
            if postReply.isSending {
              ProgressView()
            } else {
              Text("Send")
            }
          }
        }
      }
    }
  }

  func doSend() {
    self.postReply.send()
  }
}


struct PostEditorView_Previews: PreviewProvider {
  struct Preview: View {
    @StateObject var postReply = PostReplyModel()
    let defaultText: String

    var body: some View {
      PostEditorView()
        .environmentObject(postReply)
        .onAppear { postReply.show(action: .init(), content: defaultText) }
    }
  }

  static var previews: some View {
    Preview(defaultText: "Test\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\nTest\n")
  }
}
