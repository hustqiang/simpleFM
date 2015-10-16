import UIKit
import Alamofire
class HTTPController:NSObject{
    //定义一个代理
    var delegate:HttpProtocol?
    //接收网址，回调代理的方法传回数据
    func onSearch(url:String){
        Alamofire.request(.GET, url).responseJSON {response in
            self.delegate?.didRecieveResults(response.result.value!)
        }
    }
}
//定义http协议
protocol HttpProtocol {
    //定义一个方法，接收一个参数：AnyObject
    func didRecieveResults(results:AnyObject)
}