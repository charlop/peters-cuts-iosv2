//
//  AppError.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Application error codes and descriptions
//

import Foundation

// MARK: - Error Codes
enum AppErrorCode: Int {
    case unknown = -999
    case exception = -888
    case noInternet = -777
    case nonServerError = -500
    case noNumber = -38
    case active = -37
    case returningMissed = -36
    case deleted = -35
    case returningSuccess = -34
    case cancelFail = -10
    case serverError = -9
    case invalidTime = -8
    case duplicate = -7
    case getNumberFail = -5
    case getReservationFail = -3
    case shopClosed = -2
    case noSpotsAvailable = -1
    case noError = 0

    var isFatal: Bool {
        switch self {
        case .exception, .nonServerError, .cancelFail, .getNumberFail,
             .serverError, .invalidTime, .getReservationFail, .shopClosed,
             .noSpotsAvailable:
            return true
        default:
            return false
        }
    }

    var description: String {
        switch self {
        case .unknown:
            return "Whoa, something is very wrong. Call Peter and let him know. Sorry about that."
        case .noInternet:
            return "Trying to connect..."
        case .exception:
            return "Exception hit. We'd really appreciate if you call Peter and tell him how it happened."
        case .nonServerError:
            return "Can't get any information. Call Peter to see what's up."
        case .noNumber:
            return "Looks like you don't have a number yet."
        case .active:
            return "Your haircut is now"
        case .returningMissed:
            return "Did you miss your appointment?"
        case .deleted:
            return "Are you sure you want a haircut this time?"
        case .returningSuccess:
            return "Welcome back"
        case .cancelFail:
            return "Cancel unsuccessful, call Peter to cancel"
        case .serverError:
            return "Unknown response, restart the app or call Peter"
        case .invalidTime:
            return "Invalid time requested, try again or call Peter"
        case .duplicate:
            return "You already have an appointment"
        case .getNumberFail:
            return "Get Number Failed. Call Peter."
        case .getReservationFail:
            return "Sorry, no longer available. Someone just took that spot"
        case .shopClosed:
            return "Barber shop is closed. General hours: 11AM - 9PM Mon - Sat. You can reserve a spot starting at 9AM."
        case .noSpotsAvailable:
            return "No more spots available"
        case .noError:
            return ""
        }
    }
}

// MARK: - Helper Functions
struct AppErrorHelper {
    static func isFatal(errorId: Int) -> Bool {
        guard let errorCode = AppErrorCode(rawValue: errorId) else {
            return false
        }
        return errorCode.isFatal
    }

    static func getDescription(errorId: Int) -> String {
        guard let errorCode = AppErrorCode(rawValue: errorId) else {
            return AppErrorCode.unknown.description
        }
        return errorCode.description
    }
}

// MARK: - Legacy CONSTS Compatibility
// Keep these for backwards compatibility during migration
class CONSTS {
    enum ErrorNum: Int {
        case UNK = -999
        case EXCEPTION = -888
        case NO_INTERNET = -777
        case NON_SERVER_ERROR = -500
        case NO_NUMBER = -38
        case ACTIVE = -37
        case RETURNING_MISSED = -36
        case DELETED = -35
        case RETURNING_SUCCESS = -34
        case CANCEL_FAIL = -10
        case SERVER_ERROR = -9
        case INVALID_TIME = -8
        case DUPLICATE = -7
        case GET_NUMBER_FAIL = -5
        case GET_RESERVATION_FAIL = -3
        case SHOP_CLOSED = -2
        case NO_SPOTS_AVAILABLE = -1
        case NO_ERROR = 0
    }

    enum ErrorDescription: String {
        case UNK = "Whoa, something is very wrong. Call Peter and let him know. Sorry about that."
        case NO_INTERNET = "Trying to connect..."
        case EXCEPTION = "Exception hit. We'd really appreciate if you call Peter and tell him how it happened."
        case NON_SERVER_ERROR = "Can't get any information. Call Peter to see what's up."
        case NO_NUMBER = "Looks like you don't have a number yet."
        case ACTIVE = "You're haircut is now"
        case RETURNING_MISSED = "Did you miss your appointment?"
        case DELETED = "Are you sure you want a haircut this time?"
        case RETURNING_SUCCESS = "Welcome back"
        case CANCEL_FAIL = "Cancel unsuccessful, call Peter to cancel"
        case SERVER_ERROR = "Unknown response, restart the app or call Peter"
        case INVALID_TIME = "Invalid time requested, try again or call Peter"
        case DUPLICATE = "You already have an appointment"
        case GET_NUMBER_FAIL = "Get Number Failed. Call Peter."
        case GET_RESERVATION_FAIL = "Sorry, no longer available. Someone just took that spot"
        case SHOP_CLOSED = "Barber shop is closed. General hours: 11AM - 9PM Mon - Sat. You can reserve a spot starting at 9AM."
        case NO_SPOTS_AVAILABLE = "No more spots available"
        case NO_ERROR = ""
    }

    class func isFatal(errorId: Int) -> Bool {
        return AppErrorHelper.isFatal(errorId: errorId)
    }

    class func getErrorDescription(errorId: Int) -> ErrorDescription {
        let description = AppErrorHelper.getDescription(errorId: errorId)
        return ErrorDescription(rawValue: description) ?? .UNK
    }
}
