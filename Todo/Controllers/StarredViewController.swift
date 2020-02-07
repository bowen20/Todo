import UIKit
import Firebase

class StarredViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()
    var items: [Item] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        title = "Starred"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        loadItems()
    }
    
    func loadItems() {
        
        db.collection(K.FStore.collectionName)
            .whereField(K.FStore.ownerField, isEqualTo: Auth.auth().currentUser?.email as Any)
            .whereField(K.FStore.starField, isEqualTo: true)
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
                            let itemRecordingStoragerRefURL = URL(string: itemRecordingStorageRef)
                            let newItem = Item(id: itemID, description: itemDescription, status: itemStatus, star: itemStar, owner: itemOwner, listName: itemListName, dueDateTime: dueDateTime, recordingStorageRef: itemRecordingStoragerRefURL)
                            self.items.append(newItem)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()

                                let indexPath = IndexPath(row: self.items.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    

}

extension StarredViewController: UITableViewDataSource {
    
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
        cell.cellDelegate = self
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

extension StarredViewController: UITableViewDelegate {
    
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


extension StarredViewController: ItemCellDelegate {
    
    func pressedStar()
        {
            self.loadItems()
            self.tableView.reloadData()
    }
    
    func pressedDone()
        {
            self.loadItems()
            self.tableView.reloadData()
    }
   
}
