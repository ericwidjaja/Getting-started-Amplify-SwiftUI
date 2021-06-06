//  ContentView.swift
//  GettingStarted_AWSAmplify_SwiftUI
//  Created by Eric Widjaja on 6/4/21.

import SwiftUI

// singleton object to store user data
class UserData : ObservableObject {
    private init() {}
    static let shared = UserData()
    
    @Published var notes : [Note] = []
    @Published var isSignedIn : Bool = false
}

// the data class to represents Notes
class Note : Identifiable, ObservableObject {
    var id : String
    var name : String
    var description : String?
    var imageName : String?
    @Published var image : Image?
    
    init(id: String, name: String, description: String? = nil, image: String? = nil ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = image
    }
    
    // from Module 4 - to add this initializer in the Note class
    convenience init(from data: NoteData) {
        self.init(id: data.id, name: data.name, description: data.description, image: data.image)
        /* from Module 5 - to load the images when the API call returns
         When an image name is present in the instance of Note, the code calls retrieveImage. This is an asynchronous function. It takes a function to call when the image is downloaded. The function creates an Image UI object and assign it to the instance of Note. Notice that this assignment triggers a User Interface update, hence it happens on the main thread of the application with DispatchQueue.main.async.
         */
        if let name = self.imageName {
            // asynchronously download the image
            Backend.shared.retrieveImage(name: name) { (data) in
                // update the UI on the main thread
                DispatchQueue.main.async() {
                    let uim = UIImage(data: data)
                    self.image = Image(uiImage: uim!)
                }
            }
        }
        // store API object for easy retrieval later
        self._data = data
    }
    
    fileprivate var _data : NoteData?
    
    // access the privately stored NoteData or build one if we don't have one.
    var data : NoteData {
        
        if (_data == nil) {
            _data = NoteData(id: self.id,
                             name: self.name,
                             description: self.description,
                             image: self.imageName)
        }
        
        return _data!
    }
}

// a view to represent a single list item
struct ListRow: View {
    @ObservedObject var note : Note
    var body: some View {
        
        return HStack(alignment: .center, spacing: 5.0) {
            
            // if there is an image, display it on the left
            if (note.image != nil) {
                note.image!
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            
            // the right part is a vertical stack with the title and description
            VStack(alignment: .leading, spacing: 5.0) {
                Text(note.name)
                    .bold()
                
                if ((note.description) != nil) {
                    Text(note.description!)
                }
            }
        }
    }
}

// this is the main view of our app,
// it is made of a Table with one line per Note
struct ContentView: View {
    // from Module 4 - add at the begining of ContentView class
    @State var showCreateNote = false
    
    @State var name : String        = "New Note"
    @State var description : String = "This is a new note"
    //    @State var image : String       = "image"
    
    @State var image : UIImage? // replace the previous declaration of image
    @State var showCaptureImageView = false
    
    @ObservedObject private var userData: UserData = .shared
    
    //    var body: some View {
    //        List {
    //            ForEach(userData.notes) { note in
    //                ListRow(note: note)
    //            }
    //        }
    //    }
    
    // update UI from Module 3
    
