//
//  Backend.swift
//  GettingStarted_AWSAmplify_SwiftUI
//
//  Created by Eric Widjaja on 6/4/21.
//
import UIKit
import Amplify
import AmplifyPlugins

class Backend {
    static let shared = Backend()
    static func initialize() -> Backend {
        return .shared
    }
    private init() {
        // initialize amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin()) // added from Module 3
            try Amplify.configure()
            print("Initialized Amplify");
        } catch {
            print("Could not initialize Amplify: \(error)")
        }
    }
}

//We initialize our singleton Backend object when application finishes launching.
//
//Open the AppDelegate.swift file and add Backend.initialize(); in the application(:didFinishLaunchingWithOptions:) method
