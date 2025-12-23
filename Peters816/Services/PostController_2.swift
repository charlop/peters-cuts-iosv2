//
//  PostController.swift
//  Peters816
//
//  Created by Chris Charlopov on 10/22/16.
//  Copyright © 2016 spandan. All rights reserved.
//

import Foundation

// MARK: - PostController
class PostController2 {
    private let baseURL = URL(string: "http://peterscuts.com/lib/app_request2.php")!
    private let session = URLSession.shared
    
    // MARK: - Request Parameters
    private enum RequestParameter {
        static let closedMessage = "getClosedMessage=1"
        static let greeting = "getGreetingMessage=GREETING"
        static let hours = "getGreetingMessage=HOURS"
        static let address = "getGreetingMessage=ADDR"
        static let openSpots = "get_available=1"
    }
    
    // MARK: - Network Request Methods
    private func createRequest(with parameters: String) -> URLRequest {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        return request
    }
    
    private func handleNetworkResponse<T: Decodable>(data: Data?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            completion(.success(decodedResponse))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func handleStringResponse(data: Data?, error: Error?, completion: @escaping (Result<String, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data,
              let string = String(data: data, encoding: .utf8) else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }
        
        completion(.success(string))
    }
    
    // MARK: - Public Methods
    func getEta(userDefaults: User, completion: @escaping (Appointment) -> Void) {
        guard Reachability.isConnectedToNetwork() else {
            let errorResponse = Appointment()
            errorResponse.updateError(newError: CONSTS.ErrorNum.NO_INTERNET.rawValue)
            userDefaults.addOrUpdateAppointment(newAppointment: errorResponse)
            completion(errorResponse)
            return
        }
        
        let parameters = userDefaults.userInfoExists ?
            "etaName=\(userDefaults.userName)&etaPhone=\(userDefaults.userPhone)" :
            "get_next_num=1"
        
        let request = createRequest(with: parameters)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            let appointment = self.processEtaResponse(data: data, error: error)
            userDefaults.addOrUpdateAppointment(newAppointment: appointment)
            completion(appointment)
        }.resume()
    }
    
    func getNumber(_ userDefaults: User, numRes: Int = 1, reservationInd: Bool, inId: Int = 0,
                   completion: @escaping (User) -> Void) {
        var parameters = "user_name=\(userDefaults.userName)&user_phone=\(userDefaults.userPhone)&numRes=\(numRes)"
        
        if reservationInd && inId != 0 {
            parameters += "&get_res=\(inId)"
        }
        
        if !userDefaults.userEmail.isEmpty {
            parameters += "&user_email=\(userDefaults.userEmail)"
        }
        
        let request = createRequest(with: parameters)
        
        session.dataTask(with: request) { data, response, error in
            let processedUser = self.processNumberResponse(data: data, error: error, userDefaults: userDefaults, reservationInd: reservationInd)
            completion(processedUser)
        }.resume()
    }
    
    func cancelAppointment(_ userDefaults: User, completion: @escaping (CONSTS.ErrorNum.RawValue) -> Void) {
        let parameters = "deleteName=\(userDefaults.userName)&deletePhone=\(userDefaults.userPhone)"
        let request = createRequest(with: parameters)
        
        session.dataTask(with: request) { data, response, error in
            let result = self.processCancelResponse(data: data, error: error)
            
            if !CONSTS.isFatal(errorId: result) {
                userDefaults.removeAllAppointments()
            }
            
            completion(result)
        }.resume()
    }
    
    func getOpenings(completion: @escaping ([String: AnyObject]) -> Void) {
        let request = createRequest(with: RequestParameter.openSpots)
        
        session.dataTask(with: request) { data, response, error in
            let result = self.processOpeningsResponse(data: data, error: error)
            completion(result)
        }.resume()
    }
    
    func getClosedMessage(completion: @escaping ((errorNum: CONSTS.ErrorNum, messageText: String)) -> Void) {
        let request = createRequest(with: RequestParameter.closedMessage)
        fetchMessage(with: request, completion: completion)
    }
    
