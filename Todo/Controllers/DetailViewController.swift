

import UIKit
import Firebase
import AVFoundation
import GoogleSignIn
import GoogleAPIClientForREST

class DetailViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, GIDSignInDelegate {

    @IBOutlet weak var checkBox: UIButton!
    
    @IBOutlet weak var star: UIButton!
    
    @IBOutlet weak var descriptionView: UITextView!
    
    @IBOutlet weak var updateButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var calendarButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var recordingLabel: UILabel!
    
    @IBOutlet weak var dateView: UIView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    private let service = GTLRCalendarService()
    private let scopes = [kGTLRAuthScopeCalendar]
    
    var item: Item!
    var db: Firestore!
    let storage = Storage.storage()
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var recordedAudioURL: URL!
    var recordingDidHappen: Bool = false
    var recordingStorageRef: URL?
    
    var checked: Bool! {
        didSet {
            if checked == true {
                checkBox.setImage(UIImage(systemName:"checkmark.square"), for: .normal)
            } else {
                checkBox.setImage(UIImage(systemName:"square"), for: .normal)
            }
        }
    }
    var starred: Bool! {
        didSet {
            if starred == true{
                star.setImage(UIImage(systemName:"star.fill"), for: .normal)
            } else {
                star.setImage(UIImage(systemName:"star"), for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().signOut()
        let doc = db.collection(K.FStore.collectionName).document(item.id)
        doc.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()!
                self.descriptionView.text = data[K.FStore.descriptionField] as? String
                self.checked = data[K.FStore.statusField] as? Bool
                self.starred = data[K.FStore.starField] as? Bool
                print("Document data: \(data)")
            } else {
                print("Document does not exist")
            }
        }
        stopButton.isEnabled = false
        stopButton.alpha = 0
        stopButton.tintColor = UIColor(named: K.BrandColors.blue)
        if recordingStorageRef != URL(string: "todo.com") {
            playButton.isEnabled = true
            playButton.tintColor = UIColor.systemYellow
            playButton.alpha = 1
            
            
        } else {
            playButton.isEnabled = false
            playButton.alpha = 0
            playButton.tintColor = UIColor(named: K.BrandColors.blue)
        }
        recordingDidHappen = false
        datePicker.isEnabled = false
        datePicker.alpha = 0
        okButton.alpha = 0
        okButton.isEnabled = false
        dateView.alpha = 0
        recordingLabel.adjustsFontSizeToFitWidth = true
    }

    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
        
    }
    
    // Present a view that prompts the user to sign in with Google
    func signIn(signIn: GIDSignIn!,
                presentViewController viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func signIn(signIn: GIDSignIn!,
                dismissViewController viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    

    
    fileprivate lazy var calendarService: GTLRCalendarService? = {
        let service = GTLRCalendarService()
        // Have the service object set tickets to fetch consecutive pages
        // of the feed so we do not need to manually fetch them
        service.shouldFetchNextPages = true
        // Have the service object set tickets to retry temporary error conditions
        // automatically
        service.isRetryEnabled = true
        service.maxRetryInterval = 15
        
        guard let currentUser = GIDSignIn.sharedInstance().currentUser,
            let authentication = currentUser.authentication else {
                return nil
        }
        service.authorizer = authentication.fetcherAuthorizer()
        return service
    }()
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            print("Authentication Error: \(error.localizedDescription)")
            //            self.service.authorizer = nil
        } else {
            //              self.signInButton.isHidden = true
            //             self.output.isHidden = false
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            //           print(self.service.apiKey)
            print("Detail View Controller: didSignInFor")
            print("sign in successful")
            print(GIDSignIn.sharedInstance().clientID as Any )
            print(GIDSignIn.sharedInstance()?.currentUser as Any)
            print(GIDSignIn.sharedInstance()?.scopes as Any)
            print("printing user email: \(GIDSignIn.sharedInstance()?.currentUser.profile.email)")
            
            print(user.authentication)
            print(user.grantedScopes)
            print("printing user email: \(user.profile.email)")
            print("printing user ID: \(user.userID.description)")
            datePicker.isEnabled = true
            datePicker.alpha = 1
            
            okButton.alpha = 1
            okButton.isEnabled = true
            dateView.alpha = 1
            
            fetchEvents()
        }
    }
    
