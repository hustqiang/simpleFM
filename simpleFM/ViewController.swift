//
//  ViewController.swift
//  simpleFM
//
//  Created by zhangqiang on 15/10/15.
//  Copyright © 2015年 qiang. All rights reserved.
//

import UIKit
import Alamofire
import MediaPlayer

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,HttpProtocol,UIPickerViewDelegate{
    
    @IBOutlet weak var iv: EkoImage!
    
    @IBOutlet weak var bg: UIImageView!
    
    @IBOutlet weak var tv: UITableView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var channelPicker: UIPickerView!
    
    var play:Bool = true
    
    var eHttp:HTTPController = HTTPController()
    
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    
    var isAutoFinish:Bool = true
    var currentIndex:Int = 0
    
    var songData:[JSON] = []
    var channelData:[JSON] = []
    var imageCache = Dictionary<String,UIImage>()
    
    let playImg = UIImage(named: "play.png")
    let pauseImg = UIImage(named: "pause.png")
    
    var channelTitle = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        iv.onRotation()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width,height: view.frame.height)
        bg.addSubview(blurView)
        
        tv.dataSource = self
        tv.delegate = self
        
        channelPicker.delegate = self
        
        eHttp.delegate = self
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        
        eHttp.onSearch("http://douban.fm/j/mine/playlist?type=n&channel=1&from=mainsite")
        
        tv.backgroundColor = UIColor.clearColor()
        self.channelPicker.reloadAllComponents()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "play", name: MPMoviePlayerPlaybackDidFinishNotification, object: audioPlayer)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let rowData:JSON = songData[indexPath.row]
        let cell = tv.dequeueReusableCellWithIdentifier("douban") as UITableViewCell!
        cell.backgroundColor = UIColor.clearColor()
        cell.textLabel!.text = rowData["title"].string
        cell.detailTextLabel!.text = rowData["artist"].string
        cell.imageView?.image = UIImage(named: "thumb")
        let url = rowData["picture"].string
        onGetCacheImage(url!, imgView: cell.imageView!)
        return cell
    }
    
    @IBAction func clickToPlayOrPause(sender: AnyObject) {
        if play {
            playButton.setImage(playImg, forState: UIControlState.Normal)
        }else{
            playButton.setImage(pauseImg, forState: UIControlState.Normal)
        }
        play = !play
        playOrPause(self.play)
        self.channelPicker.reloadAllComponents()
    }
    
    func playOrPause(play:Bool){
        if play {
            self.audioPlayer.play()
            self.iv.onRotation()
        }else{
            self.audioPlayer.pause()
            self.iv.stopAnimating()
        }
    }
    
    func onSetAudio(url:String){
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        isAutoFinish = true
    }
    
    func didRecieveResults(results:AnyObject){
        //print(results)
        var json = JSON(results)
        if let song = json["song"].array{
            self.songData = song
            self.tv.reloadData()
            onSelectRow(0)
        } else if let channel = json["channels"].array{
            self.channelData = channel
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        onSelectRow(indexPath.row)
        isAutoFinish = false
    }
    
    func onSelectRow(index:Int){
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tv.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Top)
        let rowData:JSON = songData[index] as JSON
        let picture:String = rowData["picture"].string!
        onSetImage(picture)
        let musicData:String = rowData["url"].string!
        onSetAudio(musicData)
    }
    
    func onSetImage(url:String){
        Alamofire.request(.GET, url).response{(_,_,data,error) -> Void in
            let image = UIImage(data: data! )
            self.iv.image = image
            self.bg.image = image
            self.iv.onRotation()
        }
    }
    
    func onGetCacheImage(url:String,imgView:UIImageView){
        let img = self.imageCache[url] as UIImage?
        if img == nil {
            Alamofire.request(.GET, url).response{(_,_,data,error) -> Void in
                let image = UIImage(data: data!)
                self.imageCache[url] = image
                imgView.image = image
            }
        } else {
            imgView.image = img!
            print("cell的图片沿用之前的缓存图片")
        }
    }
    
    func pickerView(pickerView:UIPickerView!, numberOfRowsInComponent component:Int) -> Int{
        return channelData.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView!)-> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let rowData:JSON = self.channelData[row] as JSON
        let title = rowData["name"].string
        return title
        
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let rowData:JSON = self.channelData[row] as JSON
        let channel_id:String = rowData["channel_id"].stringValue
        let url:String = "http://douban.fm/j/mine/playlist?type=n&channel=\(channel_id)&from=mainsite"
        eHttp.onSearch(url)
        play = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}