    func getGreetingMessage(completion: @escaping ((errorNum: CONSTS.ErrorNum, messageText: String)) -> Void) {
        let request = createRequest(with: RequestParameter.greeting)
        fetchMessage(with: request, completion: completion)
    }
    
    func getNewHours(completion: @escaping ((errorNum: CONSTS.ErrorNum, messageText: String)) -> Void) {
        let request = createRequest(with: RequestParameter.hours)
        fetchMessage(with: request, completion: completion)
    }
    
    func getNewAddr(completion: @escaping ((errorNum: CONSTS.ErrorNum, messageText: String)) -> Void) {
        let request = createRequest(with: RequestParameter.address)
        fetchMessage(with: request, completion: completion)
    }
    
    // MARK: - Private Response Processing Methods
    private func processEtaResponse(data: Data?, error: Error?) -> Appointment {
        let etaResponse = Appointment()
        
        if error != nil {
            etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            return etaResponse
        }
        
        do {
            guard let data = data,
                  let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject] else {
                etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
                return etaResponse
            }
            
            processEtaJSON(responseJSON, etaResponse: etaResponse)
        } catch {
            etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
        }
        
        return etaResponse
    }
    
    private func processNumberResponse(data: Data?, error: Error?, userDefaults: User, reservationInd: Bool) -> User {
        let appointment = Appointment()
        
        if error != nil {
            appointment.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            userDefaults.removeAllAppointments()
            userDefaults.addOrUpdateAppointment(newAppointment: appointment)
            return userDefaults
        }
        
        do {
            guard let data = data,
                  let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] else {
                appointment.updateError(newError: CONSTS.ErrorNum.EXCEPTION.rawValue)
                userDefaults.addOrUpdateAppointment(newAppointment: appointment)
                return userDefaults
            }
            
            processNumberJSON(responseJSON, appointment: appointment, userDefaults: userDefaults, reservationInd: reservationInd)
        } catch {
            appointment.updateError(newError: CONSTS.ErrorNum.EXCEPTION.rawValue)
            userDefaults.addOrUpdateAppointment(newAppointment: appointment)
        }
        
        return userDefaults
    }
    
    private func processEtaJSON(_ responseJSON: [AnyObject], etaResponse: Appointment) {
        var etaResponseArray: [[String: AnyObject]]?
        
        if responseJSON.count > 1 {
            if let secondError = responseJSON[1] as? [[String: AnyObject]] {
                etaResponse.updateError(newError: getKeyedValueOrDefault(forKey: "error", inDict: secondError[0]))
            } else if let secondElement = responseJSON[1] as? [String: AnyObject] {
                if let etaArray = secondElement["etaArray"] as? [[String: AnyObject]] {
                    etaResponseArray = etaArray
                    if let firstElement = responseJSON[0] as? [String: AnyObject] {
                        etaResponse.updateError(newError: getKeyedValueOrDefault(forKey: "error", inDict: firstElement))
                    }
                } else {
                    etaResponse.updateError(newError: getKeyedValueOrDefault(forKey: "error", inDict: secondElement))
                }
            }
        } else if let checkForNumber = responseJSON[0] as? [String: AnyObject] {
            if let etaArray = checkForNumber["etaArray"] as? [[String: AnyObject]] {
                etaResponseArray = etaArray
            } else {
                etaResponse.updateError(newError: getKeyedValueOrDefault(forKey: "error", inDict: checkForNumber))
            }
        }
        
        if let etaArray = etaResponseArray {
            var closestEta = etaArray[0]
            for response in etaArray.dropFirst() {
                if getKeyedValueOrDefault(forKey: "etaMins", inDict: closestEta) >
                    getKeyedValueOrDefault(forKey: "etaMins", inDict: response) {
                    closestEta = response
                }
            }
            
            etaResponse.updateError(newError: getKeyedValueOrDefault(forKey: "error", inDict: closestEta))
            etaResponse.setIsReservation(isReservation: getKeyedValueOrDefault(forKey: "reservation", inDict: closestEta) == 1)
            etaResponse.setHasNumber(hasNumber: getKeyedValueOrDefault(forKey: "hasNum", inDict: closestEta) == 1)
            etaResponse.setAppointmentStartTime(etaMinVal: Double(getKeyedValueOrDefault(forKey: "etaMins", inDict: closestEta)))
            etaResponse.setNextAvailableId(nextId: getKeyedValueOrDefault(forKey: "id", inDict: closestEta))
            etaResponse.setCurrentId(currentId: getKeyedValueOrDefault(forKey: "curNum", inDict: closestEta))
        } else {
            if etaResponse.getError() == CONSTS.ErrorNum.NO_ERROR.rawValue {
                etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            }
            etaResponse.setHasNumber(hasNumber: false)
        }
    }
    
    private func processNumberJSON(_ responseJSON: [[String: AnyObject]], appointment: Appointment, userDefaults: User, reservationInd: Bool) {
        if let error = responseJSON[0]["error"] as? Int {
            appointment.updateError(newError: error)
            userDefaults.addOrUpdateAppointment(newAppointment: appointment)
            return
        }
        
        var minEtaMins = 60.0 * 24 // Used to find first ETA in response
        
        for response in responseJSON {
            if let etaMins = response["etaMins"] as? Double,
               etaMins < minEtaMins,
               let id = response["id"] as? Int {
                minEtaMins = etaMins
                
                appointment.setNextAvailableId(nextId: id)
                appointment.setAppointmentStartTime(etaMinVal: etaMins)
                appointment.setIsReservation(isReservation: reservationInd)
                appointment.setHasNumber(hasNumber: !reservationInd)
                
                userDefaults.addOrUpdateAppointment(newAppointment: appointment)
            }
        }
    }
    
    private func getKeyedValueOrDefault(forKey: String, inDict: [String: AnyObject]) -> Int {
        return inDict[forKey] as? Int ?? 0
    }
    
    private func processCancelResponse(data: Data?, error: Error?) -> CONSTS.ErrorNum.RawValue {
        if error != nil {
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        }
        
        do {
            guard let data = data,
                  let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] else {
                return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
            }
            
            if responseJSON[0]["delResult"] != nil {
                return CONSTS.ErrorNum.NO_ERROR.rawValue
            } else if let error = responseJSON[0]["error"] as? Int {
                return error
            }
        } catch {
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        }
        
        return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
    }
    
    private func processOpeningsResponse(data: Data?, error: Error?) -> [String: AnyObject] {
        var openingsArray = [String: AnyObject]()
        
        if error != nil {
            openingsArray["error"] = -500 as AnyObject
            return openingsArray
        }
        
        do {
            guard let data = data,
                  let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: AnyObject]] else {
                openingsArray["error"] = -500 as AnyObject
                return openingsArray
            }
            
            if let errorId = responseJSON[0]["error"],
               let errorFatalInd = responseJSON[0]["fatal"] as? Int,
               errorFatalInd == 1 {
                openingsArray["error"] = errorId
                return openingsArray
            }
            
            var availableSpots = [String: Int]()
            var availableSpotsArray = [String]()
            
            for response in responseJSON {
                if let startTime = response["start_time"] as? String,
                   let id = response["id"] as? Int {
                    availableSpots[startTime] = id
                    availableSpotsArray.append(startTime)
                }
            }
            
            openingsArray["availableSpotsArray"] = availableSpotsArray as AnyObject
            openingsArray["availableSpots"] = availableSpots as AnyObject
        } catch {
            openingsArray["error"] = -500 as AnyObject
        }
        
        return openingsArray
    }
    
    private func fetchMessage(with request: URLRequest, completion: @escaping ((errorNum: CONSTS.ErrorNum, messageText: String)) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if error != nil {
                completion((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR,
                          messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
                return
            }
            
            guard let data = data,
                  let message = String(data: data, encoding: .utf8) else {
                completion((errorNum: CONSTS.ErrorNum.NON_SERVER_ERROR,
                          messageText: CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue))
                return
            }
            
            completion((errorNum: CONSTS.ErrorNum.NO_ERROR, messageText: message))
        }.resume()
    }
}

// MARK: - NetworkError
enum NetworkError: Error {
    case noData
    case invalidResponse
}
