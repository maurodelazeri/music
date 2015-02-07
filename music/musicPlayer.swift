//
//  multiMedia.swift
//  ThumbsOnTheRun
//
//  Created by 丁松 on 14-9-9.
//  Copyright (c) 2014年 丁松. All rights reserved.

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class musicPlayer: UIViewController, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource {
    var player:AVAudioPlayer!
    //private var fileName = "xiaopingguo.mp3"
    var filePath = "/Users/Soung/Desktop/"
    var musicUrl:NSURL!
    var timer:NSTimer!
    var doubanChannel = doubanFM()
    
    var playListJSON:JSON = nil
    
    @IBOutlet weak var nowPlaying: UILabel!
    @IBOutlet weak var modeButtom: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var progressLabel: UILabel!
    
    @IBOutlet weak var playList: UITableView!
    @IBOutlet weak var coverImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //doubanChannel.delegate = self
        //getPlayList("1")
        self.getChannelList()
        nowPlaying.text = "musicPlayer"
    }
    override func viewWillAppear(animated: Bool) {
        playList.reloadData()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func doubanPlayList(playList: JSON) {
        playListJSON = playList
        self.playList.reloadData()
    }
    
    
    //player func
    func startPlayer(url:String) {
        var errMsg = NSErrorPointer()
        player = AVAudioPlayer(contentsOfURL: NSURL(string: url), error: errMsg)
        //player.numberOfLoops = 1 //-1 循环
        player.volume = 0.5 // vplume 0~1
        player.prepareToPlay()
        player.delegate = self
        
        playButton.setTitle("Play", forState: UIControlState.Normal)
        progressSlider.maximumValue = CFloat(player.duration)
        progressSlider.minimumValue = 0.0
        progressSlider.value = 0.0
        
        togglePlayer()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateStatus:"), userInfo: nil,repeats: true)
    }
    func togglePlayer() {
        if(player == nil) {
            return
        }
        if(player.playing){
            playButton.setTitle("Play", forState: UIControlState.Normal)
            player.pause()
        } else {
            playButton.setTitle("Pause", forState:UIControlState.Normal)            //voiceButton.setImage(UIImage(named:"voicebutton@3x.png"),forState:.Normal)
            player.play()
        }
    }
    func stopPlayer(){
        if(player == nil) {
            return
        }
        playButton.setTitle("Play", forState: UIControlState.Normal)
        player.stop()
        timer.invalidate()
    }
    func updateStatus(timer: NSTimer){
        if(player == nil) {
            return
        }
        if(!player.playing) {
            return
        }
        var hour_   = abs(Int(player.currentTime)/3600)
        var minute_ = abs(Int((player.currentTime/60) % 60))
        var second_ = abs(Int(player.currentTime  % 60))
        var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        var minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        var second = second_ > 9 ? "\(second_)" : "0\(second_)"
        progressLabel.text  = "\(hour):\(minute):\(second)"
        progressSlider.value = CFloat(player.currentTime)
    }
    
    
    
    //player control
    @IBAction func playMode(sender: AnyObject) {
        if(player == nil) {
            return
        }
        if(player.numberOfLoops == 1){
            player.numberOfLoops = -1
            modeButtom.setTitle("Loop", forState: UIControlState.Normal)
        } else {
            player.numberOfLoops = 1
            modeButtom.setTitle("Signal", forState: UIControlState.Normal)
        }
    }
    @IBAction func playButton(sender: UIButton) {
        togglePlayer()
    }
    @IBAction func stopPlayer(sender: AnyObject) {
        stopPlayer()
    }
    @IBAction func progressSlider(sender: UISlider) {
        player.currentTime = NSTimeInterval(sender.value) // * player.duration
    }
    
    @IBAction func reset2ChannelList(sender: AnyObject) {
        self.getChannelList()
    }
    
    
    
    
    
    
    //on line resource
    func getChannelList(){
        if(self.playListJSON["channels"].count == 0){
            var doubanChannelUrl = "http://www.douban.com/j/app/radio/channels"
            Alamofire.request(.GET, doubanChannelUrl).responseJSON {
                (request, response, data, error) -> Void in
                if(data == nil){
                    println(error)
                    return
                }
                self.playListJSON = JSON(data!)
                //刷新
                self.playList.reloadData()
            }
        }
    }
    func getPlayList(channel_id:String){
        var listUrl = "http://douban.fm/j/mine/playlist?channel=" + channel_id
        Alamofire.request(.GET, listUrl).responseJSON {
            (request, response, data, error) -> Void in
            if(data == nil){
                println(error)
                return
            }
            self.playListJSON = JSON(data!)
            self.playList.reloadData()
        }
    }
    func playOnlineMusic(url:String){
        if (url.hasPrefix("http") == true) {
            downloadData(url, dataHandler: {
                (data:NSData) -> Void in
                var musicUrl = self.filePath + "test" + ".mp3"
                data.writeToFile(musicUrl, atomically: true)
                self.startPlayer(musicUrl)
            })
        }

    }
    
    func downloadData(url: String, dataHandler:(NSData) -> Void){
        var request = NSURLRequest(URL: NSURL(string: url)!)  //請求的內容
        //異步請求,//操作隊列
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
            (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var httpResponse = response as NSHTTPURLResponse
            if(httpResponse.statusCode == 200){
                dataHandler(data)
            }
            else {
                println(httpResponse)
            }
        })
    }
    
    
    
    //display playlist
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.playListJSON["channels"].count > 0){
            return self.playListJSON["channels"].count
        }else{
            return self.playListJSON["song"].count
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifer = "playListCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifer) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifer)
            cell?.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        }
        if (self.playListJSON["channels"].count > 0){
            cell?.textLabel?.text = self.playListJSON["channels"][indexPath.row]["name"].string
            cell?.detailTextLabel?.text = self.playListJSON["channels"][indexPath.row]["name_en"].string
        }else{
            cell?.textLabel?.text = self.playListJSON["song"][indexPath.row]["title"].string
            cell?.detailTextLabel?.text = self.playListJSON["song"][indexPath.row]["albumtitle"].string

        }
        return cell!
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.playListJSON["channels"].count > 0){
            self.getPlayList(self.playListJSON["channels"][indexPath.row]["channel_id"].string!)
        }else{
            self.playOnlineMusic(playListJSON["song"][indexPath.row]["url"].string!)
        }
    }
}





