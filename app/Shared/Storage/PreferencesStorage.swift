//
//  PreferencesStorage.swift
//  PreferencesStorage
//
//  Created by Bugen Zhao on 7/20/21.
//

import Foundation
import Combine
import SwiftUI

class PreferencesStorage: ObservableObject {
  static let shared = PreferencesStorage()
  
  @AppStorage("showSignature") var showSignature = true
  @AppStorage("useRedact") var useRedact = true
}