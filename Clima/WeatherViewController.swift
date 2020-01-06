//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Modified by Tony Xu on 03/26/2018.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "9def5a84f246eddf19f474ac181d71f1"

    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    var locationUpdatesAreAvailable = false


    //Pre-linked IBOutlets
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!

    private var refreshControll: UIRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        addObservers()
    }

    @objc private func didPullToRefresh(sender: Any) {
        locationManager.requestLocation()
    }
    
    func getWeatherData(url: String, parameters: [String: String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON { (response) in
            if let json = response.result.value {
                self.updateWeatherData(json: JSON(json))
            } else {
                self.cityLabel.text = "Network Error"
            }
        }
    }
    
    func updateWeatherData(json : JSON) {
        if let tempResult = json["main"]["temp"].double {
            weatherDataModel.temperature = Int(tempResult - 273.15)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            
            updateUIWithWeatherData()
        } else {
            cityLabel.text = "Unavailable"
        }
    }
    
    func updateUIWithWeatherData() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(weatherDataModel.temperature)"
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
}

extension WeatherViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let grantedStatuses: [CLAuthorizationStatus] = [
            .authorizedAlways,
            .authorizedWhenInUse,
        ]
        if grantedStatuses.contains(status) {
            locationUpdatesAreAvailable = true
            locationManager.startUpdatingLocation()
            
            scroll.addSubview(refreshControll)
            refreshControll.addTarget(
                self,
                action: #selector(didPullToRefresh(sender:)),
                for: .valueChanged)
        } else {
            cityLabel.text = "Location Unavailable"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        debugPrint("Location updated!")
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            let params : [String : String] = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location Unavailable"
    }
}

@objc extension WeatherViewController {
    @nonobjc func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }
    
    func appDidEnterBackground() {
        if locationUpdatesAreAvailable {
            locationManager.stopUpdatingLocation()
        }
        debugPrint("App moved to background!")
    }
    
    func appWillEnterForeground() {
        if locationUpdatesAreAvailable {
            locationManager.startUpdatingLocation()
        }
        debugPrint("App moved to foreground!")
    }
}