    var body: some View {
        
        ZStack {
            if (userData.isSignedIn) {
                NavigationView {
                    List {
                        //                        ForEach(userData.notes) { note in
                        //                            ListRow(note: note)
                        //                        }
                        // from Module 4 - add the 'swipe to delete' behavior: add the .onDelete { } method to the ForEach struct by replacing the above line with:
                        
                        ForEach(userData.notes) { note in
                            ListRow(note: note)
                        }.onDelete { indices in
                            indices.forEach {
                                // removing from user data will refresh UI
                                let note = self.userData.notes.remove(at: $0)
                                
                                // asynchronously remove from database
                                Backend.shared.deleteNote(note: note)
                            }
                        }
                    }
                    .navigationBarTitle(Text("Notes"))
                    //                    .navigationBarItems(leading: SignOutButton())
                    //  from Module 4.c Add a + button on the navigation bar to present a sheet to create a Note - by replacing the above line with the following:
                    .navigationBarItems(leading: SignOutButton(),
                                        trailing: Button(action: {
                                            self.showCreateNote.toggle()
                                        }) {
                                            Image(systemName: "plus")
                                        })
                }.sheet(isPresented: $showCreateNote) {
                    AddNoteView(isPresented: self.$showCreateNote, userData: self.userData)
                }
                
            } else {
                
                SignInButton()
            }
        }
    }
}

// add signIn and signOut buttons - for updateUI in Module 3

struct SignInButton: View {
    var body: some View {
        Button(action: { Backend.shared.signIn() }){
            HStack {
                Image(systemName: "person.fill")
                    .scaleEffect(1.5)
                    .padding()
                Text("Sign In")
                    .font(.largeTitle)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.green)
            .cornerRadius(30)
        }
    }
}

struct SignOutButton : View {
    var body: some View {
        Button(action: { Backend.shared.signOut() }) {
            Text("Sign Out")
        }
    }
}


// this is use to preview the UI in Xcode
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        let _ = prepareTestData()
        
        return ContentView()
    }
}

// from Module 4 - add a View struct to let user create a new Note:

struct AddNoteView: View {
    @Binding var isPresented: Bool
    var userData: UserData
    
    @State var name : String        = "New Note"
    @State var description : String = "This is a new note"
//    @State var image : String       = "image"
    @State var image : UIImage? // replace the previous declaration of image
    @State var showCaptureImageView = false
    var body: some View {
        Form {
            
            Section(header: Text("TEXT")) {
                TextField("Name", text: $name)
                TextField("Name", text: $description)
            }
            
            Section(header: Text("PICTURE")) {
                //           TextField("Name", text: $image) // replace with button to show captured image
                VStack {
                    Button(action: {
                        self.showCaptureImageView.toggle()
                    }) {
                        Text("Choose photo")
                    }.sheet(isPresented: $showCaptureImageView) {
                        CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image)
                    }
                    if (image != nil ) {
                        HStack {
                            Spacer()
                            Image(uiImage: image!)
                                .resizable()
                                .frame(width: 250, height: 200)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 10)
                            Spacer()
                        }
                    }
                }
            }
            
//            Section {
//                Button(action: {
//                    self.isPresented = false
//                    let noteData = NoteData(id : UUID().uuidString,
//                                            name: self.$name.wrappedValue,
//                                            description: self.$description.wrappedValue)
//                    let note = Note(from: noteData)
//
//                    // asynchronously store the note (and assume it will succeed)
//                    Backend.shared.createNote(note: note)
//
//                    // add the new note in our userdata, this will refresh UI
//                    self.userData.notes.append(note)
//                }) {
//                    Text("Create this note")
//                }
//            }
            
            //From Module 5 - storing image when note is created
            Section {
                Button(action: {
                    self.isPresented = false

                    let note = Note(id : UUID().uuidString,
                                    name: self.$name.wrappedValue,
                                    description: self.$description.wrappedValue)

                    if let i = self.image  {
                        note.imageName = UUID().uuidString
                        note.image = Image(uiImage: i)

                        // asynchronously store the image (and assume it will work)
                        Backend.shared.storeImage(name: note.imageName!, image: (i.pngData())!)
                    }

                    // asynchronously store the note (and assume it will succeed)
                    Backend.shared.createNote(note: note)

                    // add the new note in our userdata, this will refresh UI
                    withAnimation { self.userData.notes.append(note) }
                }) {
                    Text("Create this note")
                }
            }
            
        }
    }
}

// this is a test data set to preview the UI in Xcode
func prepareTestData() -> UserData {
    let userData = UserData.shared
    userData.isSignedIn = true
    let desc = "this is a very long description that should fit on multiiple lines.\nit even has a line break\nor two."
    
    let n1 = Note(id: "01", name: "Hello world", description: desc, image: "mic")
    let n2 = Note(id: "02", name: "A new note", description: desc, image: "phone")
    
    n1.image = Image(systemName: n1.imageName!)
    n2.image = Image(systemName: n2.imageName!)
    
    userData.notes = [ n1, n2 ]
    
    return userData
}
