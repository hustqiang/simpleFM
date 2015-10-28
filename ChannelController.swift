import UIKit

protocol channelProtocol {
    func onChangeChannel(channel_id:String)
    }

class ChannelController: UIViewController,UITableViewDelegate {
    
    var channelData:[JSON] = []
    
    var delegate:channelProtocol?
    
    @IBOutlet weak var ct: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowData:JSON = self.channelData[indexPath.row] as JSON
        let cell = ct.dequeueReusableCellWithIdentifier("channel") as UITableViewCell!
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel!.text = rowData["name"].string
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let rowData:JSON = self.channelData[indexPath.row] as JSON
        let channel_id:String = rowData["channel_id"].stringValue
        delegate?.onChangeChannel(channel_id)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



