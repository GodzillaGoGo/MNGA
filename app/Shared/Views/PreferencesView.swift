//
//  PreferencesView.swift
//  NGA
//
//  Created by Bugen Zhao on 7/20/21.
//

import Foundation
import SwiftUI

private struct PostRowAppearanceView: View {
  @ObservedObject var pref: PreferencesStorage

  var body: some View {
    Form {
      Section(header: Text("Preview")) {
        PostRowView.build(post: .dummy, isAuthor: true, vote: .constant((state: .up, delta: 0)))
      }

      Section {
        Picker(selection: $pref.postRowSwipeActionLeading, label: Label("Swipe Trigger Edge", systemImage: "rectangle.portrait.arrowtriangle.2.outward")) {
          Text("Leading").tag(true)
          Text("Trailing").tag(false)
        }

        Picker(selection: $pref.postRowDateTimeStrategy.animation(), label: Label("Date Display", systemImage: "calendar")) {
          ForEach(DateTimeTextView.Strategy.allCases, id: \.self) { s in
            Text(s.description).tag(s)
          }
        }

        Toggle(isOn: $pref.showSignature.animation()) {
          Label("Show Signature", systemImage: "signature")
        }

        Toggle(isOn: $pref.showAvatar.animation()) {
          Label("Show Avatar", systemImage: "person.crop.circle")
        }
      }

      Section {
        Toggle(isOn: $pref.postRowShowAuthorIndicator.animation()) {
          Text("Show Author Indicator")
        }
        Toggle(isOn: $pref.postRowShowUserDetails.animation()) {
          Text("Show User Details")
        }
        if pref.postRowShowUserDetails {
          Toggle(isOn: $pref.postRowShowUserRegDate.animation()) {
            Text("Show User Register Date")
          }
        }
      }

      Section {
        Toggle(isOn: $pref.usePaginatedDetails) {
          Label("Paginated Reading", systemImage: "square.stack")
        }
      }
    }.tint(.accentColor)
      .navigationTitleInline(string: "")
  }
}

private struct TopicListAppearanceView: View {
  @ObservedObject var pref: PreferencesStorage

  var body: some View {
    Form {
      Picker(selection: $pref.defaultTopicListOrder, label: Label("Default Order", systemImage: "arrow.up.arrow.down")) {
        ForEach(TopicListRequest.Order.allCases, id: \.self) { order in
          Label(order.description, systemImage: order.icon).tag(order)
        }
      }
    }.tint(.accentColor)
      .navigationTitleInline(string: "")
  }
}

struct PreferencesInnerView: View {
  @StateObject var pref = PreferencesStorage.shared

  @ViewBuilder
  var appearance: some View {
    Picker(selection: $pref.colorScheme, label: Label("Color Scheme", systemImage: "rays")) {
      ForEach(ColorSchemeMode.allCases, id: \.self) { mode in
        Text(mode.description)
      }
    }
    Picker(selection: $pref.themeColor, label: Label("Theme Color", systemImage: "circle")) {
      ForEach(ThemeColor.allCases, id: \.self) { color in
        Label(color.description) {
//          Image(systemName: "circle.fill")
//            .foregroundColor(color.color ?? Color("AccentColor"))
        }.tag(color)
      }
    }
    Picker(selection: $pref.useInsetGrouped, label: Label("List Style", systemImage: "list.bullet.rectangle.portrait")) {
      Text("Compact").tag(false)
      Text("Modern").tag(true)
    }
  }

  @ViewBuilder
  var reading: some View {
    NavigationLink(destination: BlockWordListView()) {
      Label("Block Contents", systemImage: "hand.raised")
    }
    NavigationLink(destination: TopicListAppearanceView(pref: pref)) {
      Label("Topic List Style", systemImage: "list.dash")
    }
    NavigationLink(destination: PostRowAppearanceView(pref: pref)) {
      Label("Topic Details Style", systemImage: "list.bullet.below.rectangle")
    }

    Toggle(isOn: $pref.useInAppSafari) {
      Label("Always Use In-App Safari", systemImage: "safari")
    }
    Toggle(isOn: $pref.hideMNGAMeta) {
      Label("Hide MNGA Meta", systemImage: "eye.slash")
    }
  }

  @ViewBuilder
  var connection: some View {
    Group {
      Picker(selection: $pref.requestOption.baseURLV2, label: Label("Backend", systemImage: "server.rack")) {
        ForEach(URLs.hosts, id: \.self) { host in
          Text(host).tag(URLs.base(for: host)!.absoluteString)
        }
      }
      Picker(selection: $pref.requestOption.mockBaseURLV2, label: Label("MNGA Backend", systemImage: "server.rack")) {
        ForEach(URLs.mockHosts, id: \.self) { host in
          let url = URLs.base(for: host)!
          Text(url.host!).tag(url.absoluteString)
        }
      }
    }.lineLimit(1)

    Picker(selection: $pref.requestOption.device, label: Label("Device Identity", systemImage: "ipad.and.iphone")) {
      ForEach(Device.allCases, id: \.self) { device in
        Label(device.description, systemImage: device.icon).tag(device)
      }
    }.disabled(pref.requestOption.randomUa)
  }

  @ViewBuilder
  var advanced: some View {
    Toggle(isOn: $pref.imageViewerEnableZoom) {
      Label("Enable Zoom for Image Viewer", systemImage: "arrow.up.left.and.arrow.down.right")
    }
  }

  @ViewBuilder
  var special: some View {
    Group {
      Toggle(isOn: $pref.autoOpenInBrowserWhenBanned) {
        Label("Auto Open in Browser when Banned", systemImage: "network")
      }

      Toggle(isOn: $pref.requestOption.randomUa) {
        Label("Random Device Identity", systemImage: "ipad.and.iphone")
      }
    }
  }

  #if os(macOS)
    var body: some View {
      TabView {
        Form { appearance }
          .tabItem { Label("Appearance", systemImage: "circle") }
          .tag("appearance")
        Form { reading }
          .tabItem { Label("Reading", systemImage: "eyeglasses") }
          .tag("reading")
        Form { connection }
          .tabItem { Label("Connection", systemImage: "network") }
          .tag("connection")
        Form { advanced }
          .tabItem { Label("Advanced", systemImage: "gearshape.2") }
          .tag("advanced")
      }.tint(.accentColor)
        .pickerStyle(InlinePickerStyle())
        .padding(20)
        .frame(width: 500)
    }
  #else
    var body: some View {
      Form {
        Section(header: Text("Special"), footer: Text("NGA Workaround")) {
          special
        }

        Section(header: Text("Appearance")) {
          appearance
        }

        Section(header: Text("Reading")) {
          reading
        }

        Section(header: Text("Connection")) {
          connection
        }

        Section(header: Text("Advanced"), footer: Text("Options here are experimental or unstable.")) {
          NavigationLink(destination: CacheView()) {
            Label("Cache", systemImage: "internaldrive")
          }
          advanced
        }
      }
      .tint(.accentColor)
      .mayInsetGroupedListStyle()
      .navigationTitle("Preferences")
      .preferredColorScheme(pref.colorScheme.scheme) // workaround
    }
  #endif
}

struct PreferencesView: View {
  var body: some View {
    NavigationView {
      PreferencesInnerView()
    }
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static let model = PostReplyModel()

  static var previews: some View {
    PreferencesView()
      .environmentObject(model)
  }
}
