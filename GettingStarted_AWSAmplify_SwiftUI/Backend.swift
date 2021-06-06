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
    private init() { // initialize amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin()) // added from Module 3
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))// added from Module 4
            try Amplify.add(plugin: AWSS3StoragePlugin()) // added from Module 5, after installing S3 in Podfile
            try Amplify.configure()
            
            print("Initialized Amplify");
        } catch {
            
            print("Could not initialize Amplify: \(error)")
        }
        
        // listen to auth events.
        // see https://github.com/aws-amplify/amplify-ios/blob/master/Amplify/Categories/Auth/Models/AuthEventName.swift
        _ = Amplify.Hub.listen(to: .auth) { (payload) in
            
            switch payload.eventName {
            
            case HubPayload.EventName.Auth.signedIn:
                print("==HUB== User signed In, update UI")
                self.updateUserData(withSignInStatus: true)
                
            case HubPayload.EventName.Auth.signedOut:
                print("==HUB== User signed Out, update UI")
                self.updateUserData(withSignInStatus: false)
                
            case HubPayload.EventName.Auth.sessionExpired:
                print("==HUB== Session expired, show sign in UI")
                self.updateUserData(withSignInStatus: false)
                
            default:
                //print("==HUB== \(payload)")
                break
            }
        }
        
        // let's check if user is signedIn or not
        _ = Amplify.Auth.fetchAuthSession { (result) in
            do {
                let session = try result.get()
                
                // let's update UserData and the UI
                self.updateUserData(withSignInStatus: session.isSignedIn)
                
            } catch {
                print("Fetch auth session failed with error - \(error)")
            }
        }    
    }
    /*  We initialize our singleton Backend object when application finishes launching.
     
     Open the AppDelegate.swift file and add Backend.initialize(); in the application(:didFinishLaunchingWithOptions:) method
     */
    
    // MARK: - User Authentication
    
    // signin with Cognito web user interface
    public func signIn() {
        
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: UIApplication.shared.windows.first!) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
    // signout
    public func signOut() {
        
        _ = Amplify.Auth.signOut() { (result) in
            switch result {
            case .success:
                print("Successfully signed out")
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }
    
//    // change our internal state, this triggers an UI update on the main thread
//    func updateUserData(withSignInStatus status : Bool) {
//        DispatchQueue.main.async() {
//            let userData : UserData = .shared
//            userData.isSignedIn = status
//        }
//    }
    // change our internal state, this triggers an UI update on the main thread
    func updateUserData(withSignInStatus status : Bool) {
        DispatchQueue.main.async() {
            let userData : UserData = .shared
            userData.isSignedIn = status
            // the following lines are updated from Module 4
            // when user is signed in, query the database, otherwise empty our model
            if status {
                self.queryNotes()
            } else {
                userData.notes = []
            }
        }
    }
    
    // Add the following code from Module 4:
    
    // MARK: API Access
    
    func queryNotes() {
        
        _ = Amplify.API.query(request: .list(NoteData.self)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let notesData):
                    print("Successfully retrieved list of Notes")
                    
                    // convert an array of NoteData to an array of Note class instances
                    for n in notesData {
                        let note = Note.init(from: n)
                        DispatchQueue.main.async() {
                            UserData.shared.notes.append(note)
                        }
                    }
                    
                case .failure(let error):
                    print("Can not retrieve result : error  \(error.errorDescription)")
                }
            case .failure(let error):
                print("Can not retrieve Notes : error \(error)")
            }
        }
    }
    
    func createNote(note: Note) {
        
        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .create(note.data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully created note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
    
    func deleteNote(note: Note) {
        
        // use note.data to access the NoteData instance
        _ = Amplify.API.mutate(request: .delete(note.data)) { event in
            switch event {
            case .success(let result):
                switch result {
                case .success(let data):
                    print("Successfully deleted note: \(data)")
                case .failure(let error):
                    print("Got failed result with \(error.errorDescription)")
                }
            case .failure(let error):
                print("Got failed event with error \(error)")
            }
        }
    }
}
