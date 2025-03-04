import Foundation
import Photos

enum PhotoReviewMode: String {
    case fromToday
    case pastWeek
    case pastMonth
    case allTime
    
    var fetchPredicate: NSPredicate {
        let calendar = Calendar.current
        
        switch self {
        case .fromToday:
            let startOfDay = calendar.startOfDay(for: Date())
            return NSPredicate(format: "creationDate >= %@ AND (mediaType = %d OR mediaType = %d)",
                             startOfDay as NSDate,
                             PHAssetMediaType.image.rawValue,
                             PHAssetMediaType.video.rawValue)
            
        case .pastWeek:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
            return NSPredicate(format: "creationDate >= %@ AND (mediaType = %d OR mediaType = %d)",
                             sevenDaysAgo as NSDate,
                             PHAssetMediaType.image.rawValue,
                             PHAssetMediaType.video.rawValue)
            
        case .pastMonth:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
            return NSPredicate(format: "creationDate >= %@ AND (mediaType = %d OR mediaType = %d)",
                             thirtyDaysAgo as NSDate,
                             PHAssetMediaType.image.rawValue,
                             PHAssetMediaType.video.rawValue)
            
        case .allTime:
            return NSPredicate(format: "mediaType = %d OR mediaType = %d",
                             PHAssetMediaType.image.rawValue,
                             PHAssetMediaType.video.rawValue)
        }
    }
    
    var title: String {
        switch self {
        case .fromToday:
            return "From Today"
        case .pastWeek:
            return "Past 7 Days"
        case .pastMonth:
            return "Past 30 Days"
        case .allTime:
            return "All Time"
        }
    }
    
    var description: String {
        switch self {
        case .fromToday:
            return "From today onward"
        case .pastWeek:
            return "From the last week onward"
        case .pastMonth:
            return "From the last month onward"
        case .allTime:
            return "Your entire photo library"
        }
    }
    
    var icon: String {
        switch self {
        case .fromToday:
            return "clock.arrow.circlepath"
        case .pastWeek:
            return "calendar.badge.clock"
        case .pastMonth:
            return "calendar"
        case .allTime:
            return "photo.stack"
        }
    }
} 