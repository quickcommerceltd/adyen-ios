//
// Copyright (c) 2020 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// Contains the styling customization options for an item in a list.
public struct ListItemStyle: ViewStyle {
    
    /// The title style.
    public var title = TextStyle(font: .preferredFont(forTextStyle: .body),
                                 color: UIColor.AdyenCore.componentLabel,
                                 textAlignment: .natural)
    
    /// The subtitle style.
    public var subtitle = TextStyle(font: .preferredFont(forTextStyle: .footnote),
                                    color: UIColor.AdyenCore.componentSecondaryLabel,
                                    textAlignment: .natural)
    
    /// The image style.
    public var image = ImageStyle(borderColor: UIColor.AdyenCore.componentSeparator,
                                  borderWidth: 1.0 / UIScreen.main.nativeScale,
                                  cornerRadius: 4.0,
                                  clipsToBounds: true,
                                  contentMode: .scaleAspectFit)
    
    /// :nodoc:
    public var backgroundColor = UIColor.AdyenCore.componentBackground
    
    /// Initializes the list item style.
    ///
    /// - Parameter title: The title style.
    /// - Parameter subtitle: The subtitle style.
    /// - Parameter image: The image style.
    public init(title: TextStyle, subtitle: TextStyle, image: ImageStyle) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
    
    /// Initializes the list item style with the default style.
    public init() {}
    
}

extension ListItemStyle: Equatable {
    
    public static func == (lhs: ListItemStyle, rhs: ListItemStyle) -> Bool {
        lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle &&
            lhs.image == rhs.image &&
            lhs.backgroundColor.cgColor == rhs.backgroundColor.cgColor
    }
    
}
