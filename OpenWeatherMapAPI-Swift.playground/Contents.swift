//:## Open Weather Map API in Swift using Codable

//
//  Created by Dan Korkelia on 25/07/2018.
//  Copyright © 2018 Dan Korkelia. All rights reserved.
//

import Foundation

//MARK: - Namespacing for API
struct API {
    //: [Get your API Key here](https://openweathermap.org/api "Open Weather Map API")
    static let key = URLQueryItem(name: "APPID", value: .apiKey)
    
    //MARK: URL EndPoints
    static var baseURL = URLComponents(string: .url)
    static let searchString = URLQueryItem(name: .query, value: .location)
    
    //Basic Weather URL
    static func locationForecast() -> URL?  {
        API.baseURL?.queryItems?.append(API.searchString)
        API.baseURL?.queryItems?.append(API.key)
        return API.baseURL?.url
    }
}


extension String {
    static let apiKey = ""
    static let url = "https://api.openweathermap.org/data/2.5/weather?"
    static let query = "q"
    static let location = "London,uk"
}


//Utility extension to help with certain data types and calculations
extension CurrentWeatherData {
    var timeOfDataCalculation: Date {
        return Date(timeIntervalSince1970: self.dt!)
    }
}

extension CurrentWeatherData.Main {
    //Calculate Celcius and Fahrenheit Values
    func getFahrenheit(valueInKelvin: Double?) -> Double {
        if let kelvin = valueInKelvin {
            return ((kelvin - 273.15) * 1.8) + 32
        } else {
            return 0
        }
    }
    
    func getCelsius(valueInKelvin: Double?) -> Double {
        if let kelvin = valueInKelvin {
            return kelvin - 273.15
        } else {
            return 0
        }
    }
    
    var minTempFahrenheit: Double {
        return getFahrenheit(valueInKelvin: self.minTempKelvin)
    }
    var minTempCelcius: Double {
        return getCelsius(valueInKelvin: self.minTempKelvin)
    }
    var maxTempFahrenheit: Double {
        return getFahrenheit(valueInKelvin: self.maxTempKelvin)
    }
    var maxTempCelcius: Double {
        return getCelsius(valueInKelvin: self.maxTempKelvin)
    }
}

extension CurrentWeatherData.Sys {
    var sunriseTime: Date {
        return Date(timeIntervalSince1970: self.sunrise!)
    }
    
    var sunsetTime: Date {
        return Date(timeIntervalSince1970: self.sunset!)
    }
}


//Codable Struct to represent JSON payload
struct CurrentWeatherData: Decodable {
    
    let weather: [Weather]?
    let coord: Coordinates?
    let base: String? ///Internal paramenter for station information
    let main: Main?
    let visibility: Int?
    let wind: Wind?
    let clouds: Clouds?
    let dt: Double?
    let sys: Sys?
    let cityId: Int?
    let cityName: String? ///City name
    let statusCode: Int? /// cod - Internal parameter for HTTP Response
    
    struct Weather: Decodable {
        let id: Int?
        let main: String?
        let description: String?
        let icon: String?
    }
    
    struct Coordinates: Decodable {
        let lon: Double?
        let lat: Double?
    }
    
    struct Main: Decodable {
        let tempKelvin: Double? ///Temperature. Unit Default: Kelvin, Metric: Celsius, Imperial: Fahrenheit.
        var tempFahrenheit: Double {
            return getFahrenheit(valueInKelvin: self.tempKelvin)
        }
        var tempCelcius: Double {
            return getCelsius(valueInKelvin: self.tempKelvin)
        }
        let pressure: Int?
        let humidity: Int?
        let minTempKelvin: Double? /// used for large cities
        let maxTempKelvin: Double?
        
        private enum CodingKeys: String, CodingKey {
            case tempKelvin = "temp"
            case pressure
            case humidity
            case minTempKelvin = "temp_min"
            case maxTempKelvin = "temp_max"
        }
    }
    
    struct Wind: Decodable {
        let speed: Double?
        let deg: Int?
    }
    
    struct Clouds: Decodable {
        let all: Int? /// Percentage Value
    }
    
    struct Sys: Decodable {
        let type: Int?
        let id: Int?
        let message: Double?
        let country: String?
        let sunrise: Double?
        let sunset: Double?
    }
    
    private enum CodingKeys: String, CodingKey {
        case weather
        case coord
        case base
        case main
        case visibility
        case wind
        case clouds
        case dt
        case sys
        case cityId = "id"
        case cityName = "name"
        case statusCode = "cod"
    }
    
}


//Variables
var currentWeather = [CurrentWeatherData]()
var errorMessage = ""

//Networking Code
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

fileprivate func updateResults(_ data: Data) {
    currentWeather.removeAll()
    do {
        let rawFeed = try decoder.decode(CurrentWeatherData.self, from: data)
        print("Status: \(rawFeed.statusCode ?? 0)")
        currentWeather = [rawFeed]
    } catch let decodeError as NSError {
        errorMessage += "Decoder error: \(decodeError.localizedDescription)"
        print(errorMessage)
        return
    }
}

func weatherData(from url: URL, completion: @escaping () -> ()) {
    URLSession.shared.dataTask(with: url) { (data, response, error ) in
        guard let data = data else { return }
        updateResults(data)
        completion()
        }.resume()
}


weatherData(from: API.locationForecast()!) {
    DispatchQueue.main.async {
        if API.key.value == "" {
            print("Not so fast, get your API Key first")
        } else {
            currentWeather.forEach{
                print("City: \($0.cityName ?? "City not found")")
                $0.weather?.forEach{
                    print("Sky: \($0.description ?? "no info") ")
                }
                print("Temperature Celcius: \($0.main?.tempCelcius ?? 0)")
                print("Temperature Kelvin: \($0.main?.tempKelvin ?? 0 )")
                print("Temperature Fahrenheit: \($0.main?.tempFahrenheit ?? 0)")
                print("Humidity: \($0.main?.humidity  ?? 0)%")
                print("Min Temperature: \($0.main?.minTempCelcius ?? 0)")
                print("Max Temperature: \($0.main?.maxTempCelcius ?? 0)")
                print("Date of Data Refresh: \($0.timeOfDataCalculation)")
                print("Sunrise: \($0.sys?.sunriseTime ?? Date(timeIntervalSinceNow: 2018-07-26))")
                print("Sunset: \($0.sys?.sunsetTime ?? Date(timeIntervalSinceNow: 2018-07-26))")
            }
        }
    }
}
