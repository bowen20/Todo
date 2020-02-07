import UIKit
import Firebase

class ListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var itemField: UITextField!
    
    @IBOutlet weak var starTab: UIButton!
    @IBOutlet weak var checkTab: UIButton!
    
     let db = Firestore.firestore()
    var nextItemNumber = 0
    var nextItemID = ""
    
    var items: [Item] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadItems()
        
    }
    
    func loadItems() {
        
        db.collection(K.FStore.collectionName)
            .whereField(K.FStore.ownerField, isEqualTo: Auth.auth().currentUser?.email as Any)
            .whereField(K.FStore.statusField, isEqualTo: false)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapshot, error) in
            
            self.items = []
                
            if let e = error {
                print("There was an issue retrieving data from Firestore. \(e)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        
                        let data = doc.data()
                        if let itemID = data[K.FStore.idField] as? String, let itemDescription = data[K.FStore.descriptionField] as? String, let itemStatus = data[K.FStore.statusField] as? Bool, let itemStar = data[K.FStore.starField] as? Bool, let itemOwner = data[K.FStore.ownerField] as? String, let itemListName = data[K.FStore.listNameField] as? String, let dueDateTime = data[K.FStore.dueDateTime] as? String, let itemRecordingStorageRef = data[K.FStore.recordingStorageRef] as? String {
 
                            self.nextItemNumber = self.getItemNumber(itemID: itemID)
                            let itemRecordingStorageRefURL = URL(string: itemRecordingStorageRef)
                            let newItem = Item(id: itemID, description: itemDescription, status: itemStatus, star: itemStar, owner: itemOwner, listName: itemListName, dueDateTime: dueDateTime, recordingStorageRef: itemRecordingStorageRefURL)
                            print(itemRecordingStorageRefURL)
                            self.items.append(newItem)
                            DispatchQueue.main.async {
                                   //self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.items.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }

            }
            self.tableView.reloadData()
        }
    }
    
    
    func getItemID (itemNbr: Int) -> String {
        return (Auth.auth().currentUser?.email)! + "@" + String(itemNbr)
    }
    
    
    
    func getItemNumber (itemID: String) -> Int {
        
        var atSignPosition: String.Index
        
        // scanning the documentID string from the right to get the numeric portion following the second "@" sign
        print("ItemID: \(itemID)")
        atSignPosition = itemID.firstIndex(of: "@")!
        let tempSubstring = String(itemID[itemID.index(after: atSignPosition)..<itemID.endIndex])
        atSignPosition = tempSubstring.firstIndex(of: "@")!
        let finalSubstring = String(tempSubstring[tempSubstring.index(after: atSignPosition)..<tempSubstring.endIndex])
        print(finalSubstring)
        return Int(finalSubstring)!
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        nextItemNumber = nextItemNumber + 1
        print("create button pressed: \(nextItemNumber)")
        nextItemID = getItemID(itemNbr: nextItemNumber)
        print(nextItemID)
        if let description = itemField.text {
            db.collection(K.FStore.collectionName).document(nextItemID).setData([
                K.FStore.idField: nextItemID,
                K.FStore.descriptionField: description,
                K.FStore.statusField: false,
                K.FStore.dateField: Date().timeIntervalSince1970,
                K.FStore.starField: false,
                K.FStore.ownerField: Auth.auth().currentUser?.email as Any,
                K.FStore.listNameField: Auth.auth().currentUser?.email as Any,
                K.FStore.dueDateTime: "",
                K.FStore.recordingStorageRef: "todo.com"
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")
                    
                    DispatchQueue.main.async {
                         self.itemField.text = ""
                    }
                }
                
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
          print ("Error signing out: %@", signOutError)
        }
    }
    
    
    @IBAction func starTabPressed(_ sender: UIButton) {
        let starredVC = storyboard?.instantiateViewController(withIdentifier: "StarredViewController") as! StarredViewController
        starredVC.hidesBottomBarWhenPushed = true
        navigationController?.view.backgroundColor = .white
        navigationController?.pushViewController(starredVC, animated: true)
    }
    
    
    @IBAction func checkTabPressed(_ sender: UIButton) {
        let completedVC = storyboard?.instantiateViewController(withIdentifier: "CompletedViewController") as! CompletedViewController
        completedVC.hidesBottomBarWhenPushed = true
        navigationController?.view.backgroundColor = .white
        navigationController?.pushViewController(completedVC, animated: true)
    }
}
extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! ItemCell
        cell.descriptionLabel.text = item.description
        cell.bubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
        cell.descriptionLabel.textColor = UIColor(named: K.BrandColors.purple)
        cell.db = db
        cell.itemID = item.id
        if item.status {
            cell.checked = true
        } else {
            cell.checked = false
        }
        if item.star {
            cell.starred = true
        } else {
            cell.starred = false
        }
        cell.isUserInteractionEnabled = true;
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        let item = items[indexPath.row]
        detailVC.item = item
        detailVC.db = db
        detailVC.hidesBottomBarWhenPushed = true
        navigationController?.view.backgroundColor = .white
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