    func fetchEvents() {
        print("fetch events called")
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.maxResults = 10
        query.timeMin = GTLRDateTime(date: Date())
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        service.executeQuery(
            query,
            delegate: self,
            didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))
    }
    
    @objc func displayResultWithTicket(
        ticket: GTLRServiceTicket,
        finishedWithObject response : GTLRCalendar_Events,
        error : NSError?) {
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        var outputText = ""
        if let events = response.items, !events.isEmpty {
            for event in events {
                let start = event.start!.dateTime ?? event.start!.date!
                let startString = DateFormatter.localizedString(
                    from: start.date,
                    dateStyle: .short,
                    timeStyle: .short)
                outputText += "\(startString) - \(event.summary!)\n"
            }
        } else {
            outputText = "No upcoming events found."
        }
        // output.text = outputText
        print("displayResultWithTicket: \(outputText)")
    }
    
    func getEvents(for calendarId: String) {
           guard let service = self.calendarService else {
               
               return
           }
           print("able to get into getEvents")
           // You can pass start and end dates with function parameters
           let startDateTime = GTLRDateTime(date: Calendar.current.startOfDay(for: Date()))
           let endDateTime = GTLRDateTime(date: Date().addingTimeInterval(60*60*24))
           
           let eventsListQuery = GTLRCalendarQuery_EventsList.query(withCalendarId: calendarId)
           eventsListQuery.timeMin = startDateTime
           eventsListQuery.timeMax = endDateTime
           
           _ = service.executeQuery(eventsListQuery, completionHandler: { (ticket, result, error) in
               guard error == nil, let items = (result as? GTLRCalendar_Events)?.items else {
                   
                   print(error)
                   return
               }
               
               if items.count > 0 {
                   print(items)
                   // Do stuff with your events
               } else {
                   // No events
               }
           })
       }
       
    func addAnEvent() {
           
           guard let service = self.calendarService else {
               
               return
               
           }
           
           var event = GTLRCalendar_Event()
           
           event.summary = item.description
           let startDateTime = GTLRDateTime(date: Date())
           
           let endDateTime = GTLRDateTime(date: Date().addingTimeInterval(60*60))
           
           event.start = GTLRCalendar_EventDateTime()
           
           event.start?.dateTime = startDateTime
           event.end = GTLRCalendar_EventDateTime()
           
           event.end?.dateTime = endDateTime
           
           let eventsInsertQuery = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
           
           _ = service.executeQuery(eventsInsertQuery, completionHandler: { (ticket, result, error) in guard error == nil else {
               
               return
               
               }
               
           })
           
       }
       
       
       
       
       
       // Create an event to the Google Calendar's user
       func addEventoToGoogleCalendar(summary : String, description :String, startTime : String, endTime : String) {
           
           
           let calendarEvent = GTLRCalendar_Event()
           
           calendarEvent.summary = "\(summary)"
           calendarEvent.descriptionProperty = "\(description)"
           
           let dateFormatter = DateFormatter()
           
           dateFormatter.dateFormat = "MM/dd/yy, H:mm a"
           dateFormatter.timeZone = .current
           
           var tempString = startTime
           
           
           print("before: \(tempString)")
           if tempString[tempString.index(tempString.startIndex, offsetBy: 1)] == "/" {
               tempString.insert("0", at: tempString.index(tempString.startIndex, offsetBy: 0))
           }
           
           if tempString[tempString.index(tempString.startIndex, offsetBy: 4)] == "/" {
               tempString.insert("0", at: tempString.index(tempString.startIndex, offsetBy: 3))
           }
           
           
           
           print("after: \(tempString)")
           
           
           let startDate = dateFormatter.date(from: tempString)
           let endDate = dateFormatter.date(from: tempString)
           
           
           
           guard let toBuildDateStart = startDate else {
               print("Error getting start date")
               return
           }
           guard let toBuildDateEnd = endDate else {
               print("Error getting end date")
               return
           }
           print(toBuildDateStart)
           
           print(toBuildDateEnd)
           calendarEvent.start = buildDate(date: toBuildDateStart)
           calendarEvent.end = buildDate(date: toBuildDateEnd)
           
           let insertQuery = GTLRCalendarQuery_EventsInsert.query(withObject: calendarEvent, calendarId: "primary")
           print("about to execute query")
           print("print calendar event: \(calendarEvent)")
           service.executeQuery(insertQuery) { (ticket, object, error) in
               if error == nil {
                   print("Event inserted")
                   self.item.dueDateTime = tempString
               } else {
                   print(error)
               }
           }
       }
       
       
       func buildDate(date: Date) -> GTLRCalendar_EventDateTime {
           let datetime = GTLRDateTime(date: date)
           let dateObject = GTLRCalendar_EventDateTime()
           dateObject.dateTime = datetime
           return dateObject
       }
    
     func preparePlayer() {
         var error: NSError?
         do {
             print("print recorded Audio URL in preparePlayer: \(String(describing: recordedAudioURL))")
             audioPlayer = try AVAudioPlayer(contentsOf: recordedAudioURL as URL)
         } catch let error1 as NSError {
             error = error1
             audioPlayer = nil
         }
         
         if let err = error {
             print("AVAudioPlayer error: \(err.localizedDescription)")
         } else {
             audioPlayer.delegate = self
             audioPlayer.prepareToPlay()
             audioPlayer.volume = 10.0
         }
     }
     
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        print("finished recording")
        if flag
        {
            print("recording successful\(audioRecorder.url)")
            playButton.isEnabled = true
            playButton.alpha = 1
            playButton.tintColor = UIColor.systemYellow
        }
        else
        {
            print("recording not successful\(audioRecorder.url)")
             }
        
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
                print("record button was pressed")
                recordedAudioURL = nil
                recordingLabel.text = "Recording"
                recordButton.tintColor = UIColor.red
                recordButton.isEnabled = false
                stopButton.isEnabled = true
                stopButton.alpha = 1
                playButton.isEnabled = false
                playButton.alpha = 0
                
                
                let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
                print(dirPath)
        //      let dirPath = "/Users/benng/Desktop/iOS%20Development/Projects/ToDoo/recording"
                let ownerEmail = item.owner.replacingOccurrences(of: ".", with: "dot")
                let localStorageFileName = ownerEmail + ".wav"
                let pathArray = [dirPath, localStorageFileName]
                print(pathArray)
                let filePath = URL(string: pathArray.joined(separator: "/"))
                print(filePath!)
                print("recordAudio, printing filePath of recordedVoice :\(String(describing: filePath))" )
                let session = AVAudioSession.sharedInstance()
                try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
                try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
               
                
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
                audioRecorder.record()
                print("audioRecorder.record called, recording truly in progress")
    }
    
    @IBAction func stopButtonPressed(_ sender: UIButton) {
        recordButton.isEnabled = true
        recordButton.tintColor = UIColor(named: K.BrandColors.blue)
        stopButton.isEnabled = false
        recordingLabel.text = "Tap to Record"
        
        recordedAudioURL = audioRecorder.url
        print("audio recorded at: \(String(describing: recordedAudioURL))")
        audioRecorder.stop()
        recordingDidHappen = true
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
              print("play sound called")
              print("did recording happen? \(recordingDidHappen)")
              print("RecordingStorageRef: \(self.item.recordingStorageRef)")
              if recordingDidHappen == false {
                  if self.item.recordingStorageRef != nil
                  {
                 print("Downloading")
                            //self.downloadAudioRecording()
                    recordedAudioURL = item.recordingStorageRef
                            self.preparePlayer()
                            print("audio player prepared")
                            self.audioPlayer.play()
                  } else {
                      print("recording didn't happen and recordingStorageRef == none, something is wrong, there is nothing to play")
                  }
              } else {
                self.preparePlayer()
                print("audio player prepared")
                self.audioPlayer.play()
              }

        }
    
     func downloadAudioRecording () {
            var filePath: URL?
            
            let storageRef = storage.reference()

            
            let storageFilePath = "recording/recordedVoice11.wav"
            print("downloadAudioRecording: printing storageFilePath: \(storageFilePath)")
            let audioRecordingStorageRef = storageRef.child(storageFilePath)
            print("downloadAudioRecording: printing storageRecordingStorageRef: \(audioRecordingStorageRef)")
            
            print(Auth.auth().currentUser?.email! as Any)
  
            let downloadFileName = "downloadedAudio.wav"
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            filePath = documentsURL.appendingPathComponent(downloadFileName)
            
            print("downloadAudioRecording, printing filePath: \(String(describing: filePath))")

            print(filePath ?? "default file path")
            
            
            print("downloadAudioRecording, printing file path before writing: \(String(describing: filePath))")
            
                    let downloadTask = audioRecordingStorageRef.write(toFile: filePath!) { url, error in
                        if error != nil {
                            print("error in writing file\(error)")
                            return//
                        } else {
                            print("print download URL: \(url)")
                            print("write file should be successful")
                            print(filePath ?? "default file path")
                            self.recordedAudioURL = filePath
                        }
                    }
            
        }
    
    func uploadAudioRecording () -> String {
        
        let storageRef = storage.reference()
        print(storageRef)
        let ownerEmail = item.owner.replacingOccurrences(of: ".", with: "dot")
        let storageFilePath = "recording/recordedVoice11.wav"
        print("uploadAudioRecording, print storageFilePath before uploading: \(storageFilePath)")
        let recordingStorageRef = storageRef.child(storageFilePath)
        print(recordingStorageRef)
        print("uploadAudioRecording, print storageFilePath before uploading: \(recordingStorageRef)")
        
        let recordedAudioURLString = recordedAudioURL.absoluteString
        print(recordedAudioURLString)
        let recordedAudioURIString = "file://localhost" + recordedAudioURLString
        print(recordedAudioURIString)
        recordedAudioURL = NSURL(string: recordedAudioURIString) as URL?
        print(recordedAudioURL!)
        let uploadTask = recordingStorageRef.putFile(from: recordedAudioURL, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                print("error occurred in uploading file: \(String(describing: error))")
                return
            }
            
        }
        print("upload seems successful to: \(storageFilePath)")
        print("print storage file path before returning to caller: \(storageFilePath)")
        return storageFilePath
    }
    
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        if recordingDidHappen {
            var recordingStorageRef = uploadAudioRecording()
            item.recordingStorageRef = recordedAudioURL
         }
        print (item.recordingStorageRef)
        let currentItem = db.collection(K.FStore.collectionName).document(item.id)
        currentItem.updateData([
            K.FStore.descriptionField: descriptionView.text,
            K.FStore.statusField: checked,
            K.FStore.starField: starred,
            K.FStore.dueDateTime: dateLabel.text,
            K.FStore.recordingStorageRef: item.recordingStorageRef?.absoluteString
                   ]) { err in
                       if let err = err {
                           print("Error updating document: \(err)")
                       } else {
                           print("Document successfully updated")
                       }
                   }
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        db.collection(K.FStore.collectionName).document(item.id).delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func checkBoxPressed(_ sender: Any) {
        if checked {
            checked = false
        }
        else {
            checked = true
        }
    }
    
    
    @IBAction func starPressed(_ sender: Any) {
        if starred {
            starred = false
        }
        else {
            starred = true
        }
    }
    
    @IBAction func calendarButtonPressed(_ sender: UIButton) {
        GIDSignIn.sharedInstance()?.signIn()
    }
 
    
    @IBAction func datePickerChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.short
        let selectedDate = dateFormatter.string(from: datePicker.date)
        dateLabel.text = selectedDate
    }
    
    
    @IBAction func okButtonPressed(_ sender: UIButton) {
        datePicker.alpha = 0
        okButton.alpha = 0
        datePicker.alpha = 0
        dateView.alpha = 0
        addEventoToGoogleCalendar(summary : item.description, description :"", startTime : dateLabel.text!, endTime : dateLabel.text!)
    }
    
    
    
}
