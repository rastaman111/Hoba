import UIKit
import SDWebImage
import SwiftyJSON

final class RoomsListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var tryAgain: UIButton!
    
    var parentVC: SelectRoomVC?
    var jsonData: [JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tryAgain.isHidden = true
    }
    
    func updateData(json: [JSON]) {
        jsonData = json
        tryAgain.isHidden = jsonData.count != 0
        tableView.reloadData()
    }
    
    @IBAction func tryToReload(_ sender: Any) {
        parentVC?.loadData()
    }
    
    /// Table funcs
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.tableView.alpha = jsonData.count == 0 ? 0 : 1
        return jsonData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomItem", for: indexPath as IndexPath) as! RoomItem
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(argb: 0xff383536)
        cell.selectedBackgroundView = bgColorView
        
        cell.roomItem.text = jsonData[indexPath.row]["address"].stringValue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: false)
        self.parentVC?.loadSchedule(id: App.this.reservedRoomId)
    }
}

class RoomItem: UITableViewCell {
    @IBOutlet weak var roomItem: UILabel!
}
