//
//  APIService.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Modern async/await API service replacing PostController_2
//

import Foundation

// MARK: - APIService
actor APIService {
    static let shared = APIService()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Private Helper Methods

    private func createRequest(with parameters: String) -> URLRequest {
        var request = URLRequest(url: APIConfiguration.baseURL)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        guard await Reachability.isConnectedToNetwork() else {
            throw APIError.noInternet
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Public API Methods

    /// Get ETA for user or next available number
    func getEta(for user: User) async throws -> Appointment {
        let parameters: String
        if user.userInfoExists {
            parameters = "etaName=\(user.userName)&etaPhone=\(user.userPhone)"
        } else {
            parameters = "get_next_num=1"
        }

        let request = createRequest(with: parameters)

        do {
            let data = try await performRequest(request)
            return try processEtaResponse(data: data)
        } catch let error as APIError {
            let appointment = Appointment()
            appointment.updateError(newError: convertAPIErrorToLegacyCode(error))
            return appointment
        } catch {
            let appointment = Appointment()
            appointment.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            return appointment
        }
    }

    /// Get a number (walk-in) or make a reservation
    func getNumber(
        for user: User,
        count: Int = 1,
        isReservation: Bool,
        reservationId: Int = 0
    ) async throws -> User {
        var parameters = "user_name=\(user.userName)&user_phone=\(user.userPhone)&numRes=\(count)"

        if isReservation && reservationId != 0 {
            parameters += "&get_res=\(reservationId)"
        }

        if !user.userEmail.isEmpty {
            parameters += "&user_email=\(user.userEmail)"
        }

        let request = createRequest(with: parameters)

        do {
            let data = try await performRequest(request)
            return try processNumberResponse(data: data, user: user, isReservation: isReservation)
        } catch {
            let appointment = Appointment()
            appointment.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            user.addOrUpdateAppointment(newAppointment: appointment)
            return user
        }
    }

    /// Cancel an appointment
    func cancelAppointment(for user: User) async throws -> Int {
        let parameters = "deleteName=\(user.userName)&deletePhone=\(user.userPhone)"
        let request = createRequest(with: parameters)

        do {
            let data = try await performRequest(request)
            return try processCancelResponse(data: data)
        } catch {
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        }
    }

    /// Get available reservation openings
    func getOpenings() async throws -> OpeningsResult {
        let request = createRequest(with: "get_available=1")

        do {
            let data = try await performRequest(request)
            return try processOpeningsResponse(data: data)
        } catch {
            return OpeningsResult(availableSpots: [:], availableSpotsArray: [], error: -500)
        }
    }

    /// Get closed message
    func getClosedMessage() async throws -> (errorNum: CONSTS.ErrorNum, messageText: String) {
        let request = createRequest(with: "getClosedMessage=1")
        return try await fetchMessage(with: request)
    }

    /// Get greeting message
    func getGreetingMessage() async throws -> (errorNum: CONSTS.ErrorNum, messageText: String) {
        let request = createRequest(with: "getGreetingMessage=GREETING")
        return try await fetchMessage(with: request)
    }

    /// Get hours
    func getHours() async throws -> (errorNum: CONSTS.ErrorNum, messageText: String) {
        let request = createRequest(with: "getGreetingMessage=HOURS")
        return try await fetchMessage(with: request)
    }

    /// Get address
    func getAddress() async throws -> (errorNum: CONSTS.ErrorNum, messageText: String) {
        let request = createRequest(with: "getGreetingMessage=ADDR")
        return try await fetchMessage(with: request)
    }

    // MARK: - Private Response Processing

    private func fetchMessage(with request: URLRequest) async throws -> (errorNum: CONSTS.ErrorNum, messageText: String) {
        do {
            let data = try await performRequest(request)
            guard let message = String(data: data, encoding: .utf8) else {
                return (CONSTS.ErrorNum.NON_SERVER_ERROR, CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue)
            }
            return (CONSTS.ErrorNum.NO_ERROR, message)
        } catch {
            return (CONSTS.ErrorNum.NON_SERVER_ERROR, CONSTS.ErrorDescription.NON_SERVER_ERROR.rawValue)
        }
    }

    private func processEtaResponse(data: Data) throws -> Appointment {
        let etaResponse = Appointment()

        guard let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [AnyObject] else {
            etaResponse.updateError(newError: CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue)
            return etaResponse
        }

        // Parse ETA response (keeping original complex logic for now)
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

        return etaResponse
    }

    private func processNumberResponse(data: Data, user: User, isReservation: Bool) throws -> User {
        let appointment = Appointment()

        guard let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [[String: AnyObject]] else {
            appointment.updateError(newError: CONSTS.ErrorNum.EXCEPTION.rawValue)
            user.addOrUpdateAppointment(newAppointment: appointment)
            return user
        }

        if let error = responseJSON[0]["error"] as? Int {
            appointment.updateError(newError: error)
            user.addOrUpdateAppointment(newAppointment: appointment)
            return user
        }

        var minEtaMins = 60.0 * 24

        for response in responseJSON {
            if let etaMins = response["etaMins"] as? Double,
               etaMins < minEtaMins,
               let id = response["id"] as? Int {
                minEtaMins = etaMins

                appointment.setNextAvailableId(nextId: id)
                appointment.setAppointmentStartTime(etaMinVal: etaMins)
                appointment.setIsReservation(isReservation: isReservation)
                appointment.setHasNumber(hasNumber: !isReservation)

                user.addOrUpdateAppointment(newAppointment: appointment)
            }
        }

        return user
    }

    private func processCancelResponse(data: Data) throws -> CONSTS.ErrorNum.RawValue {
        guard let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [[String: AnyObject]] else {
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        }

        if responseJSON[0]["delResult"] != nil {
            return CONSTS.ErrorNum.NO_ERROR.rawValue
        } else if let error = responseJSON[0]["error"] as? Int {
            return error
        }

        return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
    }

    private func processOpeningsResponse(data: Data) throws -> OpeningsResult {
        guard let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [[String: AnyObject]] else {
            return OpeningsResult(availableSpots: [:], availableSpotsArray: [], error: -500)
        }

        if let errorId = responseJSON[0]["error"] as? Int,
           let errorFatalInd = responseJSON[0]["fatal"] as? Int,
           errorFatalInd == 1 {
            return OpeningsResult(availableSpots: [:], availableSpotsArray: [], error: errorId)
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

        return OpeningsResult(
            availableSpots: availableSpots,
            availableSpotsArray: availableSpotsArray,
            error: nil
        )
    }

    private func getKeyedValueOrDefault(forKey: String, inDict: [String: AnyObject]) -> Int {
        return inDict[forKey] as? Int ?? 0
    }

    private func convertAPIErrorToLegacyCode(_ error: APIError) -> Int {
        switch error {
        case .noInternet:
            return CONSTS.ErrorNum.NO_INTERNET.rawValue
        case .invalidResponse, .noData, .decodingError, .unknown:
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        case .serverError:
            return CONSTS.ErrorNum.NON_SERVER_ERROR.rawValue
        }
    }
}
