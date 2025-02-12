//
//  ViewController.swift
//  projectUI
//
//  Created by Sarah Sherman on 1/26/16.
//  Copyright © 2016 Sarah Sherman. All rights reserved.
//


// master file

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, CancelButtonDelegate, DoneButtonDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    var locationManager: CLLocationManager!
    var location: CLLocation?
    
    
    var tableIsFoundItems = true
    var searchActive : Bool = false
    

    var items = [Item]()
    
    var tableItems = [Item]()
    
    var tempTable = [Item]()
    
  
    
    var selected_idx = 0
    

    var currentLocation: CLLocation?
    
    var defaultImage = "noImageFound.png"
    

    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchOutlet: UISearchBar!
    
    @IBAction func foundButtonPressed(sender: UIButton) {
//        print("heeeerrreee")
        if tableIsFoundItems == false {
            tableItems = []
            for var i = 0; i < items.count; ++i {

                if items[i].founds.count  != 0 {
                    tableItems.append(items[i])
                }
            }
            tableView.reloadData()
        }
        tableIsFoundItems = true
        
    }
    
    @IBAction func notFoundButtonPressed(sender: UIButton) {
        if tableIsFoundItems == true {
            tableItems = []
            for var i = 0; i < items.count; ++i {

                if items[i].founds.count  == 0 {

                    tableItems.append(items[i])
                }
            }
            tableView.reloadData()
        }
        tableIsFoundItems = false
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
               dispatch_async(dispatch_get_main_queue(), {
            self.httpGetRequest()
        })
        

        tableView.dataSource = self
        tableView.delegate = self
        map.delegate = self
        searchOutlet.delegate = self
        

        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  //later change to kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        

        currentLocation = locationManager.location

        
        let location2D = CLLocationCoordinate2D(
            latitude: currentLocation!.coordinate.latitude,
            longitude: currentLocation!.coordinate.longitude
        )
        let span = MKCoordinateSpanMake(0.05, 0.05)
        
        
        let region = MKCoordinateRegion(center: location2D, span: span)
        
        map.setRegion(region, animated: true)
        let annotation = Pin(coordinate: location2D)
        annotation.title = "User"
        annotation.type = "User"
        map.addAnnotation(annotation)
        
        
        
        mapView(map, viewForAnnotation: annotation)
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Pin {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
                view.pinTintColor = annotation.pinColor()
//                print(view.pinTintColor)
            }
            return view
        }
        return nil
    }
    
    // location stuffs
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations[locations.count-1] as CLLocation
       
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
        
    }
  

    func loadImage(imageUrl: String) -> UIImage{
        let imgUrl = hInfo + imageUrl
       
        let urlStr: NSString = imgUrl.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let pictureURL = NSURL(string: urlStr as String)
        
        if let imageData = NSData(contentsOfURL: pictureURL!){
            return UIImage(data: imageData)!
        }
        return UIImage(named: defaultImage)!
        
    }

    
    //table view stuffs
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell")! as! ItemCell
        let item = tableItems[indexPath.row]

        dispatch_async(dispatch_get_main_queue(), {
            cell.itemImage.image = self.loadImage(item.imageUrl)
        })
        cell.zipCodeLabel.text = item.location
        cell.detailsLabel.text = item.itemName
        // ******* ?????? have to chaange date format
        cell.dateListedLabel.text = String(item.createdAt)
        cell.numberFoundLabel.text = String(item.founds.count)

        return cell
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems.count
    }
    
    
    //segue
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        selected_idx = indexPath.row
        print("performSegue: ", selected_idx)
        performSegueWithIdentifier("DetailsSegue", sender: tableView.cellForRowAtIndexPath(indexPath))
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddItem" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! AddItemViewController
            controller.cancelButtonDelegate = self
            
            controller.doneButtonDelegate = self
            controller.myLocationX = (currentLocation?.coordinate.longitude)!
            controller.myLocationY = (currentLocation?.coordinate.latitude)!
        }
        
        if segue.identifier == "DetailsSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! ItemDetailsViewController
            controller.cancelButtonDelegate = self
            controller.doneButtonDelegate = self
            
            controller.iid = tableItems[selected_idx].iid
            controller.found = tableItems[selected_idx].founds
            controller.item = tableItems[selected_idx]
            print("prepare segue: \(controller.item)")
            controller.myLocationX = (currentLocation?.coordinate.longitude)!
            controller.myLocationY = (currentLocation?.coordinate.latitude)!
        }
        
    }

    
    // navigation functions
    func cancelButtonPressedFrom(controller: UIViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    

    func doneButtonPressedFrom(controller: UIViewController){
        
            httpGetRequest()
        
        print("doneButton in Main: >>>>>>>>>>>")
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        removeAnnotations()
        foundA = []
        let length = tableItems[indexPath.row].founds.count
//        addItemAnnotation(items[indexPath.row])
        for var i = 0; i < tableItems[indexPath.row].founds.count; ++i {
            
            let curr_X = tableItems[indexPath.row].founds[i]["locationX"] as! Double
            let curr_Y = tableItems[indexPath.row].founds[i]["locationY"] as! Double
            let storeName = tableItems[indexPath.row].founds[i]["storeName"] as! String
            let randX = Double(arc4random_uniform(UInt32(length)) + 2) * 0.01
            let randY = Double(arc4random_uniform(UInt32(length)) + 2) * 0.01
            addFoundAnnotation(curr_X+randX, y: curr_Y+randY, title: storeName)

        }
        self.map.addAnnotations(foundA)
        
        
        
    }
    
    var foundA = [MKPointAnnotation]()
    
    func addFoundAnnotation(x: Double, y: Double, title: String) {
        print("X, Y in addFooun", x, y)
        let foundAnnotation = MKPointAnnotation()
        let foundLocation2D = CLLocationCoordinate2D(latitude: y, longitude: x)
        foundAnnotation.coordinate = foundLocation2D
        foundAnnotation.title = title
        print("added Found: ", foundAnnotation.coordinate.latitude)
        print("added Found: ", foundAnnotation.title)
        foundA.append(foundAnnotation)
//        self.map.addAnnotation(foundAnnotation)
//        self.map.selectAnnotation(foundAnnotation, animated: true)
    }
    
    func addItemAnnotation(item: Item){
        let itemAnnotation = MKPointAnnotation()

        let itemLocation2D = CLLocationCoordinate2D(latitude: item.locationY, longitude: item.locationX)
        itemAnnotation.coordinate = itemLocation2D
        itemAnnotation.title = item.itemName

        self.map.addAnnotation(itemAnnotation)
        self.map.selectAnnotation(itemAnnotation,animated:true)
        
    }
    
    func removeAnnotations() {
        var annotationsToRemove = [MKAnnotation]()
        for var i = 0; i < map.annotations.count; ++i {
            if map.annotations[i].title! != "User" {
                annotationsToRemove.append(map.annotations[i])
            }
        }
        map.removeAnnotations(annotationsToRemove)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    //search functions
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        print(tableItems)
        
        tempTable = tableItems
//        print(tempTable)
        tableItems = []
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        print("hi")
        searchOutlet.text! = ""
        dismissKeyboard()
        tableItems = tempTable
        self.tableView.reloadData()
        searchActive = false;
    }
    
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        print("here")
        tableItems = items.filter({ (Item) -> Bool in

            let tmp: NSString = NSString(string: Item.itemName)

            let range = tmp.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        
        
        if(tableItems.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }

    func httpGetRequest(){
        items = []
        
          if let urlToReq = NSURL(string: hInfo+"items"){//Home
            
            if let packagedData = NSData(contentsOfURL: urlToReq){
                if let unpackagedData = parseJSON(packagedData){
                    //                    print("@@@ data from server: ", unpackagedData)
                    for newItem in unpackagedData {
//                        let item = data as! Item
                        let iid = newItem["_id"] as! String
                        let userName = newItem["userName"] as! String
                        let location = newItem["location"] as! String
                        let itemName = newItem["itemName"] as! String
                        let detail = newItem["detail"] as! String
                        let locationX = newItem["locationX"] as! Double
                        let locationY = newItem["locationY"] as! Double
                        let imageUrl = newItem["imageUrl"] as! String
                        let createdDate = newItem["createdAt"] as! String
                        //change Date
                        let df = NSDateFormatter()
                        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//                        print("createdDate: ", createdDate)
                        
                        let createdAtShort = df.dateFromString(createdDate)
                        df.dateFormat = "EEE MMM d"
                        let createdAt = df.stringFromDate(createdAtShort!)
                        
                        let item = Item(iid: iid, userName: userName, itemName: itemName, locationX: locationX, locationY: locationY, details: detail, dateListed: createdAt, imageUrl: imageUrl, location: location)
                        
                        self.items.append(item)
                        
//                        print("\(iid), \(itemName), \(imageUrl)")
                        
                        if newItem["founds"] != nil {
                            let newFounds = newItem["founds"] as! NSArray
                            if newFounds.count != 0 {
                                
                                for fItem in newFounds {
                                    
                                    item.founds.append(fItem as! NSDictionary)
                                }
                            }
                        }
                    }
                    updateTable()
                }else{
                    print("Error unpackaging data")
                }
            }else{
                print("Error requesting data")
            }
        }else{
            print("Error creating NSURL")
        }
    }
    
    func updateTable(){
        tableItems = []
        print("Update Table after http request")
        if tableIsFoundItems == false {

            for var i = 0; i < items.count; ++i {
                if items[i].founds.count  == 0 {
                    tableItems.append(items[i])
                }
            }

            tableIsFoundItems = false
        }else{
            for var i = 0; i < items.count; ++i {
                if items[i].founds.count  != 0 {
                    tableItems.append(items[i])
                }
            }
            
            tableIsFoundItems = true
        }
        tableView.reloadData()

    }
    
    func parseJSON(inputData: NSData) -> NSArray? {
        var error: NSError?
        var arrOfObjects: NSArray?
        
        do {
            arrOfObjects = try NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers) as? NSArray
        } catch let error as NSError {
            print("jSon error: \(error.localizedDescription)")
        }
        return arrOfObjects!
    }




}

